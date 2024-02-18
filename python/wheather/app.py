import requests

api_key= 'dcd8c4f8fe9a2165bb574775b1a23ebc'

user_input = input("Enter city: ")

wheather_data = requests.get(
    f"https://api.openweathermap.org/data/2.5/weather?q={user_input}&units=imperial&APPID={api_key}")

