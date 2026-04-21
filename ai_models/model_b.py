import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# Load data
train_df = pd.read_csv("adult_train.csv")
test_df = pd.read_csv("adult_test.csv")

df = pd.concat([train_df, test_df], ignore_index=True)
df.columns = df.columns.str.strip()

# Remove missing
df = df.replace("?", pd.NA)
df = df.dropna()

# Target columns
decision_col = "Target"   # Model A output
protected_col = "Sex"     # What we try to predict (bias target)

# Encode decision (Model A output simulation)
df["decision"] = df[decision_col].apply(lambda x: 1 if ">50K" in str(x) else 0)

# Features for Model B = ONLY Model A decision
X = df[["decision"]]

# What we try to predict → protected attribute
y = df[protected_col]

# Encode gender
y = y.apply(lambda x: 1 if "Male" in str(x) else 0)

# Split
train_size = int(0.8 * len(df))
X_train, X_test = X[:train_size], X[train_size:]
y_train, y_test = y[:train_size], y[train_size:]

# Train Model B
model_b = RandomForestClassifier()
model_b.fit(X_train, y_train)

# Predict
y_pred = model_b.predict(X_test)

print("Bias Detection Accuracy:", accuracy_score(y_test, y_pred))