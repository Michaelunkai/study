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

# Step 3: Creating Entry Widget for Tasks
# Create an entry widget for tasks
task_entry = tk.Entry(app, width=40, font=('Helvetica', 12))

# Pack the task entry widget into the window
task_entry.pack(pady=10)