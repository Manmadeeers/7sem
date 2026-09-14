import pandas as pd
import numpy as np
import seaborn as sb
import matplotlib.pyplot as plt
import matplotlib.mlab as mlb
from sklearn.impute import KNNImputer
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import StandardScaler



def histogram():
    numeric_cols = cleaned.select_dtypes(include="number").columns.tolist()
    numeric_cols = [c for c in numeric_cols if cleaned[c].nunique() > 1]

    n = len(numeric_cols)
    fig, axes = plt.subplots(n, 2, figsize=(12, 3 * n), sharex="col")
    for i, col in enumerate(numeric_cols):
        combined = pd.concat([data[col], cleaned[col]]).dropna()
        bins = np.histogram_bin_edges(combined, bins=50)

    # Before
        axes[i, 0].hist(data[col].dropna(), bins=bins,
                    color="#4c72b0", edgecolor="black")
        axes[i, 0].set_ylabel("Frequency")
        axes[i, 0].set_title(f"Before — {col}" if i == 0 else f"Before — {col}")

    # After
        axes[i, 1].hist(cleaned[col].dropna(), bins=bins,
                    color="#55a868", edgecolor="black")
        axes[i, 1].set_title(f"After — {col}" if i == 0 else f"After — {col}")
        
    plt.tight_layout()
    plt.show()
    
    
def countDups(cleaned):
    dup_count = cleaned.duplicated().sum()
    print(f"\n Fully duplicated rows: {dup_count}")
    dups=cleaned[cleaned.duplicated(keep=False)]
    print(f"\nTotal rows involved in dupplication: {len(dups)}")
    
    if(dup_count!=0):
        before = len(cleaned)
        cleaned = cleaned.drop_duplicates(keep="last")
        after = len(cleaned)
        print(f"\nRemoved {before-after} duplicates")
    
    return cleaned
            
    
def detectOutliers(series):
    q1 = series.quantile(0.25)
    q3 = series.quantile(0.75)
    iqr = q3 - q1
    lower = q1 - 3.0 * iqr
    upper = q3 + 3.0 * iqr
    return (series < lower) | (series > upper), lower, upper


def investigate_outliers(cleaned, col, multiplier=1.5):
    q1 = cleaned[col].quantile(0.25)
    q3 = cleaned[col].quantile(0.75)
    iqr = q3 - q1
    lower = q1 - multiplier * iqr
    upper = q3 + multiplier * iqr

    mask = (cleaned[col] < lower) | (cleaned[col] > upper)
    n = mask.sum()

    print(f"\n{'='*60}")
    print(f"Column: {col}")
    print(f"  Q1={q1:.2f}  Q3={q3:.2f}  IQR={iqr:.2f}")
    print(f"  Fences: [{lower:.2f}, {upper:.2f}]")
    print(f"  Outliers: {n}  ({100*n/len(cleaned):.2f}%)")

    if n > 0:
        print(f"\n  Lowest 5 outliers:")
        print(cleaned.loc[mask, col].nsmallest(5).to_string())
        print(f"\n  Highest 5 outliers:")
        print(cleaned.loc[mask, col].nlargest(5).to_string())

        # Peek at full rows for the most extreme cases
        print(f"\n  Context — 5 highest outlier rows:")
        print(cleaned.loc[cleaned[col].nlargest(5).index]
              .to_string(max_colwidth=20))

    return mask, lower, upper


    for col in ["price", "mileage", "hp", "year"]:
        investigate_outliers(cleaned, col)
    fig, axes = plt.subplots(1, 4, figsize=(16, 5))
    for ax, col in zip(axes, ["price", "mileage", "hp", "year"]):
        ax.boxplot(cleaned[col].dropna(), vert=True)
        ax.set_title(col)
    plt.tight_layout()  
    plt.show()

