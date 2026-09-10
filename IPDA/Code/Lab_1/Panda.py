import numpy as np
import pandas as pd

np_array = np.random.randint(1,20,size=(10))
print(f"Source array from NumPy: {np_array}")

series = pd.Series(np_array)
print("Series pbject:")
print(series)
print()

print("Mathimatical operations:")
print(f"Sum:{series.sum()}")
print(f"Avg:{series.mean():.2f}")
print(f"Max:{series.max()}")
print(f"Min:{series.min()}")
print(f"Median:{series.median()}")
print(series.describe())
print()

print("Dataframes:")
np_data = np.random.randint(1,100,size=(6,5))
print("Source np array: ")
print(np_data)

np_dataframe = pd.DataFrame(np_data,columns=['A','B','C','D','E'])
print("Dataframe:")
print(np_dataframe)
print()

np_dataframe = np_dataframe.drop(index=2)
print("Dataframe after dropping the second line:")
print(np_dataframe)

np_dataframe = np_dataframe.drop(columns=['C'])
print("Dataframe after dropping column C:")
print(np_dataframe)
print()

print(f"Dataframe size: {np_dataframe.shape}")
print()

search_value = 65
print(f"Finding elements equal to {search_value}")
print("Found elements:")
dataframe_found = np_dataframe[np_dataframe==search_value]
print(dataframe_found)
print(f"Amount of elements found: {dataframe_found.count()}")
