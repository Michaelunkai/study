# Python GUI checkbox
from tkinter import *

window = Tk()

check_button = Checkbutton(window,
                           text="i Agree to something")
check_button.pack()
window.mainloop()