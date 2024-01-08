# method overriding

class Animal:

    def eat(self):
        print("This animal is eating")

class Rabbit(Animal):
    pass


rabbit = Rabbit()
rabbit.eat()