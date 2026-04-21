import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# Load datasets
train_df = pd.read_csv("adult_train.csv")
test_df = pd.read_csv("adult_test.csv")

# Combine
df = pd.concat([train_df, test_df], ignore_index=True)

# Clean column names
df.columns = df.columns.str.strip()

# Remove missing values
df = df.replace("?", pd.NA)
df = df.dropna()

# Target column
target_col = "Target"

# Separate features & target
X = df.drop(target_col, axis=1)
y = df[target_col]

# 🔥 ONE-HOT ENCODING (THIS FIXES EVERYTHING)
X = pd.get_dummies(X)

# Convert target to numeric
y = y.apply(lambda x: 1 if ">50K" in str(x) else 0)

# Split back
train_size = len(train_df)
X_train = X[:train_size]
X_test = X[train_size:]
y_train = y[:train_size]
y_test = y[train_size:]

# Train model
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Predict
y_pred = model.predict(X_test)

print("Model A Accuracy:", accuracy_score(y_test, y_pred))