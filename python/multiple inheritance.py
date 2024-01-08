# multiple inheritance
# Class inheriting from multiple classes, combining their features and functionality.

class Prey:

    def flee(self):
        print("This animal flees")

class Predator:

    def hunt(self):
        print("This animal is hunting")

# Multiple inheritance allows creating a new class inheriting from both Prey and Predator, combining fleeing and hunting functionalities seamlessly.
        
class Rabbit(Prey):
    pass

class Hawk(Predator):
    pass

class Fish(Prey, Predator):
    pass

# defining the classes:
rabbit = Rabbit()
hawk = Hawk()
fish = Fish()

rabbit.flee()
# output: This animal flees