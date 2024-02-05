#   Canvas Graphics
# from tkinter import Tk, Canvas, mainloop

# window = Tk()
# window.title("Canvas Drawing Tutorial")

# # Create a canvas
# canvas = Canvas(window, height=500, width=500)
# canvas.pack()

# # Create a blue line
# canvas.create_line(0, 0, 500,500, fill="blue", width=5)

# # Create a red line
# canvas.create_line(0, 500, 500, 0, fill="red", width=5)

# # Create a purple rectangle
# canvas.create_rectangle(50, 50, 250, 250, fill="purple")

# # Create a yellow triangle
# canvas.create_polygon([250, 0, 500, 500, 0, 500], fill="yellow", outline="black", width=5)

# # Create a green pie slice
# canvas.create_arc(0, 0, 500, 500, fill="green", start=0, extent=180, style="pieslice", width=10)

# # Start the Tkinter main loop
# mainloop()
# _______________________________________________

#  part 2

# Import necessary modules
from tkinter import Tk, Canvas, mainloop

# Create the main window
window = Tk()
window.title("Canvas Drawing Tutorial - Part 2")

# Create a canvas
canvas = Canvas(window, height=500, width=500)
canvas.pack()


# Create a red hemisphere (top part of a Pokeball)
canvas.create_arc(0, 0, 500, 500, fill="red", extent=180, width=10)

# Create a white hemisphere (bottom part of a Pokeball)
canvas.create_arc(0, 0, 500, 500, fill="white", extent=180, start=180, width=10)

# Create a white oval in the center of the Pokeball
canvas.create_oval(190, 190, 310, 310, fill="white", width=10)

# Start the Tkinter main loop
mainloop()