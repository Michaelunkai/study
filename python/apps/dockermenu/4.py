import sys
import os
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QHBoxLayout, QVBoxLayout, QScrollArea, QLineEdit, QGridLayout, QDesktopWidget
from PyQt5.QtGui import QColor
from PyQt5.QtCore import Qt
import subprocess

class DockerApp(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Docker Commands")

        # Set the window size to *** of the screen
        desktop_geometry = QDesktopWidget().screenGeometry()
        width = int(desktop_geometry.width() * 19 / 20)
        height = int(desktop_geometry.height() * 19 / 20)
        self.setGeometry(0, 0, width, height)

        self.setStyleSheet("background-color: black; font: 10pt bold; color: black;")

        self.init_ui()

    def init_ui(self):
        main_layout = QVBoxLayout(self)

        # Create a horizontal layout for the buttons
        button_layout = QHBoxLayout()

        # Add interactive button
        self.interactive_button = QPushButton("Interactive", self)
        self.interactive_button.setStyleSheet("font-size: 14pt; background-color: red; color: black;")
        self.interactive_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.interactive_button)

        # Add mouse button
        self.mouse_button = QPushButton("mouse", self)
        self.mouse_button.setStyleSheet("font-size: 14pt; background-color: green; color: black;")
        self.mouse_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.mouse_button)

        # Add platform button
        self.platform_button = QPushButton("platofrm", self)
        self.platform_button.setStyleSheet("font-size: 14pt; background-color: green; color: black;")
        self.platform_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.platform_button)

        # Add shooter button
        self.shooter_button = QPushButton("Shooter", self)
        self.shooter_button.setStyleSheet("font-size: 14pt; background-color: blue; color: black;")
        self.shooter_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.shooter_button)

        # Add chill button
        self.chill_button = QPushButton("Chill", self)
        self.chill_button.setStyleSheet("font-size: 14pt; background-color: orange; color: black;")
        self.chill_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.chill_button)

        # Add action button
        self.action_button = QPushButton("action", self)
        self.action_button.setStyleSheet("font-size: 14pt; background-color: purple; color: black;")
        self.action_button.clicked.connect(self.update_games)
        button_layout.addWidget(self.action_button)

        # Add the button layout to the main layout
        main_layout.addLayout(button_layout)

        # Add search box
        self.search_box = QLineEdit(self)
        self.search_box.setPlaceholderText("Search...")
        self.search_box.setStyleSheet("padding: 10px; font-size: 20px; background-color: white;")
        self.search_box.textChanged.connect(self.filter_buttons)
        main_layout.addWidget(self.search_box, alignment=Qt.AlignRight)

        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_widget = QWidget()
        scroll_area.setWidget(scroll_widget)

        layout = QVBoxLayout(scroll_widget)

        self.buttons = []

        self.all_games = [
    "Vampire Bloodlines", "control", "sniperelite3",
    "batmantts", "doom", "pizzatower", "theradstringclub", "elpasoelswere", "tloh", "brothers", "witcher3", "metroexodus", "transistor", "ftl", "returnal", "justcause3", "masseffect2", "harvestmoon", "thexpanse", "moonstoneisland", "planetcoaster",
    "sleepingdogs", "gtviv", "goodbyevolcanohigh", "fallout4", "vampiresurvivors", "highonlife", "oblivion", "seaofstars", "citieskylines2", "kingdomofamalur", "wolfenstein2", "okamihd", "thesilentage", "divinityoriginalsin2", "theradstringclub", "cosmicshake", "plagtalerequirm", "sackboy", "remnant2", "sims4", "returntomonkeyisland", "beyond2soul", "oddworldsoulstorm", "slaytheprincess", "prisonsimulator", "videoverse", "singularity", "farcryprimal", "sherlockholmeschapterone", "sherlockholmestheawakened", "sherlockholmescrimesandpunishments", "theascent",
   "spongbobbfbbr", "erica", "ancestorshumankind", "bumsimulator", "cafeownersimulation", "forgottencity", "hackersimulator", "hellbladesenuasacrifice", "lifeistrangeremastered", "eiyudenchroniclerising",
    "darksidersgenesis", "skaterxl", "saintsrow3", "pacmanworldrepac", "inscryption", "brewmasterbeersimulator", "cheflifesimulator", "detroitbecomehuman", "seriousam4", "houseflipper", "enterthegungeon", "blasphemous2", "deadisland2", "lostinplay", "blacktail", "godofwar", "sunsetoverdrive",    "killerfrequency", "deathmustdie", "punchclub2fastforward", "deusexhuman", "sludgelife2", "blackskylands", "notforbroadcast", "deeprockgalactic", "assassinscreedvalhalla", "frostpunk", "torchlight2", "nobodysavedtheworld", "oxenfree2", "spiritfarer", "furi", "metalgearsolidmaster", "highlandsong", "venba", "covergence", "bombrushcyberfunk", "fatesamurairemnant", "tornaway", "tailsthebackbonepreludes", "wanderingsword", "showgunners", "trinityfusion", "evilwest", "themageseeker", "enderliles", "nocturnal", "octopathtraveler2", "devilmaycry4", "bramble", "neotheworldendswithyou", "thegunk", "steelrising", "firemblemwarriors3hopes", "strangerofparadaise", "deadspace", "lordsofthefallen", "vampyr", "sonicsuperstarts", "seasonalettertothefuture", "supermariowonder", "trine2", "turok", "dredge", "tekken8", "tchia", "doubledragongaiden", "cultofthelamb", "cosmicwheelsisterhood", "talesofvesperia", "torchlight2", "xenobladechronicles", "okamihd", "trianglestrategy", "tenseiv", "braverlydefault2", "megamanbattlenetwork", "livealive", "advancedwars" "riskofrain", "driversanfrancisco", "signalis", "resistance2", "tinykin", "thedarkness", "thepunisher", "legendoftianding", "nier", "soulstice", "bugsnax", "zeldalinktothepast", "powerwashsimulator", "artfulescape", "pcbuildingsimulator", "circuselectrique", "desperados3" , "americanarcedia", "risen2", "sniperghostwarrior2", "midnightfightexpress", "readyornot", "theinvincible", "lovetooeasily", "fistforgedinshadow", "Immortalsofaveum", "cookingsimulator", "aspacefortheunbound", "alphaprotocol", "miandthedragonprincess", "lateshift", "valkyriachronicles4", "darkpicturesanthology", "asduskfalls", "thebunker", "cobletcore", "firstdatelatetodate", "thecomplex", "sonicolors", "enslaved", "superseducer2", "islets", "fivedates", "marvel", "sanabi", "bayonetta2", "sunhaven", "fuga", "scarsabove", "witchfire", "exithegungeon", "weirdwest", "supermariorpg", "ninokuni", "firemblemengage", "firemblem3houses", "chainedechoes", "armoredcore6firesofrubicon","greedfall", "eiyudenchromicle", "crisiscorefinalfantasy7", "talesofberseria", "ffx", "twinmirrors", "binarydomain", "anothercrabstreasure","yakuxa3","yakuza4", "wildlands",  "banishers", "repellafella", "childrenofthesun",
        ]


        self.displayed_games = self.all_games  # Initially, all games are displayed

        grid_layout = QGridLayout()
        row, col = 0, 0
        for game in self.displayed_games:
            button = QPushButton(game, self)
            button.clicked.connect(lambda checked, g=game.replace(" ", "").lower(): self.run_docker_command(g))

            # Change grey color to another color (black)
            button.setStyleSheet("padding: 3px; border: none; color: black; background-color: red;")

            grid_layout.addWidget(button, row, col)
            col += 1
            if col == 4:
                col = 0
                row += 1

            self.buttons.append(button)

        layout.addLayout(grid_layout)
        scroll_area.setVerticalScrollBarPolicy(0x1)
        main_layout.addWidget(scroll_area)

    def run_docker_command(self, image_name):
        formatted_image_name = image_name.replace(":", "").lower()
        docker_command = f'docker run -v /mnt/c/games/{formatted_image_name}:/c/games/{formatted_image_name} -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --name {formatted_image_name} michadockermisha/backup:{formatted_image_name} sh -c "apk add rsync && rsync -aP /home /c/games && mv /c/games/home /c/games/{formatted_image_name}"'
        subprocess.Popen(docker_command, shell=True)

    def filter_buttons(self, text):
        for button in self.buttons:
            button.setVisible(text.lower() in button.text().lower())

    def update_games(self):
        sender_button = self.sender()
        if sender_button == self.interactive_button:
            specified_titles = ["batmantts", "erica","thexpanse", "beyond2souls", "detroitbecomehuman", "Oxenfree2", "forgottencity", "sherlockholmeschapterone", "masseffect2", "slaytheprincess", "tailsthebackbonepreludes", "lifeistrangeremastered", "goodbyevolcanohigh", "tornaway", "sherlockholmescrimesandpunishments", "lovetooeasily", "lateshift", "miandthedragonprincess", "darkpicturesanthology", "asduskfalls", "thebunker", "firstdatelatetodate", "thecomplex", "superseducer2", "fivedates", "twinmirrors",
  ]
        elif sender_button == self.mouse_button:
            specified_titles = ["hackersimulator", "thecaseofthegoldenidol", "sludgelife2", "videoverse", "returnofthemonkeyisland", "divinityoriginalsin2", "cafeownersimulation", "notforbroadcast", "returntomonkeyisland", ]
        elif sender_button == self.shooter_button:
            specified_titles = ["doom", "sniperelite3", "deusexhuman", "elpasoelswhere", "theascent", "deeprockgalactic", "singularity", "evilwest", "turok", "resistance2", "thedarkness", "sniperghostwarrior2", "readyornot", "vanquish" "scarsabove", "witchfire", "binarydomain", "wildlands" ]
        elif sender_button == self.chill_button:
            specified_titles = ["okamihd", "lostinplay", "pizzatower","octopathtraveler2","skaterxl","pacmanworldrepac","harvestmoon", "tloh", "planetcoaster", "brothers", "ftl", "seasonalettertothefuture", "enterthegungeon", "seaofstars", "thesilentage", "bumsimulator", "moonstoneisland", "bumsimulator", "showgunners", "spongbobbfbbr", "cheflifesimulator", "sonicsuperstarts", "sims4", "prisonsimulator", "inscryption", "eiyudenchroniclerising", "brewmasterbeersimulator", "nobodysavedtheworld", "vampiresurvivors", "bramble", "punchclub2fastforward","blacktail", "highlandsong", "tailsthebackbonepreludes", "spiritfarer", "cafeownersimulation", "frostpunk", "citieskylines2", "blackskylands", "deathmustdie", "houseflipper", "killerfrequency", "venba", "dredge", "tchia", "doubledragongaiden", "cultofthelamb", "cosmicwheelsisterhood", "okamihd", "trianglestrategy", "braverlydefault2", "livealive", "advancedwars", "signalis", "tinykin", "bugsnax", "powerwashsimulator", "artfulescape", "pcbuildingsimulator", "circuselectrique", "aspacefortheunbound", "americanarcedia", "midnightfightexpress", "theinvincible", "cookingsimulator", "aspacefortheunbound", "cobletcore", "tetriseffect", "sunhaven", "fuga", "chainedechoes", "eiyudenchromicle", "anothercrabstreasure" "repellafella" ]
        elif sender_button == self.action_button:
            specified_titles = ["saintsrow3", "farcryprimal","devilmaycry4", "godofwar", "deadspace", "fatesamurairemnant", "sunsetoverdrive", "doom", "metroexodus", "sleepingdogs", "returnal", "kingdomofamalur", "wolfenstein2", "deadspace", "gtviv", "vampyr", "vampirebloodlines", "assassinscreedvalhalla", "neotheworldendswithyou", "thegunk", "darksidersgenesis", "steelrising", "theascent", "highonlife", "oblibion", "plagtalerequirm", "deadisland2", "metalgearsolidmaster", "transistor", "justcause3", "wanderingsword", "mountandblade2bannerlord", "ancestorshumankind", "seriousam4", "armoredcore6firesofrubicon", "furi", "witcher3", "fallout4", "oblivion", "bombrushcyberfunk", "Vampire Bloodlines", "firemblemwarriors3hopes", "themageseeker", "control", "hellbladesenuasacrifice", "turok", "tekken8", "torchlight2", "talesofvesperia", "xenobladechronicles", "tenseiv", "riskofrain", "driversanfrancisco", "thedarkness", "thepunisher", "nier", "soulstice", "desperados3", "Immortalsofaveum", "alphaprotocol", "valkyriachronicles4", "enslaved", "marvel", "bayonetta2", "weirdwest", "ninokuni", "firemblemengage", "firemblem3houses", "armoredcore6firesofrubicon", "greedfall", "crisiscorefinalfantasy7", "talesofberseria", "ffx", "binarydomain", "yakuxa3","yakuza4", "wildlands", "banishers", "childrenofthesun" ]
        elif sender_button == self.platform_button:
            specified_titles = ["sackboy", "trine2", "supermariowonder", "cosmicshake", "kazeandthewildmasks", "oddworldsoulstorm", "enderliles", "covergence", "spongbobbfbbr", "fistforgedinshadowtorch", "sonicsuperstarts", "blasphemous2", "nocturnal", "trinityfusion", "talesofvesperia", "megamanbattlenetwork", "tinykin", "legendoftianding", "zeldalinktothepast", "artfulescape", "risen2", "fistforgedinshadow", "sonicolors", "islets", "sanabi", "exithegungeon", "supermariorpg" ]

        self.displayed_games = [game for game in self.all_games if game.lower().replace(" ", "") in specified_titles]

        for button in self.buttons:
            button.setVisible(button.text().lower().replace(" ", "") in specified_titles)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    docker_app = DockerApp()
    docker_app.show()
    sys.exit(app.exec_())
