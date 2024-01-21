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
                bg="black",
                activeforeground="#00FF00",
                activebackground="black")
Button.pack()

window.mainloop()