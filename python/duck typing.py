# duck typing

# ducl typing = concept where the class of an object is less
#  important than the methods/attributes are present
# "if it walked like a duck, and it quack like a duck, than its a duck"

class duck:

    def walk(self):
        print("This duck is walking")

    def talk(self):
        print("This duck is qwuacking")

class Chicken:

    def walk(self):
        print("This chicken is walking")

    def talk(self):
        print("This chicken is clucking")