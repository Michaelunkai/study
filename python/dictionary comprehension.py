# # dictionary comprehension
# # Dictionary comprehension is a concise way
# # to create dictionaries using a single line of code.


# # cities_in_F = {'New York': 32, 'Boston':75, 'Los Angles':100, 'Chicago':50}

# # cities_in_C = {key: ((value-32)*(5/9)) for (key,value) in cities_in_F.items()} 
# # print(cities_in_C)

# # output: {'New York': 0.0, 'Boston': 23.88888888888889, 'Los Angles': 37.77777777777778, 'Chicago': 10.0}

# # with round:


# cities_in_F = {'New York': 32, 'Boston':75, 'Los Angles':100, 'Chicago':50}

# cities_in_C = {key: round((value-32)*(5/9)) for (key,value) in cities_in_F.items()} 
# print(cities_in_C)

# # output: 
# # {'New York': 0, 'Boston': 24, 'Los Angles': 38, 'Chicago': 10}

# _________________________________________________

# dictioanray of wheater
wheather = {'New York': "snowing", 'Boston': "sunny", 'Los Angles': "sunny", 'Chicago': "cloudy"}

# second dictionary with dictionary comperhension:
sunny_wheater = {key: value for (key,value) in wheather.items() if value == "sunny"}
print(sunny_wheater)

# output:
# {'Boston': 'sunny', 'Los Angles': 'sunny'}