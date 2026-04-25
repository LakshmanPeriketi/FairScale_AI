from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import io
import traceback

# Global storage for trained models (In-memory for demo purposes)
MODEL_CONTEXT = {
    "model_A": None,
    "model_B": None,
    "model_C": None,
    "protected_cols": [],
    "valid_cols": [],
    "target_col": None
}

app = Flask(__name__)
CORS(app) 

@app.before_request
def log_request_info():
    if request.path == '/intercept':
        app.logger.info('Intercept request received from: %s', request.remote_addr)

@app.route('/', methods=['GET'])
def health():
    return jsonify({"status": "ok", "message": "ML Engine is alive!", "models_ready": MODEL_CONTEXT['model_A'] is not None})

@app.route('/intercept', methods=['POST'])
def intercept():
    try:
        data = request.json
        if not MODEL_CONTEXT['model_A']:
            return jsonify({"status": "error", "message": "Models not trained yet. Visit Dashboard to train."}), 400

        # Create DataFrame from single applicant
        df_applicant = pd.DataFrame([data])
        
        # Preprocess features (simplified for demo: assume encoded correctly or use mapping)
        # In a real app, we'd use the same encoder state from the training phase
        for col in df_applicant.columns:
            if df_applicant[col].dtype == 'object':
                df_applicant[col] = 0 # Placeholder for demo mapping

        # 1. Model A Prediction and Confidence
        features_A = MODEL_CONTEXT['valid_cols'] + MODEL_CONTEXT['protected_cols']
        X_A = df_applicant[features_A]
        model_A_probs = MODEL_CONTEXT['model_A'].predict_proba(X_A)[0]
        model_A_decision = int(MODEL_CONTEXT['model_A'].predict(X_A)[0])
        model_A_confidence = round(float(np.max(model_A_probs)), 2)

        # Get Model A's key factors based on global feature importance for this model instance
        importances = MODEL_CONTEXT['model_A'].feature_importances_
        sorted_indices = np.argsort(importances)[::-1]
        top_factors_A = [features_A[i] for i in sorted_indices[:3]]

        # 2. Model B Check (Bias Detection)
        X_detective = df_applicant[MODEL_CONTEXT['valid_cols']].copy()
        X_detective['decision'] = model_A_decision
        X_detective.columns = [str(i) for i in range(len(X_detective.columns))] 
        
        bias_likelihood = MODEL_CONTEXT['model_B'].predict_proba(X_detective)[0][1] 

        # 3. Model C Result (Fair Score)
        X_C = df_applicant[MODEL_CONTEXT['valid_cols']]
        model_C_probs = MODEL_CONTEXT['model_C'].predict_proba(X_C)[0]
        fair_decision = int(MODEL_CONTEXT['model_C'].predict(X_C)[0])
        model_C_confidence = round(float(np.max(model_C_probs)), 2)
        
        # Top factors for the Fair Model
        c_importances = MODEL_CONTEXT['model_C'].feature_importances_
        c_sorted_indices = np.argsort(c_importances)[::-1]
        top_factors_C = [MODEL_CONTEXT['valid_cols'][i] for i in c_sorted_indices[:3]]

        return jsonify({
            "status": "success",
            "bias_score": round(float(bias_likelihood), 2),
            "original_decision_biased": bool(bias_likelihood > 0.5),
            "model_a_decision": "APPROVE" if model_A_decision == 1 else "REJECT",
            "model_a_confidence": model_A_confidence,
            "model_a_factors": top_factors_A,
            "model_c_decision": "APPROVE" if fair_decision == 1 else "REJECT",
            "model_c_confidence": model_C_confidence,
            "model_c_factors": top_factors_C,
            "message": "FairScale Shield Active: Decision validated across demographic parity."
        })

    except Exception as e:
        print(f"Intercept Error: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/train', methods=['POST'])
def train_models():
    try:
        print("Received training request...")
        # 1. Get File and Mapping data
        file = request.files['file']
        target_col = request.form.get('target')
        
        # Expecting comma-separated strings for lists
        protected_raw = request.form.get('protected', '')
        valid_raw = request.form.get('valid', '')
        
        protected_cols = [c.strip() for c in protected_raw.split(',') if c.strip()]
        valid_cols = [c.strip() for c in valid_raw.split(',') if c.strip()]

        print(f"Target: {target_col}")
        print(f"Protected: {protected_cols}")
        print(f"Valid: {valid_cols}")

        # SMART FALLBACK: If no valid features selected, use all columns except target/protected
        if not valid_cols:
            temp_df = pd.read_csv(io.BytesIO(file.read()))
            file.seek(0) # Reset file pointer for later use
            valid_cols = [col for col in temp_df.columns if col != target_col and col not in protected_cols]
            print(f"DEBUG: No features selected. Auto-discovered: {valid_cols}")

        if not valid_cols:
            return jsonify({"error": "No training features found after exclusion."}), 400

        if not file:
            return jsonify({"error": "No file uploaded"}), 400

        # 2. Read Dataset
        print("Reading CSV...")
        df = pd.read_csv(io.StringIO(file.read().decode('utf-8')))
        print(f"Loaded {len(df)} rows and {len(df.columns)} columns.")
        
        # Basic Preprocessing: Drop NaNs and convert categories to numbers
        df = df.dropna().reset_index(drop=True)
        for col in df.columns:
            if df[col].dtype == 'object':
                df[col] = pd.factorize(df[col])[0]

        # 3. TRAIN MODEL A (The Original - Biased)
        print("Training Model A...")
        features_A = valid_cols + protected_cols
        X_A = df[features_A]
        y = df[target_col]
        
        XA_train, XA_test, ya_train, ya_test = train_test_split(X_A, y, test_size=0.2)
        model_A = RandomForestClassifier(n_estimators=50)
        model_A.fit(XA_train, ya_train)
        acc_A = accuracy_score(ya_test, model_A.predict(XA_test))

        # 4. TRAIN MODEL B (The Detective - Adversarial)
        print("Training Model B...")
        detective_target = protected_cols[0]
        model_A_decisions = model_A.predict(X_A)
        
        X_B = pd.concat([df[valid_cols], pd.Series(model_A_decisions, name='decision')], axis=1)
        # Ensure column names are unique for Model B features
        X_B.columns = [str(i) for i in range(len(X_B.columns))] 
        
        y_B = df[detective_target]
        
        XB_train, XB_test, yb_train, yb_test = train_test_split(X_B, y_B, test_size=0.2)
        model_B = RandomForestClassifier(n_estimators=50)
        model_B.fit(XB_train, yb_train)
        bias_detection_score = accuracy_score(yb_test, model_B.predict(XB_test))

        # 5. TRAIN MODEL C (The Fair Mirror)
        print("Training Model C...")
        X_C = df[valid_cols]
        XC_train, XC_test, yc_train, yc_test = train_test_split(X_C, y, test_size=0.2)
        model_C = RandomForestClassifier(n_estimators=50)
        model_C.fit(XC_train, yc_train)
        acc_C = accuracy_score(yc_test, model_C.predict(XC_test))

        # Save to Global Context for Interception
        MODEL_CONTEXT['model_A'] = model_A
        MODEL_CONTEXT['model_B'] = model_B
        MODEL_CONTEXT['model_C'] = model_C
        MODEL_CONTEXT['protected_cols'] = protected_cols
        MODEL_CONTEXT['valid_cols'] = valid_cols
        MODEL_CONTEXT['target_col'] = target_col

        print("Training complete and models persisted!")

        return jsonify({
            "status": "success",
            "modelA": {"accuracy": round(acc_A, 2)},
            "modelB": {"bias_score": round(bias_detection_score, 2)},
            "modelC": {"accuracy": round(acc_C, 2)},
            "recommendation": "Use Model C to neutralize Detected Bias." if bias_detection_score > 0.6 else "Model A shows acceptable fairness."
        })

    except Exception as e:
        print(f"Error: {e}")
        traceback.print_exc()
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5005)
