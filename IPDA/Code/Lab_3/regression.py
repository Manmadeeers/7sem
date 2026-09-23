import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from sklearn.metrics import r2_score, mean_squared_error
from pandas.plotting import scatter_matrix

df = pd.read_csv('data.csv')

print("\nPrepared data: ")

df['Gender_enc'] = (df['Gender'] == 'F').astype(int)   # F=1, M=0
df['Result_enc'] = (df['Final_Result'] == 'Pass').astype(int)

features = ['Study_Hours', 'Attendance', 'Science_Score', 'Sleep_Hours',
            'Internet_Usage_Hours', 'Gender_enc', 'Result_enc']
target = 'Math_Score'

print(df[features + [target]].describe())


print("\nCorelations heatmap")
plt.figure(figsize=(9, 7))
corr = df[features + [target]].corr()
sns.heatmap(corr, annot=True, fmt=".2f", cmap="vlag", center=0,
            square=True, linewidths=0.5)
plt.title("Corelations heatmap")
plt.tight_layout()
plt.show()


print("\nScatter matrix:")
scatter_matrix(df[features + [target]], figsize=(14, 14),
               alpha=0.4, diagonal='hist', color='steelblue')
plt.suptitle("Scatter matrix", y=0.92)
plt.show()


print("\nSimple linear regression. Chose Study_hours parameter:")

X1 = df[['Study_Hours']]
y  = df['Math_Score']

model1 = LinearRegression().fit(X1, y)

plt.figure(figsize=(8, 5))
plt.scatter(X1, y, alpha=0.4, label='Data')
x_range = np.linspace(X1.min(), X1.max(), 100).reshape(-1, 1)
plt.plot(x_range, model1.predict(x_range), color='red', lw=2,
         label=f'y = {model1.coef_[0]:.2f}x + {model1.intercept_:.2f}')
plt.xlabel('Study_Hours'); plt.ylabel('Math_Score')
plt.title('Simple linear regression: Math_Score ~ Study_Hours')
plt.legend(); plt.grid(alpha=0.3); plt.show()

print(f"Coef:: {model1.coef_[0]:.4f}")
print(f"Intercept: {model1.intercept_:.4f}")#Свободный член

print("\nSimple model grading:")

y_pred1 = model1.predict(X1)
r2_1  = r2_score(y, y_pred1)
rmse1 = np.sqrt(mean_squared_error(y, y_pred1))
print(f"R² = {r2_1:.4f}")
print(f"RMSE = {rmse1:.4f}")


print("\nAdding potentially corelating things:")

X_multi = df[['Study_Hours', 'Attendance', 'Science_Score',
              'Sleep_Hours', 'Internet_Usage_Hours',
              'Gender_enc', 'Result_enc']]


print("\nMulti regression and it's grading:")

model2 = LinearRegression().fit(X_multi, y)
y_pred2 = model2.predict(X_multi)

r2_2   = r2_score(y, y_pred2)
rmse2  = np.sqrt(mean_squared_error(y, y_pred2))
print(f"R² (multi) = {r2_2:.4f}")
print(f"RMSE (multi) = {rmse2:.4f}")

coefs = pd.Series(model2.coef_, index=X_multi.columns).sort_values()
print(coefs)

plt.figure(figsize=(6, 6))
plt.scatter(y, y_pred2, alpha=0.4)
plt.plot([y.min(), y.max()], [y.min(), y.max()], 'r--')
plt.xlabel('Real values'); plt.ylabel('Forecast')
plt.title(f'Multiple regression: (R²={r2_2:.3f})')
plt.grid(alpha=0.3); plt.show()