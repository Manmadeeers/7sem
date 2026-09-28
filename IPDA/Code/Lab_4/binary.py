import numpy as np
import pandas as pd
import seaborn as sb
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import GridSearchCV
from sklearn.metrics import accuracy_score, classification_report
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
from sklearn.tree import plot_tree
import matplotlib.pyplot as plt

def loadData(path):
    data = pd.read_csv(path)
    print("Data loaded")
    return data

def preProcess(data):
    data.info()
    print(f"\nNull values:\n{data[data.eq(0)].count()}")
    
    
    print("\nDeleting anomalies:")
    data = data[(data['person_age'] <= 100) & (data['person_emp_exp'] <= 60)]
    
    print(f"\nMissings count:\n{data.isnull().sum()}")
    
    print("\nConverting categorized to numeric");
    data['person_gender'] = data['person_gender'].map({'male': 0, 'female': 1})
    data['previous_loan_defaults_on_file'] = data['previous_loan_defaults_on_file'].map({'No': 0, 'Yes': 1})
    
    data = pd.get_dummies(data, columns=['person_education', 'person_home_ownership', 'loan_intent'], drop_first=True)
    
    data.info()
    
    dups = data.duplicated().sum()
    print(f"\nCounting dupplicates: {dups}")
    if dups!=0:
        print("\nDropping dupplicates:")
        data = data.drop_duplicates();
        data.info();
        
        
    return data


def makeMatrix(data):
    y=data['loan_status']
    X=data.drop(columns=['loan_status'])
    print(f"\nX: {X.shape}")
    print(f"\nY: {y.shape}")
    
    
    
    return [X,y]

def splittingData(X, y):
    X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y)
    
    print(f"Train: {X_train.shape}")
    print(f"Test: {X_test.shape}")

    return [X_train,X_test,y_train,y_test]

def scaleData(X_train,X_test):
    num_features = ['person_age', 'person_income', 'person_emp_exp', 'loan_amnt',
                'loan_int_rate', 'loan_percent_income',
                'cb_person_cred_hist_length', 'credit_score']
    
    scaler = StandardScaler()
    X_train_scaled = X_train.copy()
    X_test_scaled  = X_test.copy()
    X_train_scaled[num_features] = scaler.fit_transform(X_train[num_features])
    X_test_scaled[num_features]  = scaler.transform(X_test[num_features])
    
    return [X_test_scaled,X_train_scaled]


def grid_search_models(X_train, y_train, X_train_scaled,
                       cv=5, scoring='accuracy'):
    dt_param_grid = {
        'max_depth': [3, 5, 7, 10, 15, 20, None],
        'min_samples_leaf': [1, 3, 5, 10, 20],
        'min_samples_split': [2, 5, 10],
        'criterion': ['gini', 'entropy']
    }
    dt_gs = GridSearchCV(
        DecisionTreeClassifier(random_state=42),
        dt_param_grid,
        cv=cv, scoring=scoring, n_jobs=-1
    )
    dt_gs.fit(X_train, y_train)
    print("=== Decision Tree ===")
    print(f"Лучшие параметры: {dt_gs.best_params_}")
    print(f"Лучший CV-score: {dt_gs.best_score_:.4f}")

    knn_param_grid = {
        'n_neighbors': list(range(3, 32, 2)),
        'weights': ['uniform', 'distance'],
        'p': [1, 2]         
    }
    knn_gs = GridSearchCV(
        KNeighborsClassifier(),
        knn_param_grid,
        cv=cv, scoring=scoring, n_jobs=-1
    )
    knn_gs.fit(X_train_scaled, y_train)
    print("\n=== KNN ===")
    print(f"Лучшие параметры: {knn_gs.best_params_}")
    print(f"Лучший CV-score: {knn_gs.best_score_:.4f}")

    return dt_gs.best_estimator_, knn_gs.best_estimator_



print("Loading data")
data = loadData("./data.csv")
print("\nPreprocessing data")
data = preProcess(data)

