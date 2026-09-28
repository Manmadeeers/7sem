import hashlib
from pathlib import Path
import joblib
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.tree import DecisionTreeClassifier, plot_tree
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay
)
from sklearn.decomposition import PCA


DATA_PATH = "./data.csv"
CACHE_PATH = "./best_models.joblib"

CACHE_VERSION = 1

NUM_FEATURES = [
    "person_age",
    "person_income",
    "person_emp_exp",
    "loan_amnt",
    "loan_int_rate",
    "loan_percent_income",
    "cb_person_cred_hist_length",
    "credit_score"
]


def get_file_hash(path):
    sha256 = hashlib.sha256()

    with open(path, "rb") as f:
        while True:
            chunk = f.read(8192)

            if not chunk:
                break

            sha256.update(chunk)

    return sha256.hexdigest()


def loadData(path):
    data = pd.read_csv(path)

    print("Data loaded")
    print(f"Shape: {data.shape}")

    return data


def preProcess(data):
    print("\nInitial information:")
    data.info()

    print("\nMissing values:")
    print(data.isnull().sum())

    print("\nDeleting anomalies...")

    data = data[
        (data["person_age"] <= 100) &
        (data["person_emp_exp"] <= 60)
    ].copy()

    print(f"Shape after anomaly removal: {data.shape}")

    print("\nConverting categorical features to numeric...")

    data["person_gender"] = data["person_gender"].map({
        "male": 0,
        "female": 1
    })

    data["previous_loan_defaults_on_file"] = (
        data["previous_loan_defaults_on_file"].map({
            "No": 0,
            "Yes": 1
        })
    )
    
    data = pd.get_dummies(
        data,
        columns=[
            "person_education",
            "person_home_ownership",
            "loan_intent"
        ],
        drop_first=True,
        dtype=int
    )


    print("\nMissing values after conversion:")
    print(data.isnull().sum())

    if data.isnull().sum().sum() > 0:
        print("\nDropping rows containing missing values...")
        data = data.dropna()

    dups = data.duplicated().sum()

    print(f"\nDuplicates: {dups}")

    if dups > 0:
        print("Dropping duplicates...")
        data = data.drop_duplicates()

    print("\nFinal information:")
    data.info()

    return data


def makeMatrix(data):
    y = data["loan_status"]
    X = data.drop(columns=["loan_status"])

    print(f"\nX shape: {X.shape}")
    print(f"Y shape: {y.shape}")

    return X, y


def splittingData(X, y):
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y
    )

    print(f"\nTrain: {X_train.shape}")
    print(f"Test:  {X_test.shape}")

    return X_train, X_test, y_train, y_test



def make_knn_pipeline():

    preprocessing = ColumnTransformer(
        transformers=[
            (
                "scale",
                StandardScaler(),
                NUM_FEATURES
            )
        ],
        remainder="passthrough"
    )

    pipeline = Pipeline([
        ("preprocessing", preprocessing),
        ("knn", KNeighborsClassifier())
    ])

    return pipeline



def train_base_models(X_train, y_train):
    print("\n=== Building base Decision Tree ===")

    dt = DecisionTreeClassifier(
        criterion="gini",
        max_depth=5,
        min_samples_leaf=5,
        random_state=42
    )

    dt.fit(X_train, y_train)

    print("\n=== Building base KNN ===")

    knn = make_knn_pipeline()

    knn.set_params(
        knn__n_neighbors=5,
        knn__weights="uniform",
        knn__p=2
    )

    knn.fit(X_train, y_train)

    return dt, knn



def grid_search_models(X_train, y_train, cv=5, scoring="accuracy"):


    dt_param_grid = {
        "max_depth": [3, 5, 7, 10, 15, 20, None],
        "min_samples_leaf": [1, 3, 5, 10, 20],
        "min_samples_split": [2, 5, 10],
        "criterion": ["gini", "entropy"]
    }

    dt_gs = GridSearchCV(
        estimator=DecisionTreeClassifier(random_state=42),
        param_grid=dt_param_grid,
        cv=cv,
        scoring=scoring,
        n_jobs=-1
    )

    print("\nSearching best Decision Tree parameters...")

    dt_gs.fit(X_train, y_train)

    print("\n=== Decision Tree ===")
    print(f"Best parameters: {dt_gs.best_params_}")
    print(f"Best CV score:   {dt_gs.best_score_:.4f}")


    knn_pipeline = make_knn_pipeline()

    knn_param_grid = {
        "knn__n_neighbors": list(range(3, 32, 2)),
        "knn__weights": ["uniform", "distance"],
        "knn__p": [1, 2]
    }

    knn_gs = GridSearchCV(
        estimator=knn_pipeline,
        param_grid=knn_param_grid,
        cv=cv,
        scoring=scoring,
        n_jobs=-1
    )

    print("\nSearching best KNN parameters...")

    knn_gs.fit(X_train, y_train)

    print("\n=== KNN ===")
    print(f"Best parameters: {knn_gs.best_params_}")
    print(f"Best CV score:   {knn_gs.best_score_:.4f}")

    return dt_gs.best_estimator_, knn_gs.best_estimator_



