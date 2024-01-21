# Python entry box

from tkinter import *
# entry widget = textbox that accepts a single line of user input

def submit():
    username = entry.get()
    print("Hello "+username)

window = Tk()

entry = Entry(window,
              font=("Ariel",50))
entry.pack(side=LEFT)

submit_button = Button(window,text="submit",command=submit)
submit_button.pack()

window.mainloop()