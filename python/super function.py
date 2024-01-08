# super function
# super() calls parent class methods, facilitating inheritance and avoiding hardcoding class names.

class Rectangle:
    
    def __init__(self, length, width):
        self.length = length
        self.width = width

class Square(Rectangle):

    def __init__(self, length, width):
        super().__init__(length,width)


class Cube(Rectangle):

    def __init__(self, length, width, height):
        super().__init__(length,width)
        self.height = height

Square = Square(3, 3)
cube = Cube(3, 3, 3)