print("\nCreating matricies")
matrixArray = makeMatrix(data)

print("\nDeviding data into learning and test data")
testAndTrain = splittingData(matrixArray[0],matrixArray[1])
x_train = testAndTrain[0]
x_test = testAndTrain[1]
y_train = testAndTrain[2]
y_test = testAndTrain[3]

print("\nScaling data for KNN")
scaled = scaleData(testAndTrain[0],testAndTrain[1])
x_test_scaled = scaled[0]
x_train_scaled = scaled[1]


print("\nBuilding decision tree")

dt = DecisionTreeClassifier(
    criterion='gini',
    max_depth=5,         
    min_samples_leaf=5,
    random_state=42
)

dt.fit(x_train,y_train)
y_pred_dt = dt.predict(x_test)

acc_dt = accuracy_score(y_test, y_pred_dt)
print(f"Decision Tree — Accuracy: {acc_dt:.4f}")
print(classification_report(y_test, y_pred_dt, digits=4))

print("\nBuilding KNN")

knn = KNeighborsClassifier(
    n_neighbors=5,
    weights='uniform',
    metric='minkowski',
    p=2                
)

knn.fit(x_train_scaled,y_train)
y_pred_knn = knn.predict(x_test_scaled)

acc_knn = accuracy_score(y_test, y_pred_knn)
print(f"KNN (k=5) — Accuracy: {acc_knn:.4f}")
print(classification_report(y_test, y_pred_knn, digits=4))


print("\nFinding the best parameters")
best_dt_model, best_knn_model = grid_search_models(x_train, y_train, x_train_scaled)

print("\nFinal models evaluation with best found parameters")

dt_best  = best_dt_model
knn_best = best_knn_model

y_pred_dt_best  = dt_best.predict(x_test)
print(f"\nDecision Tree (best) — Accuracy: "
      f"{accuracy_score(y_test, y_pred_dt_best):.4f}")
print(classification_report(y_test, y_pred_dt_best, digits=4))

y_pred_knn_best = knn_best.predict(x_test_scaled)
print(f"\nKNN (best) — Accuracy: "
      f"{accuracy_score(y_test, y_pred_knn_best):.4f}")
print(classification_report(y_test, y_pred_knn_best, digits=4))

print("\nConfusion matrix for both models");

# Decision Tree
cm_dt = confusion_matrix(y_test, y_pred_dt_best)

print("Confusion Matrix — Decision Tree:")
print(cm_dt)

disp_dt = ConfusionMatrixDisplay(
    confusion_matrix=cm_dt,
    display_labels=dt_best.classes_
)

disp_dt.plot(cmap="Blues")
plt.title("Confusion Matrix — Decision Tree")
plt.show()


# KNN
cm_knn = confusion_matrix(y_test, y_pred_knn_best)

print("Confusion Matrix — KNN:")
print(cm_knn)

disp_knn = ConfusionMatrixDisplay(
    confusion_matrix=cm_knn,
    display_labels=knn_best.classes_
)

disp_knn.plot(cmap="Blues")
plt.title("Confusion Matrix — KNN")
plt.show()

print("\nCOmpating models")

acc_dt_best = accuracy_score(y_test, y_pred_dt_best)
acc_knn_best = accuracy_score(y_test, y_pred_knn_best)

print(f"Decision Tree accuracy: {acc_dt_best:.4f}")
print(f"KNN accuracy:           {acc_knn_best:.4f}")

if acc_dt_best > acc_knn_best:
    print("\nBest model: Decision Tree")
    best_model = dt_best

elif acc_knn_best > acc_dt_best:
    print("\nBest model: KNN")
    best_model = knn_best

else:
    print("\nBoth models have the same accuracy")


print("\nBest model visualization")

plt.figure(figsize=(24, 12))

plot_tree(
    dt_best,
    feature_names=x_train.columns,
    class_names=[str(c) for c in dt_best.classes_],
    filled=True,
    rounded=True,
    max_depth=3,
    fontsize=8
)

plt.title("Decision Tree")
plt.show()