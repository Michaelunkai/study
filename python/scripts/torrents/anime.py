import subprocess

# List of titles
titles = [
"Kôkaku Kidôtai",
"Saiki Kusuo no Psi Nan",
"March Comes In like a Lion",
"Beck: Mongolian Chop Squad",
"Shôwa Genroku Rakugo Shinjû",
"Golden Boy",
"Bakuman",
"monster",
"Rurouni Kenshin",
"Mushi-Shi",
"Yu Yu Hakusho: Ghost Files",
"Baccano!",
" Serial Experiments Lain ",
" Wolf's Rain",
" KILL la KILL",
" Darker Than Black"


]

# Iterate over titles and run the command
for title in titles:
    command = ["python", "-m", "1337x", title + " dual audio"]
    subprocess.run(command)

