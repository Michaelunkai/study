import tkinter as tk
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
app.title("Scars Above GUI")

# Create a button for "scars_above"
button_scars_above = tk.Button(app, text="scars_above", command=lambda: start_thread("scarsabove"))
button_scars_above.pack(padx=10, pady=5)

# Create a button for "ten_dates"
button_ten_dates = tk.Button(app, text="ten_dates", command=lambda: start_thread("tendates"))
button_ten_dates.pack(padx=10, pady=5)

# Create a button for "deadspace"
button_deadspace = tk.Button(app, text="deadspace", command=lambda: start_thread("deadspace"))
button_deadspace.pack(padx=10, pady=5)

# Start the main event loop
app.mainloop()
