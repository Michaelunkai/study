import tkinter as tk
from tkinter import Label, Button

def exit_app():
    root.destroy()
    
# Create the main window
root = tk.Tk()
root.title('Task Manager')

# Add a welcome label
label = Label(root, text='Welcome!')
label.pack(pady=10)

# Add an exit button
exit_button = Button(root, text="Exit", command=exit_app)
exit_button.pack(pady=10)

# Run the Tkinter event loop
root.mainloop()