def toNumeric(cleaned):
    one_hot_cols = ["make", "fuel", "offerType"]
    cleaned = pd.get_dummies(cleaned, columns=one_hot_cols, dtype=int)
    print(f"\nAfter One-Hot: {cleaned.shape}")
    le = LabelEncoder()
    cleaned["model_encoded"] = le.fit_transform(cleaned["model"].astype(str))
    cleaned["gear_encoded"]  = le.fit_transform(cleaned["gear"].astype(str))
    cleaned = cleaned.drop(columns=["model", "gear"])
    print(f"Final shape: {cleaned.shape}")
    print(f"Dtypes:\n{cleaned.dtypes}")
    print(f"\nAny non-numeric columns left?")
    print(cleaned.select_dtypes(exclude="number").columns.tolist())
    
    return cleaned


def normalize(cleaned):
    numeric_cols = cleaned.select_dtypes(include="number").columns.tolist()
    scaler = StandardScaler()
    cleaned_scaled = cleaned.copy()
    cleaned_scaled[numeric_cols] = scaler.fit_transform(cleaned[numeric_cols])
    print("Before:")
    print(cleaned[numeric_cols].describe().loc[["mean", "std"]])    
    print("\nAfter:")
    print(cleaned_scaled[numeric_cols].describe().loc[["mean", "std"]])
    
    cleaned_scaled.to_csv("normalized.csv",index=False)
    return cleaned_scaled

print("\nCounting non-null values")
data = pd.read_csv("./dataset.csv")
data.info()

print("\nCounting null values")
print(data[data.eq(0)].count())

cols = data.columns[:]

nulls = data[cols].isnull()
print("Total missing cells:", nulls.values.sum())
print("Missing per column:\n", nulls.sum())

colors = ["#eeeeee",'#00ff00']
print("\nHeatmap")
sb.heatmap(data[cols].isnull(),cmap=sb.color_palette(colors))
plt.show()

threshold = 0.25
cleaned = data.copy()

missing_cols = cleaned.isnull().mean()
cols_dropped = missing_cols[missing_cols>threshold].index
cleaned = cleaned.drop(columns=cols_dropped)

missing_rows = cleaned.isnull().mean(axis=1)
rows_dropped = missing_rows[missing_rows>threshold].index
cleaned = cleaned.drop(index=rows_dropped)

print(f"\nDeleted columns: {len(cols_dropped)}->{list(cols_dropped)}")
print(f"\nDeleted rows: {len(rows_dropped)}")
print(f"\n Shape before: {data.shape}")
print(f"\n Shape after: {cleaned.shape}")

cleaned_cols = cleaned.columns[:]
cleaned_colors=['#00ff00',"#eeeeee"]

print("Missing cells remaining in cleaned:", cleaned.isnull().values.sum())
print("Cleaned shape:", cleaned.shape)
print("Cleaned columns:", list(cleaned.columns))

sb.heatmap(cleaned[cleaned_cols].isnull(), cmap=sb.color_palette(colors),vmin=0,vmax=1,cbar=True)
plt.show()


print("\nReplacing data:")
cleaned["fuel"]      = cleaned["fuel"].fillna(cleaned["fuel"].mode()[0])
cleaned["gear"]      = cleaned["gear"].fillna(cleaned["gear"].mode()[0])
cleaned["offerType"] = cleaned["offerType"].fillna(cleaned["offerType"].mode()[0])

numeric_cols = cleaned.select_dtypes(include="number").columns.tolist()
imputer = KNNImputer(n_neighbors=5, weights="distance")
cleaned[numeric_cols] = imputer.fit_transform(cleaned[numeric_cols])

sb.heatmap(cleaned[cleaned_cols].isnull(), cmap=sb.color_palette(colors),vmin=0,vmax=1,cbar=True)
plt.show()


histogram()

cleaned = countDups(cleaned)


for col in ["price", "mileage", "hp", "year"]:
    mask, lo, hi = detectOutliers(cleaned[col])
    print(f"{col}: {mask.sum()} outliers  (valid range: {lo:.1f} – {hi:.1f})") 
    investigate_outliers(cleaned,col)

cleaned = toNumeric(cleaned)

cleaned = normalize(cleaned)