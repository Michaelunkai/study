import requests
import tkinter as tk
from tkinter import messagebox

def get_weather(api_key, city):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={api_key}&units=metric"
    response = requests.get(url)
    data = response.json()
    return data

def get_city_suggestions(api_key, city_prefix):
    url = f"http://api.openweathermap.org/geo/1.0/direct?q={city_prefix}&limit=5&appid={api_key}"
    response = requests.get(url)
    data = response.json()
    if isinstance(data, list):
        cities = [city["name"] for city in data]
        return cities
    else:
        return []

def show_weather():
    city = city_entry.get()
    if city:
        try:
            weather_data = get_weather(api_key, city)
            if weather_data.get("cod") == 200:
                temperature = weather_data["main"]["temp"]
                description = weather_data["weather"][0]["description"]
                result_label.config(text=f"The current temperature in {city} is {temperature}°C with {description}.")
            else:
                messagebox.showerror("Error", "City not found. Please enter a valid city name.")
        except Exception as e:
            messagebox.showerror("Error", str(e))
    else:
        messagebox.showerror("Error", "Please enter a city name.")

def suggest_cities(event):
    city_prefix = city_entry.get()
    if city_prefix:
        try:
            suggested_cities = get_city_suggestions(api_key, city_prefix)
            city_listbox.delete(0, tk.END)
            for city in suggested_cities:
                city_listbox.insert(tk.END, city)
        except Exception as e:
            messagebox.showerror("Error", str(e))

api_key = "dcd8c4f8fe9a2165bb574775b1a23ebc"

root = tk.Tk()
root.title("Weather App")

city_label = tk.Label(root, text="Enter city name:")
city_label.pack()

city_entry = tk.Entry(root)
city_entry.pack()
city_entry.bind("<KeyRelease>", suggest_cities)

city_listbox = tk.Listbox(root, width=50)
city_listbox.pack()

result_label = tk.Label(root, text="")
result_label.pack()

search_button = tk.Button(root, text="Search", command=show_weather)
search_button.pack()

root.mainloop()
