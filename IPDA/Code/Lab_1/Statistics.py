import pandas as pd
import matplotlib.pyplot as plt

file_path = 'offers.csv'
try:
    df = pd.read_csv(file_path)
    print("File loaded")
except FileNotFoundError:
    print(f"File not found")
    exit()

print("\nFirst five lines in a dataset")
print(df.head())
print("\n Dataset info")
print(df.info())

print("\nStatistic for 'Stock' column")
median_stock = df['Stock'].median()
mean_stock = df['Stock'].mean()
print(f"Median value: {median_stock}")
print(f"Average value: {mean_stock}")

plt.figure(figsize=(8, 6))
plt.boxplot(df['Stock'])
plt.title('Box plot for "Stock" column')
plt.ylabel('Stock value')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()

print("\nStatistic for 'Price' column")
median_price = df['Price'].median()
mean_price = df['Price'].mean()
print(f"Median value: {median_price}")
print(f"Average value: {mean_price}")

plt.figure(figsize=(8, 6))
plt.boxplot(df['Price'])
plt.title('Box plot for "Price" column')
plt.ylabel('Price value')
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.show()

print("\nDescribing 'Stock' column's statistics using .describe()")
describe_stock = df['Stock'].describe()
print(describe_stock)

print("\nDescribing 'Price' column's statistics using .describe()")
describe_price = df['Price'].describe()
print(describe_price)