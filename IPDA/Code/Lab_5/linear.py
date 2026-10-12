import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from packaging.version import Version
from sklearn import __version__
from sklearn.base import clone
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    precision_score,
    recall_score,
    roc_auc_score,
    roc_curve,
)
from sklearn.model_selection import (
    GridSearchCV,
    StratifiedKFold,
    cross_val_score,
    train_test_split,
)
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier


def preprocess(df, test_size=0.2, random_state=42):
    df = df.copy()
    df.columns = df.columns.str.strip()
    df = df.drop(columns=["id", "Unnamed: 32"], errors="ignore")
    df = df.drop_duplicates()

    y = df["diagnosis"].map({"B": 0, "M": 1})

    if y.isna().any():
        raise ValueError("diagnosis must contain only B or M without missing values.")

    y = y.astype("int64")
    X = df.drop(columns="diagnosis").apply(pd.to_numeric, errors="raise")
    X = X.replace([np.inf, -np.inf], np.nan)

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=test_size,
        random_state=random_state,
        stratify=y,
    )

    if X_train.isna().all().any():
        raise ValueError("A training feature contains only missing values.")

    preprocessor = Pipeline(
        [
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ]
    )

    print(f"Training set shape: {X_train.shape}")
    print(f"Test set shape: {X_test.shape}")
    print("Class encoding: B = 0, M = 1")

    return X_train, X_test, y_train, y_test, preprocessor


def make_model(classifier, preprocessor):
    return Pipeline(
        [
            ("preprocessor", clone(preprocessor)),
            ("classifier", classifier),
        ]
    )


def evaluate_model(model, X, y):
    predictions = model.predict(X)

    return {
        "accuracy": accuracy_score(y, predictions),
        "precision": precision_score(y, predictions, pos_label=1, zero_division=0),
        "recall": recall_score(y, predictions, pos_label=1, zero_division=0),
    }


def make_confusion_matrix(model, X, y):
    return pd.DataFrame(
        confusion_matrix(y, model.predict(X), labels=[0, 1]),
        index=["Actual B", "Actual M"],
        columns=["Predicted B", "Predicted M"],
    )


def print_table(title, table):
    print(f"\n{title}")
    print(table.to_string(float_format=lambda value: f"{value:.4f}"))


def train_logistic_regression(
    X_train,
    X_test,
    y_train,
    y_test,
    preprocessor,
    random_state=42,
):
    cv = StratifiedKFold(
        n_splits=5,
        shuffle=True,
        random_state=random_state,
    )

    models = {}
    coefficients = {}
    rows = []

    for penalty in ("l1", "l2"):
        for C in (1, 100, 0.01):
            if Version(__version__) >= Version("1.8"):
                regularization = {"l1_ratio": 1 if penalty == "l1" else 0}
            else:
                regularization = {"penalty": penalty}

            model = make_model(
                LogisticRegression(
                    C=C,
                    solver="liblinear",
                    max_iter=10000,
                    random_state=random_state,
                    **regularization,
                ),
                preprocessor,
            )

            cv_scores = cross_val_score(
                model,
                X_train,
                y_train,
                cv=cv,
                scoring="accuracy",
            )

            model.fit(X_train, y_train)

            name = f"{penalty.upper()}, C={C:g}"
            classifier = model.named_steps["classifier"]
            models[name] = model

            coefficients[name] = pd.Series(
                np.r_[classifier.coef_[0], classifier.intercept_[0]],
                index=[*X_train.columns, "intercept"],
            )

            rows.append(
                {
                    "model": name,
                    "C": C,
                    "train_accuracy": model.score(X_train, y_train),
                    "test_accuracy": model.score(X_test, y_test),
                    "cv_accuracy": cv_scores.mean(),
                    "cv_std": cv_scores.std(),
                    "zero_coefficients": int(
                        np.count_nonzero(classifier.coef_[0] == 0)
                    ),
                }
            )

    comparison = pd.DataFrame(rows).set_index("model")
    coefficients = pd.DataFrame(coefficients)

    best_name = comparison.sort_values(
        ["cv_accuracy", "C", "zero_coefficients"],
        ascending=[False, True, False],
    ).index[0]

    best_model = models[best_name]

    metrics = pd.DataFrame.from_dict(
        {
            "train": evaluate_model(best_model, X_train, y_train),
            "test": evaluate_model(best_model, X_test, y_test),
        },
        orient="index",
    )
    metrics.index.name = "dataset"

    matrix = make_confusion_matrix(best_model, X_test, y_test)

    print_table("Logistic regression comparison:", comparison)

    print("\nCoefficients for standardized features:")
    print(coefficients.to_string(float_format=lambda value: f"{value:.6f}"))

    print(f"\nBest logistic regression by CV accuracy: {best_name}")

    print_table("Best logistic regression metrics:", metrics)
    print_table("Best logistic regression test confusion matrix:", matrix)

    print("\nSmaller C means stronger regularization.")
    print("L1 regularization can set feature coefficients to zero.")
    print("L2 regularization shrinks coefficients and usually keeps them nonzero.")

    return {
        "models": models,
        "comparison": comparison,
        "coefficients": coefficients,
        "best_name": best_name,
        "best_model": best_model,
        "metrics": metrics,
        "confusion_matrix": matrix,
    }


