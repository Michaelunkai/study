# super function
# super() calls parent class methods, facilitating inheritance and avoiding hardcoding class names.

class Rectangle:
    pass

class Square(Rectangle):

    def __init__(self, length, width):
        self.length = length
        self.width = width

class Cube(Rectangle):

    def __init__(self, length, width, height):
        self.length = length 
        self.width = width
        self.height = height