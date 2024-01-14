# list comprehension
# List comprehension in Python is concise syntax for creating lists, combining
#  loops and conditions, 
# making code efficient and readable.

# squares = [] #create an empty list
# for i in range(1,11): #create a for loop
#     squares.append(i * i) # define what each loop iteration should be
# print(squares)
# output: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

# same, with list comprehension:

squares = [i * i for i in range(1,11)]
print(squares)