def train_svc_tree_knn(
    X_train,
    X_test,
    y_train,
    y_test,
    preprocessor,
    random_state=42,
):
    cv = StratifiedKFold(
        n_splits=5,
        shuffle=True,
        random_state=random_state,
    )

    model_svc = make_model(SVC(), preprocessor)

    baseline_cv = cross_val_score(
        model_svc,
        X_train,
        y_train,
        cv=cv,
        scoring="accuracy",
    ).mean()

    model_svc.fit(X_train, y_train)

    svc_params = {
        "classifier__C": [0.1, 1, 10],
        "classifier__gamma": [0.2, 0.6, 1],
    }

    svc_grid = GridSearchCV(
        clone(model_svc),
        svc_params,
        scoring="accuracy",
        cv=cv,
        n_jobs=-1,
        refit=True,
    )

    svc_grid.fit(X_train, y_train)

    svc_candidates = {
        "SVC default": model_svc,
        "SVC GridSearch": svc_grid.best_estimator_,
    }

    cv_scores = {
        "SVC default": baseline_cv,
        "SVC GridSearch": svc_grid.best_score_,
    }

    svc_rows = []

    for name, model in svc_candidates.items():
        test_metrics = evaluate_model(model, X_test, y_test)

        svc_rows.append(
            {
                "model": name,
                "train_accuracy": model.score(X_train, y_train),
                "test_accuracy": test_metrics["accuracy"],
                "cv_accuracy": cv_scores[name],
                "precision": test_metrics["precision"],
                "recall": test_metrics["recall"],
            }
        )

    svc_comparison = pd.DataFrame(svc_rows).set_index("model")
    best_svc_name = max(cv_scores, key=cv_scores.get)
    best_svc = svc_candidates[best_svc_name]
    svc_matrix = make_confusion_matrix(best_svc, X_test, y_test)

    models = {"SVC": best_svc}

    classifiers = {
        "Decision tree": DecisionTreeClassifier(random_state=random_state),
        "KNN": KNeighborsClassifier(n_neighbors=5),
    }

    for name, classifier in classifiers.items():
        model = make_model(classifier, preprocessor)
        model.fit(X_train, y_train)
        models[name] = model

    accuracy = pd.DataFrame(
        [
            {
                "model": name,
                "train_accuracy": model.score(X_train, y_train),
                "test_accuracy": model.score(X_test, y_test),
            }
            for name, model in models.items()
        ]
    ).set_index("model")

    best_params = {
        name.replace("classifier__", ""): value
        for name, value in svc_grid.best_params_.items()
    }

    print(f"\nBest SVC parameters in the specified grid: {best_params}")
    print(f"Best SVC grid CV accuracy: {svc_grid.best_score_:.4f}")

    print_table("SVC comparison:", svc_comparison)
    print(f"\nSelected SVC by CV accuracy: {best_svc_name}")
    print_table("Selected SVC test confusion matrix:", svc_matrix)
    print_table("SVC, decision tree, and KNN accuracy:", accuracy)

    if svc_grid.best_score_ > baseline_cv:
        print("\nGrid search improved SVC cross-validation accuracy.")
    elif svc_grid.best_score_ < baseline_cv:
        print("\nDefault SVC achieved higher CV accuracy than the grid winner.")
    else:
        print("\nDefault SVC and the grid winner achieved equal CV accuracy.")

    print("Grid search finds the best parameters only within the specified grid.")

    return {
        "models": models,
        "svc_grid": svc_grid,
        "svc_comparison": svc_comparison,
        "best_svc_name": best_svc_name,
        "svc_confusion_matrix": svc_matrix,
        "accuracy": accuracy,
    }


