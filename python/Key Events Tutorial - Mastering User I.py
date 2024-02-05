#  Key Events Tutorial - Mastering User Input

# Import necessary modules
from tkinter import Tk, Label, mainloop

# Create the main window
window = Tk()
window.title("Key Events in Python")

# Create a label for displaying key events
label = Label(window, font=("Helvetica", 18))
label.pack()

# Define the function to handle key events
def handle_key_event(event):
    key_pressed = event.keysym
    label.config(text=f"You pressed: {key_pressed}")

# Bind the key event (any key) to the function
window.bind("<Key>", handle_key_event)

# Start the Tkinter main loop
mainloop()
