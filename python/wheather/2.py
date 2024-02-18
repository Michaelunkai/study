import requests
import tkinter as tk
from tkinter import messagebox

def get_weather():
    user_input = city_entry.get()
    api_key = 'dcd8c4f8fe9a2165bb574775b1a23ebc'
    
    weather_data = requests.get(f"https://api.openweathermap.org/data/2.5/weather?q={user_input}&units=metric&APPID={api_key}")
    
    if weather_data.status_code == 200:
        weather = weather_data.json()['weather'][0]['main']
        temp = round(weather_data.json()['main']['temp'])
        result_label.config(text=f"The weather in {user_input} is: {weather}\nThe temperature in {user_input} is: {temp}°C")
    else:
        messagebox.showerror("Error", "Failed to retrieve weather data. Please check your input or try again later.")

# GUI setup
root = tk.Tk()
root.title("Weather App")
root.geometry("300x200")  # Set initial window size

# Set icon for the app
icon_path = "/mnt/c/Users/micha/Downloads/1779940.ico"
root.iconbitmap(icon_path)

city_label = tk.Label(root, text="Enter city:", font=("Arial", 12))
city_label.grid(row=0, column=0, padx=10, pady=10)

city_entry = tk.Entry(root, font=("Arial", 12))
city_entry.grid(row=0, column=1, padx=10, pady=10)

get_weather_button = tk.Button(root, text="Get Weather", command=get_weather, font=("Arial", 12))
get_weather_button.grid(row=1, column=0, columnspan=2, pady=10)

result_label = tk.Label(root, text="", font=("Arial", 12))
result_label.grid(row=2, column=0, columnspan=2, padx=10, pady=10)

root.mainloop()
