import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# Load data
train_df = pd.read_csv("adult_train.csv")
test_df = pd.read_csv("adult_test.csv")

df = pd.concat([train_df, test_df], ignore_index=True)
df.columns = df.columns.str.strip()

# Remove missing values
df = df.replace("?", pd.NA)
df = df.dropna()

# Target
target_col = "Target"

# 🔥 REMOVE BIAS FEATURES
df = df.drop(["Sex", "Race"], axis=1)

# Split features & target
X = df.drop(target_col, axis=1)
y = df[target_col]

# Encode features
X = pd.get_dummies(X)

# Encode target
y = y.apply(lambda x: 1 if ">50K" in str(x) else 0)

# Split
train_size = len(train_df)
X_train = X[:train_size]
X_test = X[train_size:]
y_train = y[:train_size]
y_test = y[train_size:]

# Train fair model
model_c = RandomForestClassifier()
model_c.fit(X_train, y_train)

# Predict
y_pred = model_c.predict(X_test)

print("Model C (Fair) Accuracy:", accuracy_score(y_test, y_pred))