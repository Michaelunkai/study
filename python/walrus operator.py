# walrus operator :=
# assignment expression aka walrus operator
# assign values to variables as part of a larger expression

foods = list()
while True:
    food = input("What food do youl like?: ")
    if food == "quit":
        break
    foods.append(food)
# output: What food do youl like?: sushi
# What food do youl like?: pizza
# What food do youl like?: cheese