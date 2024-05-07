import requests
import tkinter as tk

def find_open_food_places(api_key, location, radius):
    url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    params = {
        'key': api_key,
        'location': location,
        'radius': radius * 1000,  # Convert to meters
        'type': 'restaurant',  # filter for restaurants
        'opennow': 'true'  # filter for currently open places
    }
    response = requests.get(url, params=params)
    data = response.json()

    if data['status'] == 'OK':
        places = data['results']
        for i, place in enumerate(places, start=1):
            name = place['name']
            vicinity = place['vicinity']
            place_id = place['place_id']
            phone_number = get_phone_number(api_key, place_id)
            opening_hours = get_opening_hours(api_key, place_id)
            result_text.insert(tk.END, f'{i}. {name} - {vicinity} - Phone: {phone_number}\n')
            if opening_hours:
                result_text.insert(tk.END, f'   Opening hours: {opening_hours}\n')
    else:
        result_text.insert(tk.END, 'Failed to retrieve data.\n')

def get_phone_number(api_key, place_id):
    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    params = {
        'key': api_key,
        'place_id': place_id
    }
    response = requests.get(url, params=params)
    data = response.json()

    if data['status'] == 'OK':
        return data['result'].get('formatted_phone_number', 'Phone number not available')
    else:
        return 'Phone number not available'

def get_opening_hours(api_key, place_id):
    url = 'https://maps.googleapis.com/maps/api/place/details/json'
    params = {
        'key': api_key,
        'place_id': place_id,
        'fields': 'opening_hours'
    }
    response = requests.get(url, params=params)
    data = response.json()

    if data['status'] == 'OK':
        opening_hours = data['result'].get('opening_hours', {})
        if 'weekday_text' in opening_hours:
            return '\n'.join(opening_hours['weekday_text'])
    return None

def get_radius():
    try:
        radius = float(radius_entry.get())
        find_open_food_places(api_key_entry.get(), get_current_location(), radius)
    except ValueError:
        result_text.insert(tk.END, 'Invalid input for radius.\n')

def get_current_location():
    # Hardcoded latitude and longitude
    return "alltitude, here!"

if __name__ == '__main__':
    root = tk.Tk()
    root.title("Open Food Places")

    # Define bold font
    bold_font = ("Lobster", 10, "bold")

    # Set background color
    root.configure(bg="#FFE4B2")

    api_key_label = tk.Label(root, text="Enter your Google Places API Key:", font=bold_font, bg="#FFE4B2")
    api_key_label.pack()

    api_key_entry = tk.Entry(root, font=bold_font)
    api_key_entry.pack()
    api_key_entry.insert(tk.END, "api key here")  # Insert the API key

    radius_label = tk.Label(root, text="Enter the maximum distance from your location to search for open food places (in kilometers):", font=bold_font, bg="#FFE4B2")
    radius_label.pack()

    radius_entry = tk.Entry(root, font=bold_font)
    radius_entry.pack()

    search_button = tk.Button(root, text="Search", command=get_radius, font=bold_font)
    search_button.pack()

    result_label = tk.Label(root, text="Results:", font=bold_font, bg="#FFE4B2")
    result_label.pack()

    result_text = tk.Text(root, height=20, width=80, font=bold_font)
    result_text.pack()

    root.mainloop()
