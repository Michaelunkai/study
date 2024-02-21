import sqlite3
import tkinter as tk
from tkinter import messagebox

# Connect to SQLite database or create it if it doesn't exist
conn = sqlite3.connect('wishlist.db')

# Create a cursor object
cursor = conn.cursor()

# Define SQL queries to create tables for movies, TV shows, and games
create_movies_table = """CREATE TABLE IF NOT EXISTS movies (
                            id INTEGER PRIMARY KEY,
                            title TEXT
                        )"""

create_tv_shows_table = """CREATE TABLE IF NOT EXISTS tv_shows (
                                id INTEGER PRIMARY KEY,
                                title TEXT
                            )"""

create_games_table = """CREATE TABLE IF NOT EXISTS games (
                            id INTEGER PRIMARY KEY,
                            title TEXT
                        )"""

# Execute SQL queries to create tables
cursor.execute(create_movies_table)
cursor.execute(create_tv_shows_table)
cursor.execute(create_games_table)

# Commit changes to the database
conn.commit()

# Function to add a new movie to the database
def add_movie():
    titles = movie_entry.get("1.0", "end").split('\n')
    for title in titles:
        if title.strip():
            cursor.execute("INSERT INTO movies (title) VALUES (?)", (title.strip(),))
    conn.commit()
    messagebox.showinfo("Success", "Movie(s) added successfully!")

# Function to add a new TV show to the database
def add_tv_show():
    titles = tv_show_entry.get("1.0", "end").split('\n')
    for title in titles:
        if title.strip():
            cursor.execute("INSERT INTO tv_shows (title) VALUES (?)", (title.strip(),))
    conn.commit()
    messagebox.showinfo("Success", "TV show(s) added successfully!")

# Function to add a new game or multiple games to the database
def add_game():
    titles = game_entry.get("1.0", "end").split('\n')
    for title in titles:
        if title.strip():
            cursor.execute("INSERT INTO games (title) VALUES (?)", (title.strip(),))
    conn.commit()
    messagebox.showinfo("Success", "Game(s) added successfully!")

# Function to delete listings
def delete_listings(category):
    confirm = messagebox.askyesno("Confirm Delete", f"Are you sure you want to delete all {category.replace('_', ' ')}?")
    if confirm:
        if category == "movies":
            cursor.execute("DELETE FROM movies")
        elif category == "tv_shows":
            cursor.execute("DELETE FROM tv_shows")
        elif category == "games":
            cursor.execute("DELETE FROM games")
        
        conn.commit()
        messagebox.showinfo("Success", f"All {category.replace('_', ' ')} deleted successfully.")

# Function to view wishlist items
def view_wishlist():
    # Create a new window for displaying wishlist items
    view_window = tk.Toplevel(root)
    view_window.title("View Wishlist")

    # Query all movies
    cursor.execute("SELECT * FROM movies")
    movies = cursor.fetchall()
    if movies:
        movie_label = tk.Label(view_window, text="Movies", font=("Helvetica", 16, "bold"), fg="red")
        movie_label.pack()
        for movie in movies:
            movie_item = tk.Label(view_window, text=movie[1])
            movie_item.pack()
    else:
        movie_label = tk.Label(view_window, text="No movies found")
        movie_label.pack()

    # Query all TV shows
    cursor.execute("SELECT * FROM tv_shows")
    tv_shows = cursor.fetchall()
    if tv_shows:
        tv_label = tk.Label(view_window, text="TV Shows", font=("Helvetica", 16, "bold"), fg="red")
        tv_label.pack()
        for tv_show in tv_shows:
            tv_item = tk.Label(view_window, text=tv_show[1])
            tv_item.pack()
    else:
        tv_label = tk.Label(view_window, text="No TV shows found")
        tv_label.pack()

    # Query all games
    cursor.execute("SELECT * FROM games")
    games = cursor.fetchall()
    if games:
        game_label = tk.Label(view_window, text="Games", font=("Helvetica", 16, "bold"), fg="red")
        game_label.pack()
        for game in games:
            game_item = tk.Label(view_window, text=game[1])
            game_item.pack()
    else:
        game_label = tk.Label(view_window, text="No games found")
        game_label.pack()

# Main window
root = tk.Tk()
root.title("Wishlist Manager")

# Labels
movie_label = tk.Label(root, text="Movie(s):", font=("Helvetica", 12, "bold"), fg="red")
movie_label.grid(row=0, column=0, padx=5, pady=5)
tv_show_label = tk.Label(root, text="TV Show(s):", font=("Helvetica", 12, "bold"), fg="red")
tv_show_label.grid(row=1, column=0, padx=5, pady=5)
game_label = tk.Label(root, text="Game(s):", font=("Helvetica", 12, "bold"), fg="red")
game_label.grid(row=2, column=0, padx=5, pady=5)

# Entry widgets
movie_entry = tk.Text(root, height=5, width=30)
movie_entry.grid(row=0, column=1, padx=5, pady=5)
tv_show_entry = tk.Text(root, height=5, width=30)
tv_show_entry.grid(row=1, column=1, padx=5, pady=5)
game_entry = tk.Text(root, height=5, width=30)
game_entry.grid(row=2, column=1, padx=5, pady=5)

# Buttons
add_button = tk.Button(root, text="Add", width=10, command=add_movie)
add_button.grid(row=0, column=2, padx=5, pady=5)
add_button = tk.Button(root, text="Add", width=10, command=add_tv_show)
add_button.grid(row=1, column=2, padx=5, pady=5)
add_button = tk.Button(root, text="Add", width=10, command=add_game)
add_button.grid(row=2, column=2, padx=5, pady=5)

# View button
view_button = tk.Button(root, text="View Wishlist", command=view_wishlist, font=("Helvetica", 12, "bold"), fg="red")
view_button.grid(row=3, column=0, columnspan=3, pady=10)

# Delete buttons
delete_movie_button = tk.Button(root, text="Delete Movies", command=lambda: delete_listings("movies"), font=("Helvetica", 12, "bold"), fg="red")
delete_movie_button.grid(row=4, column=0, pady=5)
delete_tv_show_button = tk.Button(root, text="Delete TV Shows", command=lambda: delete_listings("tv_shows"), font=("Helvetica", 12, "bold"), fg="red")
delete_tv_show_button.grid(row=4, column=1, pady=5)
delete_game_button = tk.Button(root, text="Delete Games", command=lambda: delete_listings("games"), font=("Helvetica", 12, "bold"), fg="red")
delete_game_button.grid(row=4, column=2, pady=5)

# Start the GUI
root.mainloop()

# Close the database connection
conn.close()
