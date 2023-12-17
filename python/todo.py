# Step 1: Setting up the Project

# Import necessary libraries
import tkinter as tk

# Create the main application window
app = tk.Tk()
app.title("Task Manager")

# Run the main event loop
app.mainloop()

# Create a title label
title_label = tk.Label(app, text="To-Do List", font=("Helvetica", 16, "bold"))

# Pack the title label into the window
title_label.pack(pady=10)