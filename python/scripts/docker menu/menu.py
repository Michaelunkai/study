import tkinter as tk
from tkinter import ttk
import subprocess
import threading

def run_command(image_tag):
    # Define the Docker run command with the specified image tag
    docker_command = f"docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --name michadockermisha_container michadockermisha/backup:{image_tag} sh -c 'apk add rsync && rsync -aP /home/ /c/games/ && exit'"

    try:
        # Run the Docker command using subprocess
        subprocess.run(docker_command, shell=True)
    except Exception as e:
        # Handle any exceptions that may occur during command execution
        print(f"Error: {e}")

def start_thread(image_tag):
    # Create a thread for running the Docker command
    thread = threading.Thread(target=run_command, args=(image_tag,))
    thread.start()

# Create the main application window
app = tk.Tk()
app.title("Docker Image Runner")

# Create a styled Tkinter theme
style = ttk.Style()
style.theme_use("clam")

# Create a menu bar
menu_bar = tk.Menu(app)
app.config(menu=menu_bar)

# Create a "File" menu
file_menu = tk.Menu(menu_bar, tearoff=0)
menu_bar.add_cascade(label="File", menu=file_menu)
file_menu.add_command(label="Exit", command=app.destroy)

# Create a frame for the buttons
button_frame = ttk.Frame(app, padding="10")
button_frame.grid(column=0, row=0, sticky=(tk.W, tk.E, tk.N, tk.S))

# Create buttons with a modern style
button_scars_above = ttk.Button(button_frame, text="Scars Above", command=lambda: start_thread("scarsabove"))
button_scars_above.grid(column=0, row=0, padx=5, pady=5, sticky=tk.W)

button_ten_dates = ttk.Button(button_frame, text="Ten Dates", command=lambda: start_thread("tendates"))
button_ten_dates.grid(column=1, row=0, padx=5, pady=5, sticky=tk.W)

button_deadspace = ttk.Button(button_frame, text="Dead Space", command=lambda: start_thread("deadspace"))
button_deadspace.grid(column=2, row=0, padx=5, pady=5, sticky=tk.W)

button_road96mile0 = ttk.Button(button_frame, text="Road96 Mile0", command=lambda: start_thread("road96mile0"))
button_road96mile0.grid(column=0, row=1, padx=5, pady=5, sticky=tk.W)

button_pentiment = ttk.Button(button_frame, text="Pentiment", command=lambda: start_thread("pentiment"))
button_pentiment.grid(column=1, row=1, padx=5, pady=5, sticky=tk.W)

button_trepang2 = ttk.Button(button_frame, text="Trepang2", command=lambda: start_thread("trepang2"))
button_trepang2.grid(column=2, row=1, padx=5, pady=5, sticky=tk.W)

button_nomoreheroes3 = ttk.Button(button_frame, text="No More Heroes 3", command=lambda: start_thread("nomoreheroes3"))
button_nomoreheroes3.grid(column=0, row=2, padx=5, pady=5, sticky=tk.W)

# Start the main event loop
app.mainloop()
