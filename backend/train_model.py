# This reads training.csv / testing.csv, trains a
# model to predict whether at least one spot is empty, and saves
# the model as parking_forecast_model.joblib

from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report


def main():
    base_dir = Path(__file__).resolve().parent
    train_path = base_dir / "training.csv"
    test_path = base_dir / "testing.csv"

    print(f"Loading training data from: {train_path}")
    df_train = pd.read_csv(train_path)

    print(f"Loading test data from: {test_path}")
    df_test = pd.read_csv(test_path)

    # Features: time-of-week only
    feature_cols = ["day_of_week", "minute_of_day"]

    X_train = df_train[feature_cols].values
    y_train = df_train["label_any_empty"].values

    X_test = df_test[feature_cols].values
    y_test = df_test["label_any_empty"].values

    print("Training RandomForestClassifier...")
    clf = RandomForestClassifier(
        n_estimators=200,
        max_depth=10,
        min_samples_leaf=5,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1,
    )
    clf.fit(X_train, y_train)

    print("Evaluating on test set...")
    y_pred = clf.predict(X_test)
    print(classification_report(y_test, y_pred))

    model_path = base_dir / "parking_forecast_model.joblib"
    joblib.dump(clf, model_path)
    print(f"Saved model to: {model_path}")


if __name__ == "__main__":
    main()

