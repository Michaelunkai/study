# inheritence

class Animal:

    alive = True

    def eat(self):
        print("This animal is eating")

    def sleep(self):
        print("This animal is sleeping")

class Rabbit(Animal):
    pass
class Fish(Animal):
    pass
class Hawk(Animal):
    pass
# 1 parent class , 3 children

# creating objects from this classes:
rabbit = Rabbit()
fish = Fish()
hawk = Hawk()

print(rabbit.alive)
fish.eat
Hawk.sleep