# buttons

from tkinter import *

def click():
    print("You clicked my button!")

window = Tk()

Button = Button(window,
                text="This is misha's text",
                command=click,
                font=("Comic sans",30),
                fg="#00FF00",
                bg="black")
Button.pack()

window.mainloop()