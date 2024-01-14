# reduce
# apply a func to an iterable and reduce it to single cumulative value.
# perform function on first two elements and repeat pricess untill 1 value remains

# redice function

import functools

letters = ["H","E","L","L","O"]
word = functools.reduce(lambda x, y,:x + y,letters)
print(word)