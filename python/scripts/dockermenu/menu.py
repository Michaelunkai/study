import tkinter as tk
from tkinter import ttk
import subprocess

def run_docker_command(image_name):
    # Replace or remove problematic characters, such as colon
    formatted_image_name = image_name.replace(":", "").lower()

    # Simplified Docker command without unnecessary elements
    docker_command = f'docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --name {formatted_image_name} michadockermisha/backup:{formatted_image_name} sh -c "apk add rsync && rsync -aP /home /c/games && mv /c/games/home /c/games/{formatted_image_name}"'

    # Run the command asynchronously
    subprocess.Popen(docker_command, shell=True)

# Create the main window
window = tk.Tk()
window.title("Docker Commands")
window.configure(bg="black")  # Set the background color of the window

# Set the overall font for the application
font_style = ("Helvetica", 10, "bold")

# Create styled buttons for various games with only the game names
style = ttk.Style()
style.configure("TButton", padding=2, relief="flat", foreground="black", background="red", font=font_style)

games = ["Vampire Bloodlines", "control", "Scars Above", "Road 96: Mile 0", "Pentiment", "persona4", "codblackops2", "codblackops3", "codww2", "codghosts", "codadvancedwarfare", "codinfinfinitewarfare", "codvanguard", "codmw", "moderwarfare2", "codmw3", "outerworld", "sniperelite2", "sniperelite3", "batmantts", "doom", "doomethernal", "pizzatower", "theradstringclub", "tellmewhy", "elpasoelswere" ,"rage2", "judgment", "tloh", "brothers", "madmax", "batmantew", "witcher3", "hyperlightdrifter", "metroexodus", "transistor", "thesurge2", "ftl", "returnal", "justcause3", "starwars", "mafia", "rimword", "masseffect2", "deathstranding", "ghostrunner", "ghostrunner2", "harvestmoon", "thexpanse", "tellingliies", "moonstoneisland", "residentevilvillage", "planetcoaster", "sleepingdogs", "gtaiv", "pseudoregalia", "thegreataceattorney", "goodbyevolcanohigh", "fallout4", "battlefieldbadcompany2", "battlefieldhardline", "battlefield1", "battlefieldv", "yakuza0", "yakuza3remasterd", "yakuza4", "yakuza5", "yakuza6thesongodlife", "yakuzalikeadragon", "vampiresurvivors", "highonlife", "thegodfather", "scarface", "unpacking", "scarletnexus", "haveanicedeath", "dredge", "cultofthelamb", "oblivion", "seaofstarts", "citieskylines2", "eldenrings", "kingdomofamalur", "wolfenstein2", "okamihd", "thesilentage", "divinityoriginalsin2", "dordogne", "tellmewhy", "theradstringclub", "systemshock", "subnautica", "riftapart", "grouned", "cosmicshake", "hotwheels", "alanwake", "alanwake2", "escapefromtarkov", "alyx", "plagtalerequirm", "sackboy", "remnant2", "sims4", "returntomonkeyisland", "beyond2souls", "eternalcylinder", "oddworldsoulstorm", "immortalsfenyxrising"]


# Arrange three buttons per horizontal line using the grid layout
row_num = 0
col_num = 0

for game in games:
    button = ttk.Button(window, text=game, command=lambda g=game.replace(" ", "").lower(): run_docker_command(g), style="TButton")
    button.grid(row=row_num, column=col_num, padx=1, pady=1)

    # Increment the column number, reset to 0 and increment the row number after every third button
    col_num += 1
    if col_num == 5:
        col_num = 0
        row_num += 1

# Start the GUI event loop
window.mainloop()
