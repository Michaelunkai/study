# lables

# from tkinter import * 

# # label = an area widget that holds text and/or an image within a windows

# window = Tk()

# label = Label(window, text="Hello World")
# label.pack()

# window.mainloop()
# _______________________________________________-
# from tkinter import * 

# window = Tk()

# label = Label(window, text="Hello World")
# label.place()

# window.mainloop()
# ______________________________________________-
# example:
# from tkinter import * 

# window = Tk()

# label = Label(window, text="Hello World")
# label.place(x=0,y=0)

# window.mainloop()
# _______________________________________________

# from tkinter import * 

# window = Tk()

# label = Label(window, text="Hello World",font=('Ariel',40,'bold'))
# label.pack()

# window.mainloop()
# __________________________________________________-
from tkinter import * 

window = Tk()

label = Label(window, text="Hello World",font=('Ariel',40,'bold'),fg='green')
label.pack()

window.mainloop()