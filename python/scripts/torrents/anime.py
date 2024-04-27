import subprocess

# List of titles
titles = [
"Spy x Family",
"Zankyou no Terror",
"Zetsuen no Tempest",
"Akame ga Kill",
"Boku dake ga Inai Machi",
"Black Bullet",
"3x3 Eyes",
"Kabaneri Of The Iron Fortress",
"Hell's Paradise",
"Yasuke",
"Trinity Blood",
"Shiki",
"Delicious in Dungeon",
"Frieren: Beyond Journey's End",
"Mob Psycho 100",
"Neon Genesis Evangelion",
"Run with the Wind",
"Black Clover",
"Dr. Stone",
"Violet Evergarden",
"Haikyu!!",
"Ghost In The Shell: Stand Alone Complex",
"FLCL",
"Ping Pong the Animation",
"Kôkaku Kidôtai",
"Saiki Kusuo no Psi Nan",
"March Comes In like a Lion",
"Beck: Mongolian Chop Squad",
"Shôwa Genroku Rakugo Shinjû",
"Golden Boy",
"Bakuman",
]

# Iterate over titles and run the command
for title in titles:
    command = ["python", "-m", "1337x", title + " dual audio"]
    subprocess.run(command)

