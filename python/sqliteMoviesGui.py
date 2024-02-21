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

    # Create a frame for movies
    movie_frame = tk.Frame(view_window)
    movie_frame.pack(side=tk.LEFT, padx=10, pady=10)

    # Query all movies
    cursor.execute("SELECT * FROM movies")
    movies = cursor.fetchall()
    if movies:
        movie_label = tk.Label(movie_frame, text="Movies", font=("Helvetica", 16, "bold"), fg="red")
        movie_label.pack()
        movie_list = tk.Listbox(movie_frame, height=20, width=50)
        for movie in movies:
            movie_list.insert(tk.END, movie[1])
        movie_list.pack(side=tk.LEFT, fill=tk.Y)
        movie_scroll = tk.Scrollbar(movie_frame, orient=tk.VERTICAL)
        movie_scroll.config(command=movie_list.yview)
        movie_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        movie_list.config(yscrollcommand=movie_scroll.set)
    else:
        movie_label = tk.Label(movie_frame, text="No movies found")
        movie_label.pack()

    # Create a frame for TV shows
    tv_show_frame = tk.Frame(view_window)
    tv_show_frame.pack(side=tk.LEFT, padx=10, pady=10)

    # Query all TV shows
    cursor.execute("SELECT * FROM tv_shows")
    tv_shows = cursor.fetchall()
    if tv_shows:
        tv_label = tk.Label(tv_show_frame, text="TV Shows", font=("Helvetica", 16, "bold"), fg="red")
        tv_label.pack()
        tv_list = tk.Listbox(tv_show_frame, height=20, width=50)
        for tv_show in tv_shows:
            tv_list.insert(tk.END, tv_show[1])
        tv_list.pack(side=tk.LEFT, fill=tk.Y)
        tv_scroll = tk.Scrollbar(tv_show_frame, orient=tk.VERTICAL)
        tv_scroll.config(command=tv_list.yview)
        tv_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        tv_list.config(yscrollcommand=tv_scroll.set)
    else:
        tv_label = tk.Label(tv_show_frame, text="No TV shows found")
        tv_label.pack()

    # Create a frame for games
    game_frame = tk.Frame(view_window)
    game_frame.pack(side=tk.LEFT, padx=10, pady=10)

    # Query all games
    cursor.execute("SELECT * FROM games")
    games = cursor.fetchall()
    if games:
        game_label = tk.Label(game_frame, text="Games", font=("Helvetica", 16, "bold"), fg="red")
        game_label.pack()
        game_list = tk.Listbox(game_frame, height=20, width=50)
        for game in games:
            game_list.insert(tk.END, game[1])
        game_list.pack(side=tk.LEFT, fill=tk.Y)
        game_scroll = tk.Scrollbar(game_frame, orient=tk.VERTICAL)
        game_scroll.config(command=game_list.yview)
        game_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        game_list.config(yscrollcommand=game_scroll.set)
    else:
        game_label = tk.Label(game_frame, text="No games found")
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

# Start the GUI
root.mainloop()

# Close the database connection
conn.close()
