# inheritence

class Animal:

    alive = True

    def eat(self):
        print("This animal is eating")

    def sleep(self):
        print("This animal is sleeping")

# rabbit is the child class, and animal is parent class
class Rabbit(Animal):
    pass
# child class will inherite everything from its parent class