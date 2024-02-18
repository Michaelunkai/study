import requests

api_key = 'dcd8c4f8fe9a2165bb574775b1a23ebc'

user_input = input("Enter city: ")

weather_data = requests.get(
    f"https://api.openweathermap.org/data/2.5/weather?q={user_input}&units=metric&APPID={api_key}")

if weather_data.status_code == 200:
    weather = weather_data.json()['weather'][0]['main']
    temp = round(weather_data.json()['main']['temp'])
    print("Weather:", weather)
    print("Temperature (Celsius):", temp)
else:
    print("Failed to retrieve weather data. Please check your input or try again later.")
