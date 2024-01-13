# higher order functions
#  a function that either:
# 1. accepts a function as an argument
# or 
# 2. return a function
#  (in python, functions are also treated as objects)

# example:

def loud(text):
    return text.upper()

def quiet(text):
    return text.lower()

def hello(func):
    text = func("Hello")
    print(text)

hello(loud)
# output: HELLO