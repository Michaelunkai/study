# zip function

# The zip function in Python
# combines corresponding elements from multiple 
# iterables into tuples,
# creating an iterator that produces pairs
# of elements.

usernames = ["Dude", "Bro", "Mister"]
passwords = ("password","Abc", "guest")

# to zip elements from each iterable togheter,so thair in pairs,
#  and each pair is going to be stored as a tuple within a zip object:

users = zip(usernames, passwords)

for i in users:
    print(i)

# output:
# ('Dude', 'password')
# ('Bro', 'Abc')
# ('Mister', 'guest')
    
# we got a zip object of tuples! and each tuple store each pair of elemts of my 2 iretables/
    
