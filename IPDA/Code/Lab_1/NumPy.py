import numpy as np

random_array = np.random.randint(0,10,size=(4,5))
print("Source 2d array with 20 values:")
print(random_array)
print()

print("Deviding source array in two:")

first_half  =random_array[:2,:]
second_half = random_array[2:,:]

print("First half:")
print(first_half)

print("Second half:")
print(second_half)
print()

value_to_find = 3

found_elements = random_array[random_array==value_to_find]
print("Found elements:")
print(found_elements)

found_count = np.sum(random_array==value_to_find)
print(f"Found elements count: {found_count}")