def compare_models_roc(models, X_train, X_test, y_train, y_test):
    figure, axes = plt.subplots(figsize=(8, 6))
    rows = []

    for name, model in models.items():
        test_metrics = evaluate_model(model, X_test, y_test)

        if hasattr(model, "decision_function"):
            scores = model.decision_function(X_test)
        else:
            positive_index = list(model.classes_).index(1)
            scores = model.predict_proba(X_test)[:, positive_index]

        fpr, tpr, _ = roc_curve(y_test, scores, pos_label=1)
        auc = roc_auc_score(y_test, scores)

        axes.plot(
            fpr,
            tpr,
            linewidth=2,
            label=f"{name}: AUC = {auc:.4f}",
        )

        rows.append(
            {
                "model": name,
                "train_accuracy": model.score(X_train, y_train),
                "test_accuracy": test_metrics["accuracy"],
                "precision": test_metrics["precision"],
                "recall": test_metrics["recall"],
                "roc_auc": auc,
            }
        )

    axes.plot([0, 1], [0, 1], "k--", label="Random classifier")
    axes.set(
        xlabel="False positive rate",
        ylabel="True positive rate",
        title="ROC curves on the test set",
        xlim=(0, 1),
        ylim=(0, 1.02),
    )
    axes.legend(loc="lower right")
    axes.grid(alpha=0.3)
    figure.tight_layout()

    comparison = (
        pd.DataFrame(rows).set_index("model").sort_values("roc_auc", ascending=False)
    )

    print_table("Comparison of all four models:", comparison)

    best_auc = comparison["roc_auc"].max()
    best_names = comparison.index[comparison["roc_auc"] == best_auc].tolist()

    print(f"\nHighest test ROC AUC: {', '.join(best_names)} ({best_auc:.4f})")
    print("This ranking describes the current test split.")
    print("Recall measures the fraction of malignant cases detected.")
    print("Higher training accuracy with lower test accuracy can indicate overfitting.")

    plt.show()

    return {
        "comparison": comparison,
        "figure": figure,
    }


def main(data_path="data.csv", random_state=42):
    df = pd.read_csv(data_path)

    X_train, X_test, y_train, y_test, preprocessor = preprocess(
        df,
        random_state=random_state,
    )

    logistic_results = train_logistic_regression(
        X_train,
        X_test,
        y_train,
        y_test,
        preprocessor,
        random_state=random_state,
    )

    additional_results = train_svc_tree_knn(
        X_train,
        X_test,
        y_train,
        y_test,
        preprocessor,
        random_state=random_state,
    )

    all_models = {
        "Logistic regression": logistic_results["best_model"],
        **additional_results["models"],
    }

    roc_results = compare_models_roc(
        all_models,
        X_train,
        X_test,
        y_train,
        y_test,
    )

    return {
        "logistic_regression": logistic_results,
        "additional_models": additional_results,
        "roc": roc_results,
    }


if __name__ == "__main__":
    results = main("data.csv")
