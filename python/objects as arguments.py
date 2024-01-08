# objects as arguments
class Car:

    color = None

class Motorcycle:

    color = None

def change_color(vehicle,color):

    vehicle.color = color


car_1 = Car()
car_2 = Car()
car_3 = Car()

change_color(car_1,"red")
change_color(car_2,"white")
change_color(car_3,"blue")


print(car_1.color)
print(car_2.color)
print(car_3.color)

# output:
# red
# white
# blue