# abstract classes
# Abstract classes in Python are blueprints with unimplemented methods, meant for subclassing.

from abc import ABC, abstractmethod

class Vehicle(ABC):

    @abstractmethod
    def go(self):
        pass

class Car(Vehicle):

    def go(self):
        print("You drive the car")

class Motorcycle(Vehicle):

    def go(self):
        print("You ride the motorcycle")


vehicle = Vehicle()
car = Car()
motorcycle = Motorcycle()

vehicle.go()
car.go()
motorcycle.go()

# output: You drive the car
# You ride the motorcycle

# output: TypeError: Can't instantiate abstract class Vehicle with abstract methods go

