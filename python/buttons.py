# buttons

from tkinter import *

def click():
    print("You clicked my button!")

window = Tk()

Button = Button(window,
                text="This is misha's text",
                command=click)
Button.pack()

window.mainloop()