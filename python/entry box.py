# Python entry box

from tkinter import *
# entry widget = textbox that accepts a single line of user input

window = Tk()

entry = Entry(window,
              font=("Ariel",50))
entry.pack()

window.mainloop()