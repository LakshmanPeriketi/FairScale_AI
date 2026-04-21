import pandas as pd
from sklearn.ensemble import RandomForestClassifier

# Load data
df = pd.read_csv("adult_train.csv")
df.columns = df.columns.str.strip()
df = df.replace("?", pd.NA).dropna()

# ---------- MODEL A ----------
X_a = pd.get_dummies(df.drop("Target", axis=1))
y = df["Target"].apply(lambda x: 1 if ">50K" in str(x) else 0)

model_a = RandomForestClassifier()
model_a.fit(X_a, y)

# ---------- MODEL C (FAIR) ----------
df_fair = df.drop(["Sex", "Race"], axis=1)
X_c = pd.get_dummies(df_fair.drop("Target", axis=1))

model_c = RandomForestClassifier()
model_c.fit(X_c, y)

# ---------- PREDICTION FUNCTION ----------
def predict(input_dict):
    input_df = pd.DataFrame([input_dict])

    # Model A
    input_a = pd.get_dummies(input_df)
    input_a = input_a.reindex(columns=X_a.columns, fill_value=0)
    pred_a = model_a.predict(input_a)[0]

    # Model C
    input_c = input_df.drop(["Sex", "Race"], axis=1)
    input_c = pd.get_dummies(input_c)
    input_c = input_c.reindex(columns=X_c.columns, fill_value=0)
    pred_c = model_c.predict(input_c)[0]

    # Bias Score (simple version)
    bias_score = abs(pred_a - pred_c)

    return {
        "Model_A_Decision": int(pred_a),
        "Model_C_Fair_Decision": int(pred_c),
        "Bias_Score": float(bias_score)
    }


# ---------- TEST ----------
sample = {
    "Age": 35,
    "Workclass": "Private",
    "fnlwgt": 200000,
    "Education": "Bachelors",
    "Education_num": 13,
    "Marital_Status": "Never-married",
    "Occupation": "Tech-support",
    "Relationship": "Not-in-family",
    "Race": "White",
    "Sex": "Male",
    "Capital_gain": 0,
    "Capital_loss": 0,
    "Hours_per_week": 40,
    "Country": "United-States"
}

print(predict(sample))