def get_best_models(X_train, y_train, data_hash):
    cache_file = Path(CACHE_PATH)

    if cache_file.exists():
        print("\nSaved models found. Checking cache...")

        saved = joblib.load(cache_file)

        correct_version = (
            saved.get("cache_version") == CACHE_VERSION
        )

        same_data = (
            saved.get("data_hash") == data_hash
        )

        same_features = (
            saved.get("features") == list(X_train.columns)
        )

        if correct_version and same_data and same_features:
            print("Cached models are valid.")
            print("Loading models without GridSearchCV...")

            return (
                saved["decision_tree"],
                saved["knn"]
            )

        print("Dataset or configuration changed.")
        print("Models will be trained again.")

    best_dt, best_knn = grid_search_models(
        X_train,
        y_train
    )

    print("\nSaving trained models...")

    joblib.dump(
        {
            "cache_version": CACHE_VERSION,
            "data_hash": data_hash,
            "features": list(X_train.columns),

            "decision_tree": best_dt,
            "knn": best_knn
        },
        CACHE_PATH
    )

    print(f"Models saved to: {CACHE_PATH}")

    return best_dt, best_knn



def evaluate_model(name, model, X_test, y_test):
    predictions = model.predict(X_test)

    accuracy = accuracy_score(
        y_test,
        predictions
    )

    print(f"\n=== {name} ===")
    print(f"Accuracy: {accuracy:.4f}")

    print(
        classification_report(
            y_test,
            predictions,
            digits=4,
            zero_division=0
        )
    )

    return predictions, accuracy


def show_confusion_matrix(name, model, y_test, predictions):
    cm = confusion_matrix(
        y_test,
        predictions
    )

    print(f"\nConfusion Matrix — {name}:")
    print(cm)

    display = ConfusionMatrixDisplay(
        confusion_matrix=cm,
        display_labels=model.classes_
    )

    display.plot(cmap="Blues")

    plt.title(
        f"Confusion Matrix — {name}"
    )

    plt.show()



def visualize_tree(model, feature_names):
    print("\nDecision Tree visualization")

    plt.figure(figsize=(24, 12))

    plot_tree(
        model,
        feature_names=feature_names,
        class_names=[
            str(c)
            for c in model.classes_
        ],
        filled=True,
        rounded=True,

        max_depth=3,

        fontsize=8
    )

    plt.title("Decision Tree")

    plt.tight_layout()
    plt.show()

def visualize_knn(model, X_test):
    print("\nKNN visualization")

    preprocessing = model.named_steps["preprocessing"]
    knn = model.named_steps["knn"]
    X_processed = preprocessing.transform(X_test)

    pca = PCA(n_components=2)
    X_2d = pca.fit_transform(X_processed)

    predictions = model.predict(X_test)

    plt.figure(figsize=(10, 7))

    scatter = plt.scatter(
        X_2d[:, 0],
        X_2d[:, 1],
        c=predictions,
        cmap="coolwarm",
        alpha=0.7
    )

    plt.xlabel("PCA component 1")
    plt.ylabel("PCA component 2")
    plt.title(
        f"KNN predictions "
        f"(k={knn.n_neighbors}, "
        f"weights={knn.weights}, p={knn.p})"
    )

    plt.colorbar(
        scatter,
        label="Predicted class"
    )

    plt.grid(alpha=0.3)
    plt.show()
    
    

print("Loading data")

data_hash = get_file_hash(DATA_PATH)

data = loadData(DATA_PATH)


print("\nPreprocessing data")

data = preProcess(data)


print("\nCreating X and y")

X, y = makeMatrix(data)


print("\nDividing data into training and test sets")

x_train, x_test, y_train, y_test = splittingData(
    X,
    y
)



print("\nTraining base models")

dt, knn = train_base_models(
    x_train,
    y_train
)


print("\nEvaluating base Decision Tree")

y_pred_dt, acc_dt = evaluate_model(
    "Decision Tree (base)",
    dt,
    x_test,
    y_test
)


print("\nEvaluating base KNN")

y_pred_knn, acc_knn = evaluate_model(
    "KNN (base)",
    knn,
    x_test,
    y_test
)



print("\nGetting best models")

dt_best, knn_best = get_best_models(
    x_train,
    y_train,
    data_hash
)


print("\nFinal evaluation")

y_pred_dt_best, acc_dt_best = evaluate_model(
    "Decision Tree (best)",
    dt_best,
    x_test,
    y_test
)

y_pred_knn_best, acc_knn_best = evaluate_model(
    "KNN (best)",
    knn_best,
    x_test,
    y_test
)



show_confusion_matrix(
    "Decision Tree",
    dt_best,
    y_test,
    y_pred_dt_best
)

show_confusion_matrix(
    "KNN",
    knn_best,
    y_test,
    y_pred_knn_best
)



print("\nComparing models")

print(
    f"Decision Tree accuracy: "
    f"{acc_dt_best:.4f}"
)

print(
    f"KNN accuracy:           "
    f"{acc_knn_best:.4f}"
)


if acc_dt_best > acc_knn_best:
    print("\nBest model: Decision Tree")

    best_model = dt_best
    best_model_name = "Decision Tree"

elif acc_knn_best > acc_dt_best:
    print("\nBest model: KNN")

    best_model = knn_best
    best_model_name = "KNN"

else:
    print("\nBoth models have the same accuracy")

    best_model = dt_best
    best_model_name = "Decision Tree"



print(
    f"\nVisualizing best model: "
    f"{best_model_name}"
)

if best_model_name == "Decision Tree":

    visualize_tree(
        best_model,
        x_train.columns
    )

elif best_model_name == "KNN":

    visualize_knn(
        best_model,
        x_test
    )