alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias l='ls -CF'
alias dps='docker ps --size'
alias dpsa='docker ps -a --size'
alias dim='docker images'
alias built='docker build -t'
alias drun='docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --name'
alias drc='docker rm -f'
alias dri='docker rmi -f'
alias dkill='docker stop $(docker ps -aq) || true && docker rm $(docker ps -aq) || true && ( [ "$(docker ps -q)" ] || docker rmi $(docker images -q) || true ) && ( [ "$(docker images -q)" ] || docker system prune -a --volumes --force ) && docker network prune --force || true'
alias conip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "
alias killc='docker stop $(docker ps -q)
docker rm $(docker ps -aq)'
alias dcu='docker-compose up -d'
alias backupwsl='cd /mnt/f/backup/linux/wsl && built michadockermisha/backup:wsl . && docker push michadockermisha/backup:wsl'
alias backupapps='cd /mnt/f/backup/windowsapps && built michadockermisha/backup:windowsapps . && docker push michadockermisha/backup:windowsapps'
alias backitup='backupapps && gg && backupwsl'
alias restoreapps='drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup/ && mv home windowsapps && exit" '
alias restorelinux='cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/linux && cd /c/backup/linux && mv home wsl && exit" '
alias restoreasus='cdbackup && drun asus michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup && mv home asus && exit" '
alias restorebackup='c && mkdir backup && drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup/ && mv home windowsapps && exit" && cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/linux && cd /c/backup/linux && mv home wsl && exit" '
alias brc='gedit ~/.bashrc'
alias brc1='source ~/.bashrc && source /root/.bashrc'
alias updates='sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y'
alias update='apt update'
alias cpbash='sudo cp /root/.bashrc /home/kali/.bashrc'
alias gatway="netstat -rn | grep '^0.0.0.0'"
alias ssk='ssh-keygen -t rsa -b 2048 && ssh-copy-id'
alias sshprox="ssh root@192.168.1.222"
alias sshubuntu="ssh ubuntu@192.168.1.193"
alias c='cd /mnt/c/'
alias stu='cd /mnt/f/study'
alias cdwsl='cd /mnt/f/backup/linux/wsl'
alias games='cd /mnt/c/games'
alias pfiles="c && cd 'Program Files'"
alias wapps='pfiles && cd WindowsApps'
alias cdbackup="c && cd backup"
alias cdapps="cd /mnt/f/backup/windowsapps"
alias scloud='cd /mnt/f/study/cloud'
alias slinux='cd /mnt/f/study/linux'
alias sssh='cd /mnt/f/study/ssh'
alias smalware='cd /mnt/f/study/malware'
alias spython='cd /mnt/f/study/Dev_Toolchain/programming/python'
alias sbash='cd /mnt/f/study/shells/bash'
alias sexams='cd /mnt/f/study/exams'
alias swin='cd /mnt/f/study/windows'
alias sprox="cd /mnt/f/study/virtualmachines/proxmox"
alias sserver="cd /mnt/f/study/Platforms/windows/server"
alias cda='cd /mnt/f/study/ansible/etc/ansible'
alias play='cd /etc/ansible/playbooks'
alias backupansible='cp -r /etc/ansible /mnt/f/study/ansible/etc'
alias ansiblereboot='ansible docker -a "reboot"'
alias ansibleping='ansible docker -m ping'
alias ansibleupdate=' ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/update.yml'
alias gadd=' git add . && git commit -m "commit" && git push -u origin main'
alias fkali='echo "wsl --unregister kali-linux; wsl --import kali-linux C:\wsl2 C:\backup\linux\wsl\kalifull.tar"'
alias backupw='echo "wsl --export kali-linux C:\backup\linux\kalifull.tar; wsl --export ubuntu C:\backup\linux\ubuntu.tar"'

alias wupdates='cat "/mnt/f/study//shells/powershell/scripts/windowsupdates.ps1" && cp "/mnt/f/study/shells/powershell/scripts/windowsupdates.ps1 /mnt/c/users/micha/updates.ps1"'
alias getpycharm=' wget https://download.jetbrains.com/python/pycharm-community-2021.2.3.tar.gz && tar -xzf pycharm-community-2021.2.3.tar.gz && sudo mv pycharm-community-2021.2.3 /opt/ && cd /opt/pycharm-community-2021.2.3/bin && ./pycharm.sh'
alias getext='apt install tesseract-ocr -y'
alias text=tesseract
alias basicinstall='sudo apt install -y -qq wireless-tools kali-win-kex && net-tools gedit kali-desktop-xfce curl wget jq libgtk-3-dev libcurl4-openssl-dev -y'
export DOCKER_BUILDKIT=1
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
alias x11='export DISPLAY=:0'
alias reset='echo "systemreset.exe" '
alias conf=' nano /etc/wsl.conf'
alias conf2='nano /mnt/c/Users/micha/.wslconfig'
alias cleanwsl=' cat "/mnt/f/study/shells/powershell/scripts/optimizewsl.ps1" && cp /mnt/f/study/shells/powershell/scripts/optimizewsl.ps1 /mnt/c/Users/micha/ccwsl.ps1'
alias poweroff='shutdown.exe /s /t 0'
alias reboot='shutdown.exe /r /t 0'
alias dockhub='gc https://hub.docker.com/repository/docker/michadockermisha/backup/tags?page=1&ordering=last_updated'
alias gpt='ff https://chat.openai.com/'
alias pocket='ff https://getpocket.com/saves?src=navbar'
alias 1337='ff https://1337x.to/home/'
alias gamespot='ff https://www.gamespot.com/'
alias awsweb="gc https://us-east-1.console.aws.amazon.com/console/home?region=us-east-1#"
export PATH=$PATH:/snap/bin
export DISPLAY=:0
alias qcow='qemu-img convert -f vmdk -O qcow2'
alias dfs='df -h /mnt/c'
alias pyc=' bash /opt/pycharm-community-2021.2.3/bin/pycharm.sh'
alias biggest=' echo "du -h --max-depth=1 -a | sort -rh" '
alias wslg='cd /mnt/wslg && biggest'
alias psw='powershell.exe'
alias mp3='docker run --rm -v $HOME/Downloads:/root/Downloads dizcza/youtube-mp3 $1'
alias mp4='docker run --rm -i -e PGID=$(id -g) -e PUID=$(id -u) -v "$(pwd)":/workdir:rw mikenye/youtube-dl'
alias txt='tesseract'
alias rip="ff 'http://192.168.1.1'"
alias getplex="updates && echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list && curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add - && updates && cc && sudo apt install plexmediaserver -y && sudo systemctl enable plexmediaserver && sudo systemctl start plexmediaserver && ff http://87.70.162.212:32400/web/"
alias getff="apt install firefox-esr -y"
alias defender='cmd.exe /c C:/backup/windowsapps/install/afterformat/windows-defender-remover-main/windows-defender-remover-main/Script_Run.bat'
alias act="cd /mnt/f/backup/windowsapps/install/Microsoft-Activation-Scripts-master/mas/All-In-One-Version && cmd MAS_AIO.cmd"
alias python='python3'
alias aliases="gedit /mnt/f/backup/linux/wsl/alias.txt"
alias cpalias="cp /mnt/f/backup/linux/wsl/alias.txt /root/.bashrc && cp /mnt/f/backup/linux/wsl/alias.txt ~/.bashrc"
alias cmd='cmd.exe /c'
complete -C '/mnt/c/Users/micha/mc' mc
alias savegames="cd /mnt/f/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c 'apk add rsync && rsync -aP /home/* /c/backup/gamesaves && exit' && built michadockermisha/backup:gamesaves . && docker push michadockermisha/backup:gamesaves && rm -rf ./*"
alias sshct="ssh root@192.168.1.100"
alias savedg="cd /mnt/f/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c 'apk add rsync && rsync -aP /home/* /c/backup/gamesaves && exit'"
alias sjavascript="cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript"
alias sfront="cd /mnt/f/study/Dev_Toolchain/programming/frontend"
alias scomptia="cd /mnt/f/study/exams/compTIA"
alias allips="nmap -sn 192.168.1.1/24"
alias kstart="minikube start --driver=docker --force"
alias sshwindows="ssh Administrator@192.168.1.230"
alias fixwin="echo 'choco upgrade all -y --force; Repair-WindowsImage -Online -ScanHealth; Repair-WindowsImage -Online -RestoreHealth; sfc /scannow ; DISM.exe /Online /Cleanup-Image /CheckHealth ; DISM.exe /Online /Cleanup-Image /RestoreHealth ; dism /online /cleanup-image /startcomponentcleanup; chkdsk /f /r; net start wuauserv; ./updates.ps1 '"
alias fubuntu="echo 'wsl --unregister ubuntu; wsl --import ubuntu C:\wsl2\ubuntu C:\backup\linux\wsl\ubuntu.tar'"
alias backupubu="echo 'wsl --export ubuntu C:\backup\linux\ubuntu.tar'"
alias ssecurity="cd /mnt/f/study/security"
alias fall="echo 'wsl --unregister kali-linux; wsl --import kali-linux C:\wsl2 C:\backup\linux\wsl\kalifull.tar; wsl --unregister ubuntu; wsl --import ubuntu C:\wsl2\ubuntu\ C:\backup\linux\wsl\ubuntu.tar'"
alias dcode='docker run -v /mnt/c/:/c/ -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --rm --name my_container michadockermisha/backup:python bash -c "echo 'y' | code --no-sandbox --user-data-dir=~/vscode-data && bash"'
alias drmariadb='docker run -v /mnt/c/:/c/ -it -d --name mariadb -e MYSQL_ROOT_PASSWORD=123456 -p 3307:3307 mariadb:latest && sleep 30 && docker exec -it mariadb mariadb -u root -p'
alias dei="docker exec -it"
alias playlist="py /mnt/c/users/micha/videos/a.py"
alias build="cp /mnt/f/study/containers/docker/dockerfiles/buildimage ./Dockerfile && nano Dockerfile"
alias build2='cp /mnt/f/study/containers/docker/dockerfiles/buildthispath ./Dockerfile && nano Dockerfile'
alias compile="echo ' & \"C:\Users\micha\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\LocalCache\local-packages\Python312\Scripts\pyinstaller\" --onefile --icon=a.ico --windowed --name=WinOptimize a.py ' "
alias trans="python /mnt/f/study/Dev_Toolchain/programming//python/apps/transcripts/youtubeVideoToText/b.py"
alias sdatascience="cd /mnt/f/study/datascience"
alias salgo=" cd /mnt/f/study/datascience/algorithms"
alias sdatasets="cd /mnt/f/study/datascience/datasets"
alias sleetcode="cd /mnt/f/study/exams/leetcode"
alias audioh="epub2tts a.txt --engine edge --language he --speaker he-IL-AvriNeural --audioformat wav"
alias upgradeit="apt --only-upgrade install"
alias getollama="update && cd && curl -fsSL https://ollama.com/install.sh | sh && sleep 5 && ollama run llama3 && docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main && gc http://localhost:8080"
alias sources="cd /etc/apt/sources.list.d"
alias qna="cd /mnt/f/study/exams/QNA"
alias epub2text="apt install calibre -y && ebook-convert a.epub a.txt"
alias sprog="cd /mnt/f/study/programming"
alias setups="cd /mnt/f/study/setups"
alias saws="cd /mnt/f/study/cloud/aws/awscli"
alias pdata="cd /mnt/f/study/Dev_Toolchain/programming/python/datascience"
alias smicro="cd /mnt/f/study/microservices"
alias getprom="sudo apt update && sudo apt install prometheus -y && sudo systemctl start prometheus"
alias sone="cd /mnt/f/study/Devops/automation/oneliners"
alias getdocker='
sudo apt-get update &&
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release acl &&
sudo mkdir -p /etc/apt/keyrings &&
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes &&
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bullseye stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update -y &&
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &&
sudo systemctl start docker &&
sudo systemctl enable docker &&
sudo groupadd docker 2>/dev/null || true &&
sudo usermod -aG docker $USER &&
sudo setfacl -m user:$USER:rw /var/run/docker.sock &&
export DOCKER_HOST=unix:///var/run/docker.sock &&
if [ ! -f ~/.docker/config.json ]; then
  mkdir -p ~/.docker &&
  echo "{\"credsStore\": \"desktop\", \"stackOrchestrator\": \"swarm\", \"detachKeys\": \"ctrl-p,ctrl-q\"}" > ~/.docker/config.json
fi &&
sudo rm -f /usr/local/bin/docker-compose &&
sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose &&
echo "Docker and Docker Compose installation complete. Please log out and log back in for the group changes to take effect." &&
echo "Docker version: $(docker --version)" &&
echo "Docker Compose version: $(docker-compose --version)"
'
alias sapps="cd /mnt/f/study/Dev_Toolchain/programming/python/apps"
alias sssl="cd /mnt/f/study/security/SSL"
alias svb="cd /mnt/f/study/virtualmachines/VirtualBox"
alias startkube="minikube start --driver=docker --force"
alias getapache="apt install apache2 -y && sudo systemctl start apache2"
alias fixupdates="sudo apt update --fix-missing && sudo apt upgrade --fix-missing"
alias sgcp="cd /mnt/f/study/cloud/GCP/cli"
alias getwordpress='sudo apt update && sudo apt install -y mariadb-server wget && wget -c https://wordpress.org/latest.tar.gz && tar -xvzf latest.tar.gz && sudo mv wordpress /var/www/html/ && sudo chown -R www-data:www-data /var/www/html/wordpress && sudo chmod -R 755 /var/www/html/wordpress && sudo mariadb --execute="ALTER USER '\''root'\''@'\''localhost'\'' IDENTIFIED BY '\''123456'\''; FLUSH PRIVILEGES;" && sudo mariadb --user=root --password=123456 --execute="DELETE FROM mysql.user WHERE User=''; DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE Db='\''test'\'' OR Db='\''test\\_%'\''; FLUSH PRIVILEGES;" && sudo mariadb --user=root --password=123456 --execute="CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci; CREATE USER '\''wpuser'\''@'\''localhost'\'' IDENTIFIED BY '\''123456'\''; GRANT ALL PRIVILEGES ON wordpress.* TO '\''wpuser'\''@'\''localhost'\''; FLUSH PRIVILEGES;" && sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf && sudo sed -i '\''s|DocumentRoot /var/www/html|DocumentRoot /var/www/html/wordpress|'\'' /etc/apache2/sites-available/wordpress.conf && sudo a2ensite wordpress.conf && sudo a2enmod rewrite && sudo systemctl restart apache2 && sudo systemctl enable apache2 && echo -e "<?php\nphpinfo();\n?>" | sudo tee /var/www/html/wordpress/info.php > /dev/null && sudo systemctl restart apache2 && xdg-open "http://localhost/wordpress"'
alias getjenkins='docker run -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home --name jenkins jenkins/jenkins:lts && sleep 30 && docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword && echo "Access Jenkins at: http://$(hostname -I | awk '\''{print $1}'\''):8080" && gc http://172.27.127.95:8080'
alias getera='wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt update && sudo apt install terraform -y'
alias getkafka="sudo apt-get update && sudo apt-get install -y openjdk-11-jre && sudo docker pull confluentinc/cp-kafka:7.3.2 && sudo docker pull confluentinc/cp-zookeeper:7.3.2 && sudo docker network create kafka-net && sudo docker run -d --net=kafka-net --name=zookeeper -e ZOOKEEPER_CLIENT_PORT=2181 confluentinc/cp-zookeeper:7.3.2 && sudo docker run -d --net=kafka-net --name=kafka -p 7000:7000 -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:7000 -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 confluentinc/cp-kafka:7.3.2 "
alias fixkube="sudo sysctl fs.protected_regular=0 && sudo minikube delete && sudo chown -R $USER:$USER /tmp/juju* && minikube start --driver=docker --force"
alias samba='cd /srv/samba/shared'
alias rmsamba='rm -rf /srv/samba/shared/*'
alias sud="sudo su"
alias csources="rm -rf /etc/apt/sources.list.d/*"
alias remove="sudo apt autoremove -y"
alias snet="cd /mnt/f/study/networking"
alias shost='cd /mnt/f/study/hosting'
alias swrt="cd /mnt/f/study/networking/openWRT"
alias svm='cd /mnt/f/study/virtualmachines'
alias getgraf='sudo apt-get install -y apt-transport-https software-properties-common wget && sudo mkdir -p /etc/apt/keyrings/ && wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null && echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list && sudo apt-get update && sudo apt-get install -y grafana && sudo systemctl daemon-reload && sudo systemctl start grafana-server && gc http://localhost:3000/login'
alias rmsources="rm -rf /etc/apt/sources.list.d/*"
alias sapis="cd /mnt/f/study/Dev_Toolchain/programming/APIs"
alias rmf="rm -rf"
alias gitpull="git pull origin main"
alias gitadd='psw -Command "gitadd" '
alias gitpush='psw -Command "gitpush"'
alias stud="cd /home/ubuntu/study"
alias sauto="cd /mnt/f/study/Devops/automation"
alias gitlock="stu && rm .git/index.lock"
alias getgcloud='pip install pyqt5 && sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl sudo && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && sudo apt-get update -y && sudo apt-get install -y google-cloud-cli && gcloud init'
alias getkuma="sudo docker run -d --restart always -p 3001:3001 -v /var/kuma:/app/data louislam/uptime-kuma:1 && gc http://localhost:3001"
alias rmdata="apt purge mariadb-server mariadb-client -y && remove"
alias react="docker run -it --rm -v $(pwd):/app -w /app -p 3000:3000 node:latest /bin/bash"
alias sdocker="cd /mnt/f/study/containers/docker/guides"
alias sjs="cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript"
alias getgitea='cd && sudo apt-get update && sudo apt-get install -y mariadb-server && sudo systemctl start mariadb && sudo mysql -e "CREATE DATABASE gitea; GRANT ALL PRIVILEGES ON gitea.* TO '\''gitea'\''@'\''localhost'\'' IDENTIFIED BY '\''123456'\''; FLUSH PRIVILEGES;" && sudo apt-get install -y bash-completion wget curl git sqlite3 && sudo adduser --system --shell /bin/bash --gecos '\''Git Version Control'\'' --group --disabled-password --home /home/git git && sudo wget -O /tmp/gitea https://dl.gitea.io/gitea/1.20/gitea-1.20-linux-amd64 && sudo mv /tmp/gitea /usr/local/bin/gitea && sudo chmod +x /usr/local/bin/gitea && sudo mkdir -p /var/lib/gitea/{custom,data,log} && sudo chown -R git:git /var/lib/gitea/ && sudo chmod -R 750 /var/lib/gitea/ && sudo mkdir /etc/gitea && sudo chown root:git /etc/gitea && sudo chmod 770 /etc/gitea && sudo -u git mkdir -p /var/lib/gitea/data && mkdir /usr/local/bin/data && chmod 777 /usr/local/bin/data && mkdir /usr/local/bin/log && chmod 777 /usr/local/bin/log && mkdir /usr/local/bin/custom && chmod 777 /usr/local/bin/custom && sudo -u git /usr/local/bin/gitea web'
alias iac="cd /mnt/f/study/Infrastructure_as_Code"
alias ytlater="gc https://www.youtube.com/playlist?list=PLY8Bm7EI5jJXioeO2CHovbC4ei1sYP3Kw"
alias smon='cd /mnt/f/study/monitoring'
alias trouble="cd /mnt/f/study/troubleshooting"
alias sback="cd /mnt/f/study/backup"
alias cpt='cp -r "$(ls -t | head -n 1)" /mnt/f/study/troubleshooting'
alias cpdot='cp -r "$(ls -t | head -n 1)" /mnt/f/study/Dev_Toolchain/programming/.net'
alias cphp='cp -r "$(ls -t | head -n 1)" /mnt/f/study/Dev_Toolchain/programming/php'
alias cpfront='cp -r "$(ls -t | head -n 1)" /mnt/f/study/Dev_Toolchain/programming/frontend'
alias cpjs='cp -r "$(ls -t | head -n 1)" /mnt/f/study/Dev_Toolchain/programming/frontend/javascript'
alias pubip="curl ifconfig.me"
function gcl() {
cmd.exe /c start chrome http://localhost:$1
}
alias amount="(find . -type f -print) | wc -l"
alias rmp="rmf /mnt/c/Users/micha/Pictures/*"
alias cpn='cp -r "$(ls -t | head -n 1)" /mnt/f/study/networking'
alias cpm='cp -r "$(ls -t | head -n 1)" /mnt/f/study/monitoring'

alias getry="cd && mkdir -p /usr/share/wordlists && wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O /usr/share/wordlists/rockyou.txt && clear && ls /usr/share/wordlists"
alias sort="du -ah . | sort -rh"
alias mysize="cd /mnt/wslg && apt install ncdu -y && ncdu"
alias myports="netstat -tulpn | grep LISTEN"
alias editg="gedit /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5Menus/GamesDockerMenu/gui/4.py"
alias menu="py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/DockerMenu/noGui/a.py"
alias bbc="nano /root/.bashrc"
alias pihole="gc http://192.168.1.237/admin"
alias sgc="cd /mnt/f/study/cloud/gcp/cli"
alias sansible="cd /mnt/f/study/Infrastructure_as_Code/ansible"
alias sysa="systemctl start"
alias sysb="systemctl enable"
alias sysc="systemctl status"
alias sysd="systemctl restart"
alias kube='sudo apt-get install -y apt-transport-https curl gnupg2 software-properties-common && \
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
chmod +x kubectl && \
sudo mv kubectl /usr/local/bin/ && \
export PATH=$PATH:/usr/local/bin && \
sudo snap install helm --classic && \
snap install microk8s --classic && \
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
sudo install minikube /usr/local/bin/ && \
minikube start --driver=docker --force'
export PATH=$PATH:/usr/local/bin
alias n='nanox'
alias ssps="cd /mnt/f/study/shells/powershell"
alias scomp="cd /mnt/f/study/Dev_Toolchain/programming/python/compiled"
alias ssent="cd /mnt/f/study/Centralized_Logging"
alias cpps='cp -r "$(ls -t | head -n 1)" /mnt/f/study/shells/powershell'
alias rms="rm a.sh && n a.sh"
alias bashs="cd /mnt/f/study/shells/bash/scripts"
alias ndc="n docker-compose.yml"
alias rma="rm a.py && n a.py"
alias startd="systemctl start docker && systemctl enable docker"
alias drts="docker run -v /mnt/c/:/c/ \ -e DISPLAY=$DISPLAY \ -v /tmp/.X11-unix:/tmp/.X11-unix \ -p 3000:3000 \ -it \ --name typescript \ michadockermisha/backup:typescript"
alias dush="du -sh"
alias editfixer='n /mnt/f/study/Dev_Toolchain/programming/python/apps/filesfixer/AllFilesInPath/b.py'
alias fixer="py /mnt/f/study/Dev_Toolchain/programming/python/apps/filesfixer/AllFilesInPath/b.py"
alias restorestudy='c && cd study && drun study michadockermisha/backup:study sh -c "apk add rsync && rsync -aP /home/* /c/study/ && exit"'
alias sgit="cd /mnt/f/study/Version_Control"
alias word="find . -type f -not -path "/\." -print0 | xargs -0 -P 4 grep -iRl"
alias getsplunk='docker run -d --name splunk -p 8000:8000 -p 8088:8088 -p 8089:8089 -p 9997:9997 -e SPLUNK_START_ARGS="--accept-license" -e SPLUNK_PASSWORD="adminadmin" -v /home/user/splunk-data:/opt/splunk/var splunk/splunk:latest && gcl 8000'
alias getmsf='getsnap && snap install metasploit-framework && msfconsole'
alias nin="n index.html"
alias njs="n app.js"
alias ncss="n style.css"
alias libre='apt install libreoffice-writer -y && libreoffice --writer'
alias abi="sudo apt install abiword -y && abiword"
alias nsj="n src/App.js"
alias nsc="n src/index.css"
alias shack="cd /mnt/f/study/Security_Networking/Hacking"
alias track='psw -command "cd C:\study\programming\python\apps\study_tracker; python 4.py" '
alias sreact="cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript/react/projects"
# Define colors
RED='\[\033[0;31m\]'
RESET='\[\033[0m\]'
# Customize the PS1 variable to include the username and path in red
PS1="${RED}\u@\h:\w\$ ${RESET}"
alias voice="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/Media2Text/speachtotext/7 && pip install unicorn fastapi && py app.py & gcl 8000"
alias myapps="cd /mnt/f/backup/windowsapps/installed/myapps/compiled_python"
alias spaas="cd /mnt/f/study/cloud/PaaS"
alias sinfo="cd /mnt/f/study/Security_Networking/Hacking/info_gathering"
alias sfix="space && fixer"
alias snpm="cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript/npm_nodejs"
alias getnginx='apt install nginx -y && systemctl start nginx && systemctl enable nginx'
alias rename='cd /mnt/f/study/shells/bash/scripts && ./setup_AI_renamer.sh'
alias g="gedit"
alias ncdustu="apt install ncdu -y && stu && ncdu"
alias sclu="cd /mnt/f/study/cluster"
alias cdweb="cd /mnt/f/backup/windowsapps/installed/WebDrivers"
alias chrome="google-chrome-stable --no-sandbox"
alias scom="cd /mnt/f/study/communication"
alias stux="stu && ex"
alias sapache="cd /mnt/f/study/hosting/WebServers/apache"
alias snginx="cd /mnt/f/study/hosting/WebServers/nginx"
alias sazure="cd /mnt/f/study/cloud/azure/cli"
alias synclabs="rsync -av --delete /mnt/f/study/Dev_Toolchain/programming/python/apps/labs/ /mnt/f/study/exams/Labs/ && rsync -av --delete /mnt/f/study/Dev_Toolchain/programming/python/apps/labs/ /mnt/f/study/cloud/Labs/"
alias sras="cd /mnt/f/study/Platforms/linux/raspberry"
alias sexport="cd /mnt/f/backup/linux && ex"
alias title='echo '\''remake all steps... add big long title for the tutorial... make sure the topic and tools in the tutori al are mentioned in the title'\'''
alias sanal="cd /mnt/f/study/datascience/Analytics"
alias echoit='cat /mnt/f/study/Artificial_Intelligence/prompts/project_echo_creator'
alias gpts=' nano /mnt/f/study/Artificial_Intelligence/OpenAI'
alias getjan="cd && mkdir -p ~/jan-ai && cd ~/jan-ai && wget https://github.com/janhq/jan/releases/download/v0.5.2/jan-linux-amd64-0.5.2.deb && sudo apt-get update && sudo apt-get install -y libnss3 libxss1 xdg-utils && sudo dpkg -i jan-linux-amd64-0.5.2.deb && sudo apt-get install -f && jan --no-sandbox"
alias getssh='sudo apt-get install -y openssh-server && sudo systemctl enable ssh && sudo systemctl start ssh && sudo bash -c '\''echo -e "\nPermitRootLogin yes\nPasswordAuthentication yes" >> /etc/ssh/sshd_config'\'' && sudo systemctl restart ssh && source ~/.bashrc && sudo passwd root'
alias afterf="nano /mnt/f/backup/windowsapps/install/add.txt"
alias exportex="cd /mnt/f/backup/linux && ex"
alias myec2="aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output table"
alias inbound="gc https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#ModifyInboundSecurityGroupRules:securityGroupId=sg-0286fc995dc776496"
alias awsconf='apt install awscli -y && aws configure set aws_access_key_id AKIATFQ7MED5RUAH3H5L && aws configure set aws_secret_access_key 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 && aws configure set region us-east-1'
alias ppwd='psw -command "pwd"'
alias getorch='pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu111 && python3 -c "import torch; print(torch.version)"'
alias dea="deactivate"
alias getelk='apt-get update && sudo apt-get install openjdk-17-jre-headless -y && sudo apt-get install nginx -y && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - && sudo apt-get install apt-transport-https -y && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list && sudo apt-get update && sudo apt-get install elasticsearch -y && rm -rf /etc/elasticsearch/elasticsearch.yml && cp /mnt/f/study/Centralized_Logging/ELK/installationfiles/"etc elasticsearch elasticsearch.yml" /etc/elasticsearch/elasticsearch.yml && rm -rf /etc/elasticsearch/jvm.options && cp /mnt/f/study/Centralized_Logging/ELK/installationfiles/"etc elasticsearch jvm.options" /etc/elasticsearch/jvm.options && sudo systemctl start elasticsearch.service && sudo systemctl enable elasticsearch.service && clear && curl -X GET "localhost:9200" && sudo apt-get install kibana -y && rm -rf /etc/kibana/kibana.yml && cp /mnt/f/study/Centralized_Logging/ELK/installationfiles/"etc kibana kibana.yml" /etc/kibana/kibana.yml && sudo systemctl start kibana && sudo systemctl enable kibana && sudo apt-get install logstash -y && sudo systemctl start logstash && sudo systemctl enable logstash && sudo apt-get install filebeat -y && rm -rf /etc/filebeat/filebeat.yml && cp /mnt/f/study/Centralized_Logging/ELK/installationfiles/"etc filebeat filebeat.yml" /etc/filebeat/filebeat.yml && sudo filebeat modules enable system && sudo filebeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"localhost:9200\"]" && sudo systemctl start filebeat && sudo systemctl enable filebeat && clear && curl -XGET http://localhost:9200/_cat/indices?v'
alias pipreq="pip install -r requirements.txt"
alias skafka='cd /mnt/f/study/distributed_messaging/tools/KAFKA'
alias storch="cd /mnt/f/study/DeepLearning/FrameWorks/torch"
alias mymail="echo 'michaelovsky5@gmail.com' "
alias cptorch='cp -r "$(ls -t | head -n 1)" "/mnt/f/study/DeepLearning/FrameWorks/torch"'
alias cptensor='cp -r "$(ls -t | head -n 1)" "/mnt/f/study/DeepLearning/FrameWorks/tensorflow"'
alias syncneural="rsync -av --delete /mnt/f/study/Machine_Learning/Neural_Networks/ /mnt/f/study/Dev_Toolchain/programming/python/datascience/Neural_Network/"
alias slabs="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/labs"
alias cpsnap='cp -r "$(ls -t | head -n 1)" "/mnt/f/study/Platforms/linux/Package_Manager/snap"'
alias 100txt="cat /mnt/f/study/Artificial_Intelligence/prompts/create_python_code_for_100_txt_files"
alias sphp="cd /mnt/f/study/Dev_Toolchain/programming/php"
alias pya="py a.py"
alias mkt="mk templates"
alias ndex="nano templates/index.html"
alias ad2s="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/AutomateDownloads2study"
alias updatepip="python3 -m pip install --upgrade pip"
alias ssnap="cd /mnt/f/study/Platforms/linux/Package_Manager/snap"
nanox() {
    /usr/bin/nano "$@"
    chmod +x "$@"
}
alias makes="cat '/mnt/f/study/Artificial_Intelligence/prompts/make_script'"
alias scprc='apt install sshpass -y && bash /mnt/f/study/shells/bash/scripts/sshpass.sh '
alias stest="cd /mnt/f/study/QA/testing"
alias last3="ls -lt | head -n 4 | tail -n 3"
alias scon="cd /mnt/f/study/converting"
alias size="du -sh /mnt/c/wsl2/ubuntu"
alias sizes="du -sh /mnt/c/wsl2/ubuntu && du -sh /mnt/c/wsl2/ubuntu2 && df -h /mnt/c"
alias pipi="pip install"
alias ftpserver="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/upload/uploadDownloadserver/ftpserver/2"
alias cpscript='cp -r "$(ls -t | head -n 1)" /mnt/f/study/shells/bash/scripts'
alias cpscript2='cp -r "$(ls -t | head -n 1)" /mnt/f/study/shells/powershell/scripts'
alias scripts="cd /mnt/f/study/shells/bash/scripts"
alias scripts2="cd /mnt/f/study/shells/powershell/scripts"
getnagios() {
    sudo apt install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.4 libgd-dev
    sudo useradd nagios
    sudo groupadd nagcmd
    sudo usermod -a -G nagcmd nagios
    cd /tmp
    wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.6.tar.gz
    tar xzf nagios-4.4.6.tar.gz
    cd nagios-4.4.6
    ./configure --with-nagios-group=nagios --with-command-group=nagcmd
    make all
    sudo make install
    sudo make install-init
    sudo make install-config
    sudo make install-commandmode
    sudo make install-webconf
    sudo bash -c "echo -e 'root\nroot' | htpasswd -c /usr/local/nagios/etc/htpasswd.users root"
    sudo a2enmod rewrite cgi
    sudo systemctl restart apache2
    cd /tmp
    wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
    tar xzf nagios-plugins-2.3.3.tar.gz
    cd nagios-plugins-2.3.3
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
    make
    sudo make install
    sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
    sudo systemctl start nagios.service
    sudo systemctl enable nagios.service
    echo "Access Nagios at: http://$(hostname -I | awk '{print $1}')/nagios"
}
alias scolab="cd /mnt/f/study/collaboration"
alias sqa="cd /mnt/f/study/QA"
alias topdf="bash /mnt/f/study/shells/bash/scripts/convert_and_optimize_docx_files_to_pdf.sh"
alias hflogin='apt install python3-pip -y && pip install huggingface_hub && huggingface-cli login --token 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'
alias hfdownload="huggingface-cli download"
alias getnpm='curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs=22.1.0-1nodesource1 && npm install -g npm@latest && node -v && npm -v'
alias getnvm='curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && brc2 && export NVM_DIR="$HOME/.nvm" && brc2'
alias getconda='cd && curl -O https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh && bash Anaconda3-2020.11-Linux-x86_64.sh -b && export PATH=$HOME/anaconda3/bin:$PATH && source ~/.bashrc && conda update conda -y && conda update anaconda -y && conda -V'
alias brc2='brc1 && rsync -aP /root/.bashrc /mnt/f/backup/linux/wsl/alias.txt && rsync -aP /root/.bashrc ~/.bashrc && rsync -aP /root/.bashrc /mnt/f/study/shells/bash/.bashrc && sudo cp /root/.bashrc /home/ubuntu/.bashrc && sudo chown ubuntu:ubuntu /home/ubuntu/.bashrc && sudo -u ubuntu bash -c "source /home/ubuntu/.bashrc"'
alias subu="su ubuntu"
alias used="n /mnt/f/study/Artificial_Intelligence/UsedByMe/used"
alias nalias="n /mnt/c/Users/micha/Desktop/alias.txt"
alias compress="xz -z -9"
alias sweb="cd /mnt/f/study/webbuilding"
alias 128="down && apt install imagemagick -y && convert download.png -resize 128x128! download_resized.png"
alias snvidia="cd /mnt/f/study/nvidia"
alias scplaylist="down && rsync -av --progress playlist/* root@192.168.1.120:/root/python"
alias scptv="down && rsync -av --progress tv/ root@192.168.1.101:/home/TV"
alias scpanime="down && rsync -av --progress anime/ root@192.168.1.101:/home/anime"
alias scpmovies="down && rsync -av --progress movies/ root@192.168.1.101:/home/movies"
alias plex="gc http://192.168.1.101:32400"

alias ssg="cd /mnt/f/study/webbuilding/StaticSiteGenerators"
alias downloadable="cat /mnt/f/study/Artificial_Intelligence/prompts/downloadable"
alias sprompt="cd /mnt/f/study/Artificial_Intelligence/prompts"



alias chm="chmod +x"
alias applied="cat /mnt/c/Users/micha/Desktop/applied.txt"
alias sshells="cd /mnt/f/study/shells"
alias getcuda="sudo add-apt-repository ppa:graphics-drivers/ppa -y && sudo apt-get update && sudo apt-get install nvidia-driver-535 -y && sudo apt-get install -y nvidia-cuda-toolkit && nvidia-smi && nvcc --version"
alias dcreds="cd /mnt/f/backup/windowsapps/Credentials && built michadockermisha/backup:creds . && docker push michadockermisha/backup:creds"
alias scred="cd /mnt/f/backup/windowsapps/Credentials"
alias gitoken="cat /mnt/f/backup/windowsapps/Credentials/github/accessToken.txt"
alias hftoken="cat /mnt/f/backup/Credentials/huggingface/token.txt"
alias sshec2="cp /mnt/f/backup/windowsapps/Credentials/aws/key.pem ~ && cd && chmod 600 key.pem && ssh -i /root/key.pem ubuntu@54.173.176.93"

alias ftp="gc http://192.168.1.196:5000"
alias getaudio="apt install python3.10-venv -y && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/transcripts/epub2tts && sudo apt install -y espeak-ng ffmpeg -y && pip install . && venv && python -m nltk.downloader punkt_tab && edge-tts --list-voices | grep -i hebrew"
alias ssap="cd /mnt/f/study/SAP"

alias getmonero="sudo apt-get install -y monero && monero-wallet-cli"

alias wallet="sudo apt-get install -y monero && monero-wallet-cli --wallet-file /mnt/f/backup/windowsapps/Credentials/monero/MyWallet"
alias getmysql="sudo apt-get install -y mysql-server && sudo systemctl start mysql && sudo systemctl enable mysql"
alias smysql=" sudo mysql"
alias getgres="sudo apt install -y postgresql postgresql-contrib && sudo systemctl start postgresql"
alias sgress="sudo -i -u postgres psql"
alias smongo=" mongosh"
alias getredis="sudo apt update && sudo apt install -y redis-server && sudo systemctl start redis-server && sudo systemctl enable redis-server"
alias smariadb="sudo mysql"

alias getyarn=" getnpm && sudo npm install --global yarn"
alias sflow="cd /mnt/f/study/datascience/Data_Flow"
alias getnpm18="curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs && npm install -g npm@latest && node -v && npm -v"
alias getmongo="sudo apt install -y gnupg curl && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo tee /etc/apt/trusted.gpg.d/mongodb-server-7.0.asc && echo deb [arch=amd64,arm64] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && sudo apt-get update && sudo apt-get install -y mongodb-org && sudo systemctl start mongod && sudo systemctl enable mongod"

alias ppya="psw -command pya"

alias catwallet="cat /mnt/f/backup/windowsapps/Credentials/monero/address"
alias swallet="cd /mnt/f/study/Passive_income/blockchain/wallets"
alias catwallet2="cat /mnt/f/backup/windowsapps/Credentials/geth/ethereumAddress.txt"



alias fixd="setups && sfix && sone && sfix && sdocker && sfix"
alias napplied="n /mnt/f/backup/windowsapps/Credentials/linkedin/LinkedIn-Easy-Apply-Bot/applied.txt"

alias spassword="cd /mnt/f/study/Security_Networking/Hacking/passwordCracking"
alias systop="systemctl stop"
alias systart="systemctl start"
alias sysenable="systemctl enable"
alias sysrestart="systemctl restart"
alias systatus="systemctl status"
alias mysite="gc https://michaelresume.great-site.net/?i=1"


alias fixlock="pids=\$(pgrep -x dpkg); if [ -n \"\$pids\" ]; then sudo kill -9 \$pids; fi; sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/dpkg/updates/*; sudo dpkg --configure -a"
alias calias="cat /mnt/c/Users/micha/Desktop/alias.txt"

alias 1337x="gc https://1337x.to/"
alias smemo="cd /mnt/f/study/memory_management"

alias mygames="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/game_tracker && py h.py"

alias sspeach="cd /mnt/f/study/speach2text"
alias sban="cd /mnt/f/study/Passive_Income/bandwidth_sharing"
alias using="n /mnt/f/study/Passive_Income/currently_running"

alias saveweb="cd /mnt/c/Users/micha/videos/webinars && docker run --rm -v /mnt/c/Users/micha/videos/webinars:/backup michadockermisha/backup:webinars sh -c \"apk update && apk add --no-cache rsync && rsync -av /home/* /backup\" && docker build -t michadockermisha/backup:webinars . && docker push michadockermisha/backup:webinars && rm -rf /mnt/c/Users/micha/videos/webinars/*"



alias smine="cd /mnt/f/study/Passive_Income/blockchain/mining_tools"
alias sblock="cd /mnt/f/study/Passive_Income/blockchain"
alias strade="cd /mnt/f/study/Passive_Income/blockchain/trading_bots"

alias big="bash /mnt/f/study/shells/bash/scripts/how_big_are_the_Files_in_my_path.sh"

alias slink="cd /mnt/f/backup/windowsapps/Credentials/linkedin/LinkedIn-Easy-Apply-Bot"

alias rmlogs="rmf /mnt/f/backup/windowsapps/Credentials/linkedin/LinkedIn-Easy-Apply-Bot/logs/* "
alias getsqlite="sudo apt install -y sqlite3"
alias ssqlite="sqlite3"

alias sdis="cd /mnt/f/study/disturbed"
alias sts="cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript/typescript/projects"

alias serror="cd /mnt/f/study/QA/Error_Tracking"
alias pipit="pip install pipreqs && pipreqs . --force --savepath requirements.txt && pip install -r requirements.txt && python app.py"
alias pipit2="pip install pipreqs && pipreqs . --force --savepath requirements.txt && pip install -r requirements.txt && python a.py"




alias sscrum="cd /mnt/f/study/scrum"
alias sres="cd /mnt/f/study/resume"
alias sjava="cd /mnt/f/study/Dev_Toolchain/programming/java"
alias getrust="curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && source $HOME/.cargo/env && . /root/.cargo/env && rustc --version && cargo --version"
alias srust="cd /mnt/f/study/Dev_Toolchain/programming/rust"
alias myres="cd /mnt/f/study/resume/MyResume"
alias sorm="cd /mnt/f/study/ORM"

alias dismem="cd /mnt/f/study/disturbed/disturbedMemorycaching"
alias sfile="cd /mnt/f/study/FilesystemManagement"
alias srea="cd /mnt/f/study/Research"

alias sdoc="cd /mnt/f/study/documents"
alias scent="cd /mnt/f/study/CentralizedManagement"
alias sruby="cd /mnt/f/study/Dev_Toolchain/programming/ruby"
alias srepl="cd /mnt/f/study/REPL"

alias scrm="cd /mnt/f/study/crm"
alias svuln="cd /mnt/f/study/Security_Networking/Hacking/vulnerabilty"
alias ecom="cd /mnt/f/study/E-commarce"
alias scis="cd /mnt/f/study/cisco"

alias getqemu="sudo apt install -y qemu-kvm qemu-utils libguestfs-tools libvirt-daemon-system libvirt-clients bridge-utils virt-manager && sudo kvm-ok"

alias getmariadb="sudo apt install -y mariadb-server && sudo systemctl start mariadb && sudo systemctl enable mariadb && sudo mysql_secure_installation"

alias secom="cd /mnt/f/study/e-commarce"
alias spas="cd /mnt/f/study/Security_Networking/Hacking/passwordCracking"
alias svisual="cd /mnt/f/study/datascience/Visualization"
alias getruby="sudo apt install -y ruby-full build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common ruby-bundler ruby-dev && gem install rails -v 7.0.4 &&  gem install bundler"
alias sstorage="cd /mnt/f/study/storage"

alias shelp="cd /mnt/f/study/QA/helpdesk"
alias pteleg="py /mnt/f/backup/windowsapps/Credentials/telegram/bot/download_videos_from_telegram_group.py"
alias skube="cd /mnt/f/study/Orchestration/kubernetes"
alias sorch="cd /mnt/f/study/Orchestration"
alias bbrc="psw -command brc"

alias sdpf="cd /mnt/f/study/datascience/DataPipeLineFramework"

alias sdv="cd /mnt/f/study/Version_Control/Data_Versioning"

alias sbrow="cd /mnt/f/study/browsers"
alias upgrade="sudo sed -i s/Prompt=lts/Prompt=normal/ /etc/update-manager/release-upgrades && do-release-upgrade -f DistUpgradeViewNonInteractive"
alias upall="updates && upgrade && rmsources && updates && upgrade"

alias fixpost="sudo postconf -e myhostname=localhost.localdomain mydomain=localdomain && sudo dpkg --configure -a"
alias pythonm="python3 -m http.server"
alias sproj="cd /mnt/f/study/projects"

alias shtml="cd /mnt/f/study/Dev_Toolchain/programming/frontend/html/projects"
alias sbackup="cd /mnt/f/study/backup"
alias getpython2="sudo apt-get remove -y python3-pip && sudo apt-get purge -y python3 python3-venv && sudo apt-get autoremove -y && sudo apt-get install -y python2.7 python2.7-dev python-pip && sudo ln -sf /usr/bin/python2.7 /usr/bin/python && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py && python2 get-pip.py && python2 --version && pip --version"
alias myweb="gc https://michacard.netlify.app"

alias getnetify="getnpm && npm install -g netlify-cli && netlify login && netlify init && netlify deploy --prod"
alias pym="python3 -m http.server"

alias getrvm="sudo apt install gnupg2 -y && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \curl -sSL https://get.rvm.io | bash -s stable && source /etc/profile.d/rvm.sh && rvm --version"
alias swine="cd /mnt/f/study/shells/tools/wine"
alias cpw="cp -r lockmouseSecondDisplay.ps1 /mnt/f/study/shells/tools/wine"
alias cpc="cp -r lockmouseSecondDisplay.ps1 /mnt/f/study/converting"
alias stools="cd /mnt/f/study/shells/tools"
alias sbpf="cd /mnt/f/study/shells/bash/BPF"
alias swebhost="cd /mnt/f/study/hosting/WebHosting"
alias interface="ip -o link show | awk -F:  {print $2}"
alias skernal="cd /mnt/f/study/shells/bash/kernal"

alias getneo4j="apt install apt-transport-https ca-certificates curl software-properties-common -y && curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && add-apt-repository deb https://debian.neo4j.com stable 4.1 && apt update && apt install neo4j -y && systemctl enable neo4j.service && systemctl start neo4j.service && cypher-shell -a neo4j+s://5c52969e.databases.neo4j.io -u neo4j -p BB_RD1QfrqRop7ajXf2MHdm7njDcv_V08IKryEf7n6I"
alias sldap="cd /mnt/f/study/networking/protocols/LDAP"

alias spara="cd /mnt/f/study/datascience/Parallel_computing"
alias sgo="cd /mnt/f/study/Dev_Toolchain/programming/go"
alias purgepip="pip freeze | xargs pip uninstall -y"
alias rmdocker="sudo mount -o remount,rw /mnt/wslg/distro && sudo rm -rf /mnt/wslg/distro/var/lib/docker/layout2 &&  sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose-plugin && sudo apt-get autoremove -y --purge && sudo rm -rf /var/lib/docker /etc/docker && sudo rm /etc/apparmor.d/docker && sudo groupdel docker && sudo rm -rf /var/run/docker.sock"
alias disk="du -sh /mnt/wslg"


alias github="gc https://github.com/Michaelunkai/study2"
alias sspoof="cd /mnt/f/study/Security_Networking/Hacking/spoofing"

alias getwine="dpkg --add-architecture i386 && apt-get update && apt-get install wine32 winetricks -y && sudo apt install wine winbind -y"


alias rmsnap="sudo systemctl stop snapd && sudo apt-get remove --purge -y snapd && sudo rm -rf /var/cache/snapd /var/snap /snap /root/snap /home/*/snap"

alias more="cat /mnt/f/study/Artificial_Intelligence/prompts/more"
alias seco="cd /mnt/f/study/econometrics"


alias getlibssl1="wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
alias rmpython="sudo apt purge -y python3* && sudo apt autoremove -y && sudo apt clean && sudo rm -rf /usr/local/lib/python* /usr/lib/python* /usr/bin/python* ~/.local/lib/python* ~/.cache/pip"
alias rmvim="sudo apt-get purge --auto-remove vim vim-runtime vim-tiny vim-common vim-gui-common"




alias top100="/mnt/f/study/shells/bash/scripts/top100.sh"
alias sprot="cd /mnt/f/study/networking/protocols"
alias srd="cd /mnt/f/study/remote/RemoteDesktop"
alias sre="cd /mnt/f/study/remote"
alias srp="cd /mnt/f/study/remote/RemoteProcedure"
alias psub="sudo usermod -aG sudo ubuntu && sudo usermod -aG root ubuntu && sudo chmod -R 777 /root && sudo chown -R ubuntu:root /root && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ubuntu"

alias stu100=" /mnt/f/study/shells/bash/scripts/top100stu.sh"
alias win100="/mnt/f/study/shells/bash/scripts/top100win.sh"
alias stux="stu && ee"

alias kube="sudo apt-get install -y apt-transport-https curl gnupg2 software-properties-common ca-certificates lsb-release && curl -LO https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/ && export PATH=\$PATH:/usr/local/bin && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && sudo snap install microk8s --classic && curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/ && minikube start --driver=docker --force"




alias sfm="cd /mnt/f/study/FilesystemManagement/FileManagers"
alias rmkube="sudo kubeadm reset -f || true && sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni kube* || true && sudo apt-get autoremove -y || true && sudo rm -rf ~/.kube /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/rancher /var/lib/docker /usr/local/bin/k3s /root/.minikube /usr/libexec/docker /usr/local/bin/minikube || true && sudo systemctl stop k3s || true && sudo systemctl disable k3s || true && sudo systemctl daemon-reload || true"


alias kpods="kubectl get pods -n kube-system"
alias 2-3="cat /mnt/f/study/Artificial_Intelligence/prompts/words"


alias telegram="gc https://web.telegram.org/a/"
alias smitm="cd /mnt/f/study/Security_Networking/Hacking/ManInTheMiddle"
alias comp="cd /mnt/f/backup/windowsapps/installed/compiled_python"


alias side="cd /mnt/f/study/ide/IDEs"
alias getjava="wget https://download.java.net/java/GA/jdk23/3c5b90190c68498b986a97f276efd28a/37/GPL/openjdk-23_linux-x64_bin.tar.gz && tar -xvzf openjdk-23_linux-x64_bin.tar.gz && mv jdk-23 /usr/local/ && update-alternatives --install /usr/bin/java java /usr/local/jdk-23/bin/java 1 && update-alternatives --install /usr/bin/javac javac /usr/local/jdk-23/bin/javac 1 && update-alternatives --set java /usr/local/jdk-23/bin/java && update-alternatives --set javac /usr/local/jdk-23/bin/javac && java -version"
alias sjet="cd /mnt/f/study/ide/IDEs/JetBrains"
alias catalias="cat ~/.bashrc"


alias clean=" cd /mnt/f/study/shells/bash/scripts && ./cleanstu.sh"
alias swf="cd /mnt/f/study/Devops/automation/workflow"

alias rmgit="find . -type d \( -name .git -o -name .github \) -exec rm -rf {} +"
alias getc="sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev"




alias logs=" psw -command logs2"



alias words="cd /mnt/f/study/Devops/automation/oneliners && word"
alias sdns="cd /mnt/f/study/networking/protocols/dns"


alias folders3=" echo for the tool we just talked about, which topic most related to which of this folders? choose only one that fits it most, answer in 5 words : && tree -d -L 3"
alias spc="cd /mnt/f/study/Security_Networking/Hacking/packetcapture"
alias sarp="cd /mnt/f/study/networking/protocols/arp"
alias tool="source /mnt/f/study/shells/bash/scripts/create_tool_dir.sh"
alias sproxy="cd /mnt/f/study/security/proxy"
alias spraph="cd /mnt/f/study/datascience/Visualization/graph"

alias sselenium="cd /mnt/f/study/QA/testing/selenium"


alias sdd="cd /mnt/f/study/disturbed/Disturbed_Debugging"
alias sdfs="cd /mnt/f/study/disturbed/Distributed_FileSystems"


alias phtml="python -m http.server"
alias svpn="cd /mnt/f/study/security/vpn"
alias spro="cd /mnt/f/study/networking/protocols"
alias stra="cd /mnt/f/study/networking/traffic"
alias onels="sone && ls"
alias getkernel=" cd ~ && sudo apt install -y build-essential flex bison dwarves libssl-dev libelf-dev cpio && git clone https://github.com/microsoft/WSL2-Linux-Kernel.git && cd WSL2-Linux-Kernel && make KCONFIG_CONFIG=Microsoft/config-wsl && sudo apt install build-essential flex bison dwarves libssl-dev libelf-dev cpio -y && sudo apt-get install -y linux-headers-generic && sudo apt install --install-recommends linux-generic-hwe-22.04 -y && sudo apt install -y linux-tools-common linux-tools-generic build-essential libelf-dev htop sysstat iotop iftop net-tools iproute2 lsof bpfcc-tools linux-cloud-tools-common 2>/dev/null"
alias cdtv="cd /mnt/f/Downloads/tv"

alias getflutter="mkdir -p /root/flutter_project && cd /root/flutter_project && wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.6-stable.tar.xz && tar xf flutter_linux_3.10.6-stable.tar.xz && export PATH=\"/root/flutter_project/flutter/bin:\$PATH\" && git config --global --add safe.directory /root/flutter_project/flutter && flutter config --no-analytics && flutter doctor --android-licenses && flutter doctor && flutter --version"
alias sphi="cd /mnt/f/study/Security_Networking/Hacking/phishing"
alias senu="cd /mnt/f/study/Security_Networking/Hacking/Enumeration"

alias swire="cd /mnt/f/study/Security_Networking/Hacking/Wireless_Attack"
alias sosint="cd /mnt/f/study/Security_Networking/Hacking/osint"
alias sint="cd /mnt/f/study/Security_Networking/Hacking/Intrusion_Detection"
alias sfuzz="cd /mnt/f/study/Security_Networking/Hacking/fuzzing"

alias spen="cd /mnt/f/study/Security_Networking/Hacking/pentesting"
alias sexpo="cd /mnt/f/study/Security_Networking/Hacking/exploits"
alias sbrut="cd /mnt/f/study/Security_Networking/Hacking/Brute_force"
alias ssqlin="cd /mnt/f/study/Security_Networking/Hacking/exploits/sql_injection"
alias spriv="cd /mnt/f/study/Security_Networking/Hacking/Privilege_Escalation"
alias sdos="cd /mnt/f/study/Security_Networking/Hacking/ddos-dos"
alias spay="cd /mnt/f/study/Security_Networking/Hacking/payloads"


alias schrome="cd /mnt/f/study/browsers/chrome"
alias surl="cd /mnt/f/study/networking/url_Shorting"
alias roktoken="echo ngrok config add-authtoken 2e5YpXo7VVuueVwjFmmiM9706tv_6MfqxYhAH2EpUNuAWrLVR"


alias rmcopy="rm *Copy*"
alias srs="cd /mnt/f/study/Security_Networking/Hacking/reverseSHELL"

alias cicd="cd /mnt/f/study/CI-CD"
alias ssec="cd /mnt/f/study/security/secrets"
alias sskd="cd /mnt/f/study/security/secrets/secret_key_detection"
alias getgo="bash /mnt/f/study/shells/bash/scripts/getgo.sh"




alias gethadoop="sudo apt-get update && sudo apt-get install -y openjdk-11-jdk wget && wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && tar -xzvf hadoop-3.3.6.tar.gz -C /usr/local && sudo mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && export HADOOP_HOME=/usr/local/hadoop && export PATH=\$PATH:\$HADOOP_HOME/bin && export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 && \$HADOOP_HOME/bin/hadoop version"
alias sdw="cd /mnt/f/study/datascience/data_warehouse"



alias getjava8="sudo apt-get install -y openjdk-8-jdk"
alias getzoo="bash /mnt/f/study/shells/bash/scripts/setup_and_run_Zookeper_ubuntu.sh"
alias getjava11="sudo apt-get install -y openjdk-11-jdk"

alias decompress="unxz"
alias cdocx="venv && stu && py /mnt/f/study/Dev_Toolchain/programming/python/apps/shrink/docx/docxShrinkcurrentPathWithsubFolders.py"
alias cpdf="venv && stu && py /mnt/f/study/Dev_Toolchain/programming/python/apps/shrink/pdf/pdfShrinkcurrentPathWithsubFolders.py"
alias cpdfdocx="cdocx && stu && dush && py /mnt/f/study/Dev_Toolchain/programming/python/apps/shrink/pdf/pdfShrinkcurrentPathWithsubFolders.py && dush"
alias getlibssl=" sudo add-apt-repository ppa:nrbrtx/libssl1 && update && sudo apt install libssl1.1"
alias sqr="cd /mnt/f/study/security/QRcode"


alias sla="cd /mnt/f/study/datascience/Analytics/Log_Analysis"


alias gethive="gethadoop && sudo apt install -y default-jdk wget && wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz && tar -xvzf apache-hive-4.0.1-bin.tar.gz && sudo mv apache-hive-4.0.1-bin /usr/local/hive && export HIVE_HOME=/usr/local/hive && export PATH=$HIVE_HOME/bin:$PATH && hive --version"


alias siot="cd /mnt/f/study/networking/Internet_of_Things"
alias sblu="cd /mnt/f/study/Bluetooth"
alias getpython="sudo apt install -y -qq python3 python3-pip python3-venv python3-twisted python-is-python3 python3-dev python3-setuptools python3-cryptography python3-impacket python3-wheel python3-cffi python3-tk python3-lxml libpq-dev build-essential libssl-dev libffi-dev apache2 libapache2-mod-wsgi-py3 libjpeg-dev zlib1g-dev && sudo apt autoremove -y -qq && python3 --version"
alias upython="sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt update && sudo apt install python3.13 -y && sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1"
alias getkali="getpython2 && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/katoolin/katoolin.py /usr/bin/katoolin && chmod +x /usr/bin/katoolin && katoolin"

alias myg="venv && py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/5.py"
alias stcp="cd /mnt/f/study/networking/protocols/tcp"
alias vscode="cd /mnt/f/study/ide/IDEs/vscode/KeyboardShortcuts"
alias sbrowtb="cd /mnt/f/study/browsers/Terminal-based"
alias spack="cd /mnt/f/study/networking/packets"
alias cptuv="rmf /mnt/f/study/exams/data_analysis/TUVTECH && cp -r /mnt/f/study/datascience/data_analysis/TUVTECH  /mnt/f/study/exams/data_analysis/TUVTECH"

alias snn="cd /mnt/f/study/DeepLearning/Neural_Networks"
alias venv2="python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip"
alias ranch="bash /mnt/f/study/shells/bash/scripts/getkubernetes.sh"


alias getbrew="bash /mnt/f/study/shells/bash/scripts/getbrew.sh"

alias selk="cd /mnt/f/study/Centralized_Logging/elk"

alias fulljava="sudo apt install -y default-jre default-jdk maven gradle ant ivy libcommons-lang3-java libcommons-io-java libcommons-collections3-java libcommons-codec-java libcommons-logging-java libcommons-dbcp-java libcommons-dbcp2-java libcommons-pool-java libcommons-pool2-java libswt-gtk-4-java libasm-java libaspectj-java libjcommon-java libjfreechart-java libhamcrest-java libmockito-java libcglib-java libjavassist-java libehcache-java libc3p0-java libproguard-java liblogback-java libdom4j-java libhibernate3-java libhibernate-validator-java libspring-core-java libspring-beans-java libspring-context-java libspring-web-java libaopalliance-java libjoda-time-java libcommons-compress-java libzip4j-java liblz4-java libsnappy-java libsqljet-java libhsqldb-java libderby-java libcommons-cli-java libcommons-math-java libcommons-math3-java libcommons-net-java libcommons-exec-java libcommons-validator-java libcommons-collections4-java libcommons-csv-java libxerces2-java libxml-commons-external-java libxml-commons-resolver1.1-java libbcel-java libsaxon-java libsaxonb-java libfreemarker-java libitext-java libjboss-logging-java libjboss-logging-tools-java libaopalliance-java libactivation-java libjgoodies-forms-java libxstream-java libfindbugs-java libslf4j-java liblog4j1.2-java libjoda-convert-java libapache-poi-java libjna-java libeclipselink-java libjaxb-api-java libxmlbeans-java libbatik-java libfop-java libswtchart-java libkxml2-java libcommons-discovery-java libaxis-java"
alias spark="/opt/spark/bin/spark-shell"


alias getspark="sudo apt install -y default-jdk scala git && wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz && tar xvf spark-3.5.3-bin-hadoop3.tgz && sudo mv spark-3.5.3-bin-hadoop3 /opt/spark && echo -e 'export SPARK_HOME=/opt/spark\nexport PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin\nexport PYSPARK_PYTHON=/usr/bin/python3' >> ~/.bashrc && source ~/.bashrc && start-master.sh && start-worker.sh spark://$(hostname):7077 && gcl 4040/jobs && /opt/spark/bin/spark-shell"

alias sspark="cd /mnt/f/study/datascience/spark"
alias venvpath="echo /mnt/f/backup/windowsapps/venv/bin/python3.10"
alias sbas="cd /mnt/f/study/Dev_Toolchain/programming/python/basics"



alias getvs="sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg /etc/apt/sources.list.d/vscode.list && sudo apt -y install wget gpg && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg && echo deb [arch=amd64] https://packages.microsoft.com/repos/code stable main > /etc/apt/sources.list.d/vscode.list && apt -y update && apt -y install code && yes | code --install-extension ms-python.python --no-sandbox --user-data-dir=~/.vscode-root"
alias sset="cd /mnt/f/study/setups"

alias fixclock="sudo timedatectl set-ntp false && sudo timedatectl set-time 2024-10-14 15:30:00 && sudo timedatectl set-ntp true"
alias compare="gc https://www.textcompare.org/python/ "
alias sbasics="cd /mnt/f/study/Dev_Toolchain/programming/python/basics"
alias cleanvenv="venv && cd venv && pip install --upgrade pip && pip install pip-autoremove && pip-autoremove --yes && pip freeze > requirements.txt && find /mnt/f/backup/windowsapps/venv -type d -name __pycache__ -exec rm -rf {} + && find /mnt/f/backup/windowsapps/venv -type f -name *.pyo -o -name *.pyc -exec rm -f {} + && find /mnt/f/backup/windowsapps/venv -type d -name *.dist-info -exec rm -rf {} + && find /mnt/f/backup/windowsapps/venv -type d -name *.egg-info -exec rm -rf {} + && find /mnt/f/backup/windowsapps/venv -name *.so -exec strip --strip-unneeded {} + && rm -rf /mnt/f/backup/windowsapps/venv/share && rm -rf /mnt/f/backup/windowsapps/venv/include && rm -rf /mnt/f/backup/windowsapps/venv/lib/python*/site-packages/tests && pip cache purge && deactivate"
alias plexrc="n /mnt/f/study/hosting/plex/bashrc"

alias top1000="cd /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000"

alias get1337x="venv && python -m pip install --user git+https://github.com/NicKoehler/1337x"


alias getqt="sudo apt install -y qtcreator qtbase5-dev qtbase5-dev-tools qttools5-dev qttools5-dev-tools qtdeclarative5-dev qtquickcontrols2-5-dev qtwebengine5-dev libqt5core5a libqt5gui5 libqt5widgets5 libqt5network5 libqt5sql5 libqt5xml5 libqt5test5 libqt5printsupport5 libqt5multimedia5 libqt5multimediawidgets5 libqt5opengl5-dev libqt5positioning5 libqt5webkit5 libqt5svg5-dev libqt5x11extras5 qtwayland5 qt3d5-dev qt3d5-examples qttranslations5-l10n qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-dialogs qml-module-qtquick-layouts qml-module-qtquick-privatewidgets qml-module-qtquick-window2 qml-module-qtquick2"

alias sload="cd /mnt/f/study/networking/load_balance"


alias big2="bash /mnt/f/study/shells/bash/scripts/how_big_are_the_Files_in_my_path2.sh"
alias watched="cp -r /root/watched_movies.db /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000"
alias sblue="cd /mnt/f/study/Bluetooth"


alias scpmyg="rm -f /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/Gui/games_data.json && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/nogui/games_data.json /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/Gui/ && scp /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/nogui/games_data.json ubuntu@192.168.1.193:/home/ubuntu"
alias cleanstu="sudo apt install -y rdfind && rdfind -makehardlinks true /mnt/f/study && d2p && cpdfdocx && stu && rmf results.txt"


alias venv="cdapps && apt install python3.10-venv -y && sudo apt install python3-venv -y && cd /mnt/f/backup/windowsapps && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd "
alias getlb="apt install libreoffice-writer -y"
alias ncdu="apt install -y ncdu && ncdu"

alias getab="apt install abiword -y"
alias ccc="cpo && cps && sfix"
alias rmdoc="find /mnt/f/study -type f -name *.docx -delete"

alias watched2="cp -r /root/watched_tv_shows.db /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv"



alias sdesk="cd /mnt/c/Users/micha/Desktop"
alias swish="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/wishlist/awsdb/ubuntu"
alias plextoken="cat /mnt/f/backup/windowsapps/Credentials/plex/token.txt"
alias d2p="bash /mnt/f/study/shells/bash/scripts/docx2pdf.sh && rmdoc"

alias rmd="rmf /mnt/f/Downloads/*"
alias shot="cd /mnt/f/study/Platforms/windows/AutoHotkey"
alias cdt="cd templates"
alias getngrok2="curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs=22.1.0-1nodesource1 && npm install -g npm@latest && node -v && npm -v && npm install -g ngrok && ngrok -v && ngrok config add-authtoken 2pRcoJEfKjWvAu2zHDAmHA1caui_7NRu838gBdijqdv8TeuM3"
alias fixpostfix="sudo postconf -e myhostname=localhost.localdomain mydomain=localdomain && sudo dpkg --configure -a"


alias termurl="apt install jq -y && curl --silent http://localhost:4040/api/tunnels | jq -r .tunnels[0].public_url "




alias cccc="cpo && cps && sfix && fixd"
alias getmvn="getjava && apt install maven -y"
alias ssc="cd /mnt/f/study/shells/bash/scripts"
alias what="bash /mnt/f/study/shells/bash/scripts/get_wsl_distro_name.sh"

alias 20000="venv && cd ~ && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/a.py ~/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/watched_tv_shows.db ~/watched_tv_shows.db && wget -q https://datasets.imdbws.com/title.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.ratings.tsv.gz && wget -q https://datasets.imdbws.com/title.crew.tsv.gz && wget -q https://datasets.imdbws.com/title.principals.tsv.gz && wget -q https://datasets.imdbws.com/name.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.episode.tsv.gz && wget -q https://datasets.imdbws.com/title.akas.tsv.gz && python3 a.py"


alias ccubu="(sudo apt install -y rdfind && rdfind -makehardlinks true /mnt/f/study && d2p && cpdfdocx && stu && rmf results.txt) &"
alias gmail="gc https://mail.google.com/mail/u/0/"
alias term="bash /mnt/f/study/shells/bash/scripts/ngrokTerminal.sh && gmail"
alias saverc="cat /mnt/c/Users/micha/Desktop/alias.txt >> /root/.bashrc && source /root/.bashrc"

alias 10000="venv && cd && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/g.py /root/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pya"
alias backbbb="(cd /mnt/f/backup/windowsapps && docker build -t michadockermisha/backup:windowsapps . > /dev/null 2>&1 && docker push michadockermisha/backup:windowsapps > /dev/null 2>&1) & (cd /mnt/f/study && docker build -t michadockermisha/backup:study . > /dev/null 2>&1 && docker push michadockermisha/backup:study > /dev/null 2>&1) & (cd /mnt/f/backup/linux/wsl && docker build -t michadockermisha/backup:wsl . > /dev/null 2>&1 && docker push michadockermisha/backup:wsl > /dev/null 2>&1) &"
alias bbb="backapps && backupwsl && gg"




alias latemv="late && cc && ls && mvdoc && ls"
alias editmyg="cd  /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/nogui && py e.py"
alias backapps="cd /mnt/f/backup/windowsapps && echo -e venv/ > .dockerignore && docker build -t michadockermisha/backup:windowapps . && docker push michadockermisha/backup:windowapps && rm .dockerignore"
alias subs="venv && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/youtube/Playlists/substoplaylist && py h.py"

alias rmalias="> /mnt/c/Users/micha/Desktop/alias.txt"
alias getjup="apt install -y jupyter-notebook"
alias jup="jupyter-notebook --allow-root *.ipynb"
alias repython="sudo apt update && sudo apt install --fix-broken -y && sudo apt install --reinstall -y python3 python3-pip python3-venv python3-twisted python3-dev python3-setuptools python3-cryptography python3-impacket python3-wheel python3-cffi python3-tk python3-lxml libpq-dev build-essential libssl-dev libffi-dev apache2 libapache2-mod-wsgi-py3 libjpeg-dev zlib1g-dev && sudo apt autoremove -y && sudo apt clean && rm -rf ~/.local/lib/python* ~/.cache/pip && python3 --version"



alias sprom="cd /mnt/f/study/monitoring/prometheus"
alias conf8="echo -e [wsl2]nmemory=8GBnmemory=100% >> /mnt/c/Users/micha/.wslconfig"
alias conf6="echo -e [wsl2]nmemory=6GBnmemory=100% >> /mnt/c/Users/micha/.wslconfig"
alias conf12="echo -e [wsl2]nmemory=12GBnmemory=100% >> /mnt/c/Users/micha/.wslconfig"
alias conf4="echo -e [wsl2]nmemory=4GBnmemory=100% >> /mnt/c/Users/micha/.wslconfig"
alias sfirewall="cd /mnt/f/study/security/firewall"
alias sdc="cd /mnt/f/study/AI_and_Machine_Learning/Datascience"
alias sai="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence"
alias sdeep="cd /mnt/f/study/AI_and_Machine_Learning/DeepLearning"
alias sneural="cd /mnt/f/study/AI_and_Machine_Learning/Neural_Networks"
alias name="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/name_this_liner"


alias bin="psw -command bin"
alias sda="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/data_analysis"
alias stuv="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/TUVTECH"
alias prompt="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts"
alias folders2="bash /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/folders2.sh"
alias saml="cd /mnt/f/study/AI_and_Machine_Learning"
alias swm="cd /mnt/f/study/AI_and_Machine_Learning/Workflow_Management"
alias tools="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/tools"
alias tools3="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/tools3"
alias csgg="cleanstu && stu && dush && gg"
alias ubuvm="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup"
alias nubuvm="n /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup"





alias bgitgo="fixd && stu && dush && cleanstu && bbb && gitgo"
alias fullgg="cc && stu && dush && cleanstu && dush && gg"

alias screen="psw -command screen"
alias rmps="rmp && screen"
alias late="cd \"\$(find /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/TUVTECH/ -maxdepth 18 -type d -printf '%T@ %p\n' | command sort -n -r | head -1 | cut -d' ' -f2-)\""


alias tgi="tgpt -i"
alias getg="curl -sSL https://raw.githubusercontent.com/aandrew-me/tgpt/main/install | bash -s /usr/local/bin"
alias bigitgo="fixd && stu && dush && fullgg && backitup && gitgo"


alias cdr="cd /mnt/f/study/Dev_Toolchain/programming/r"
alias getr="sudo apt ins tall -y libcurl4-openssl-dev libsodium-dev libssl-dev libxml2-dev dirmngr gnupg apt-transport-https ca-certificates software-properties-common && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && yes  | sudo add-apt-repository deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/ && sudo apt install -y r-base && R --version && cd && wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb && sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb"
alias apis="cd /mnt/f/study/Dev_Toolchain/programming/APIs/ObtainKeys"
alias getchrome="cd && wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb && sudo apt install -y chromium-chromedriver && sudo apt-get install -y libnss3 libgconf-2-4 && sudo apt-get install -y libnss3 libgconf-2-4 && cc && which chromedriver"
alias folders="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/folders && ls"
alias shms="cd /mnt/f/study/Devops/automation/SmarthomeManagementSystems"
alias proxrc="nano /mnt/f/study/virtualmachines/proxmox/bashrc.txt"
alias ssure="cd /mnt/f/study/Security_Networking/Hacking/surveillance"
alias scri="cd /mnt/f/study/shells/bash/scripts"


alias smqtt="cd /mnt/f/study/disturbed/MQTT_Brokers"
alias ..="cd .."
alias space="bash /mnt/f/study/shells/bash/scripts/remove_spaces.sh"
alias latest="bash /mnt/f/study/shells/bash/scripts/latest_file_fullpath.sh"
alias disdat="cd /mnt/f/study/disturbed/disturbed_database"
alias sdm="cd /mnt/f/study/Download_Managers"
alias cpb='cp -r "$(ls -t | head -n 1)" /mnt/f/study/shells/bash/scripts'
alias cc="clear"
alias mk="mkdir"
alias ex="exit"
alias ns="n a.sh"
alias as="./a.sh"
alias prox="gc http://192.168.1.222:8006/"
alias py="python3"
export LS_COLORS="di=34:fi=32:ln=36"
alias ls="ls --color=always"
alias str="cd /mnt/f/study/streaming"
alias scf="cd /mnt/f/study/cloud/cloudflare"

alias sdash="cd /mnt/f/study/hosting/dashboard"
alias ee="explorer.exe ."

alias rmso="rmsources && updates"
alias ccl="cc && ls"
alias croot="rm -rf /root/* && cd && ccl"
alias snotes="cd /mnt/f/study/ide/Notes"

alias np="n a.py"
alias sdata="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases"
alias ssql="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql"
alias snosql="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/nosql"

alias smedia="cd /mnt/f/study/hosting/MediaServers"
alias cpo="cp -r EnableGuestAccessforNetworkSharing.ps1 /mnt/f/study/Devops/automation/oneliners"
alias cps="cp -r EnableGuestAccessforNetworkSharing.ps1 /mnt/f/study/setups"
alias cpd="cp -r EnableGuestAccessforNetworkSharing.ps1 /mnt/f/study/containers/docker/guides"
alias getkaggle="venv &&  mkdir -p ~/.kaggle && mv /mnt/f/backup/windowsapps/Credentials/kaggle/kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json && kaggle competitions list"


alias sfs="cd /mnt/f/study/networking/FileSharing"
alias cdftp="cd /mnt/f/study/networking/FileSharing/ftp"
alias mkc="f() { mkdir -p \"\$1\" && cd \"\$1\"; }; f"
alias nano="n"
alias ll="bash /mnt/f/study/shells/bash/scripts/linershortcut.sh"
alias lb="bash /mnt/f/study/shells/bash/scripts/bashshortcut.sh"
copy() {
    apt install xclip -y
    # Enable alias expansion in the function
    shopt -s expand_aliases
    # Re-run the provided command with alias expansion and pipe to xclip
    eval "$*" | xclip -selection clipboard
    echo "Output of '$*' copied to clipboard."
}


alias crotn="croot && nsa"
alias nsa="ns && as"
alias crotp="croot && np && pya"
alias pdlf="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/DataPipeLineFramework"
alias ggbbb="fullgg && bbb"

alias getnix=" sh <(curl -L https://nixos.org/nix/install) --daemon"
alias vs="yes | code --no-sandbox --user-data-dir=."
alias cd3d="cd /mnt/f/study/hosting/3Dprint"
alias lps="bash /mnt/f/study/shells/bash/scripts/linershortcutps.sh"
alias bigo="fixd && stu && dush && fullgg && backitup"
alias rmpro="sudo apt-get remove --purge ubuntu-advantage-tools -y && sudo rm /etc/apt/apt.conf.d/20apt-esm-hook.conf && remove && clean"


alias ab="abiword *.docx"
alias ds="docker search"
alias runab="getab && down && ab"
alias storrent="cd /mnt/f/study/networking/torrents"
alias sse="cd /mnt/f/study/search_engines/searchEngines"
alias getphp="yes | sudo apt update && yes | sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-imagick php-intl php-soap php-xmlrpc php-sqlite3 php8.1-opcache php-redis php-xdebug php-memcached php-ldap php-ds php-pspell php-tidy php-apcu php-readline php-enchant php-msgpack php-igbinary php-amqp php-http php-yaml php-mailparse php-raphf php-smbclient php-uuid php-solr php-uopz php-pcov php-gearman php-mongodb php-pgsql php-dba php-gmp php-ast php-uploadprogress php-imap && curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer && COMPOSER_ALLOW_SUPERUSER=1 composer --version"

alias lp="bash /mnt/f/study/shells/bash/scripts/linershortcutprox.sh"
alias sbus="cd /mnt/f/study/Business"
alias sfin="cd /mnt/f/study/Business/finance"
alias sceo="cd /mnt/f/study/Business/ceo"
alias spass="cd /mnt/f/study/Business/Passive_Income"
alias svis="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/visualization"
alias sgraph="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/visualization/Graphs"


alias ggbbbb="fullgg && backitup"
alias snot="cd /mnt/f/study/Notifications"
alias hint="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/hint"
alias sreverse="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/reverse_engineering"
alias sfire="cd /mnt/f/study/security/firewall"
alias fd='function _findlike() { find . -type f -iname "*$1*" 2>/dev/null; }; _findlike'

alias ucc="updates && clean"
alias sredis="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/nosql/redis"
alias sgres="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql/postgres"
alias smaria="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql/mariadb"
alias mkclp='f() { mkdir -p "$1" && cd "$1" && bash /mnt/f/study/shells/bash/scripts/linershortcutprox.sh "$1"; }; f'
alias mkcll='f() { mkdir -p "$1" && cd "$1" && bash /mnt/f/study/shells/bash/scripts/linershortcut.sh "$1"; }; f'
alias mkclps='f() { mkdir -p "$1" && cd "$1" && bash /mnt/f/study/shells/bash/scripts/linershortcutps.sh "$1"; }; f'
alias ffd='function _findlike() { find . -type d -iname "*$1*" 2>/dev/null; }; _findlike'

alias swiki="cd /mnt/f/study/documents/wiki_management_tools"
alias ssync="cd /mnt/f/study/backup/sync"
alias youapi="cat /mnt/f/backup/windowsapps/Credentials/youtube/2apikeysdata"
alias syou="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/youtube"
alias splex="cd /mnt/f/study/hosting/MediaServers/plex"

alias t="time"
alias getlib="cd && getlibssl1 &&  sudo apt install -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 libgconf-2-4 libgtk2.0-0 libatk1.0-0 libcairo2 libpango-1.0-0 libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev libxcb-xfixes0-dev libxcb-glx0-dev libxinerama1 libxcursor-dev libxi-dev libxext-dev libxmu-dev libxpm-dev libxau-dev libxdmcp-dev libuuid1 libblkid-dev libmount-dev libselinux1-dev libsepol-dev libpcre3-dev libexpat1-dev libglib2.0-dev libatk-bridge2.0-dev libepoxy-dev libdrm-dev libgbm-dev libinput-dev libwacom-dev libsystemd-dev libgraphite2-dev libfontconfig1-dev libxrender-dev libxft-dev libglu1-mesa-dev libvulkan1 libvulkan-dev libxcb-shape0-dev libxcb-keysyms1-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-randr0-dev libxcb-util0-dev libxcb-xkb-dev libxcb-xv0-dev libxcb-present-dev libxcb-dpms0-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev libxcb-record0-dev libxcb-render0-dev libxcb-res0-dev libxcb-screensaver0-dev libxcb-sync-dev libxcb-xinerama0-dev libxv-dev libappindicator3-1 libindicator3-7 libtext-affixes-perl libtext-aligner-perl libtext-ansi-util-perl libtext-asciitable-perl libtext-aspell-perl libtext-autoformat-perl libtext-bibtex-perl libtext-bibtex-validate-perl libtext-bidi-perl libtext-brew-perl libtext-charwidth-perl libtext-chasen-perl libtext-context-eitherside-perl libtext-context-perl"

 alias getfuse='sudo add-apt-repository universe && sudo apt install -y libfuse2 && sudo modprobe fuse && sudo groupadd fuse && sudo usermod -a -G fuse "$(whoami)"'

alias sips="cd /mnt/f/study/security/IPS"
alias setup_macos="docker pull sickcodes/docker-osx:latest && docker run -it --privileged -e \"DISPLAY=${DISPLAY}\" -v /tmp/.X11-unix:/tmp/.X11-unix sickcodes/docker-osx:latest"
alias srouter="cd /mnt/f/study/networking/router"
alias sml="cd /mnt/f/study/AI_and_Machine_Learning/Machine_Learning"
alias sllm="cd /mnt/f/study/AI_and_Machine_Learning/Machine_Learning/LLM"
alias sstream="cd /mnt/f/study/streaming"
alias secret="cd /mnt/f/study/security/secrets/Secret_Management"
alias ssearch="cd /mnt/f/study/search_engines/searchEngines"
alias stext="cd /mnt/f/study/ide/IDEs/TextEditors"
alias shard="cd /mnt/f/study/AI_and_Machine_Learning/hardware"


alias spi="cd /mnt/f/study/networking/ADblock/pi-hole"
sad="cd /mnt/f/study/networking/ADblock/adguard"
alias aikey="cat /mnt/f/backup/windowsapps/Credentials/openai/api.txt"
alias sopen="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/openai"
alias ppw="powershell.exe -command"


alias exai='export OPENAI_API_KEY="sk-svcacct-TiI2B_7zM1_B8PISYuPQhZTzNAtJRGvhEAtmDqCGE9VtuxGvMJBYnus_nbuoeT3BlbkFJUupZffoO1GXpkhv-o1PlCY1vrqoRdmuFSIqPt2opMT-AB1MdxfO63z6RIhX7wA" && brc2 && echo $OPENAI_API_KEY'
alias stera="cd /mnt/f/study/Devops/automation/Infrastructure_as_Code/terraform"
alias senc="cd /mnt/f/study/security/encryption"
alias sflat="cd /mnt/f/study/Shells/tools/Flatpak"
alias down="cd /mnt/c/Users/micha/Downloads && ls"

alias swsl="cd /mnt/f/study/virtualmachines/wsl2"
alias sand="cd /mnt/f/study/android"

alias getemp="apt install w3m jq -y && curl -L https://git.io/tempmail > tempmail && chmod +x tempmail && sudo mv tempmail /usr/bin/tempmail && tempmail --version"
alias sic="cd /mnt/f/study/security/IntegrityCheck"

alias path=" bash /mnt/f/study/shells/bash/scripts/cdthisPath.sh"
alias paste="xclip -selection clipboard -o"
alias sta="cd /mnt/f/study/FilesystemManagement/taskmanager"

alias pasterc="xclip -selection clipboard -o >> /mnt/c/Users/micha/Desktop/alias.txt && echo >> /mnt/c/Users/micha/Desktop/alias.txt"
alias copyp="copy path && paste"
alias san="cd /mnt/f/study/android"
scpubu() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: scpubu <source_path>"
        return 1
    fi

    local source_path="$1"
    local remote_user="ubuntu"
    local remote_host="192.168.1.193"
    local remote_path="/home/ubuntu"
    local password="123456"

    # Use sshpass to provide password and disable host key checking
    sshpass -p "$password" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r "$source_path" "${remote_user}@${remote_host}:${remote_path}"
}
alias ppsw="psw -command"
alias tunnel="cd /mnt/f/study/hosting/tunneling"
alias sng="cd /mnt/f/study/hosting/tunneling/ngrok"
alias sen="cd /mnt/f/study/security/endpoint"
alias dsubs="ppsw dsubs"
alias ste="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/terminalAI"
alias gmail2="gc https://mail.google.com/mail/u/1/#inbox"
alias mym="copy mymail"
alias napi="n api.txt"
alias runjup="getjup && down && jup"
alias getzep="bash /mnt/f/study/shells/bash/scripts/get_zeppelin.sh"
alias mypass="cat /mnt/f/backup/windowsapps/Credentials/mypass/mypass"
alias mpass="copy mypass"
alias runvs="getvs && down && vs *.ipynb"
alias getnvm='curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
alias nvmv="nvm ls-remote"
alias mvd="mv /mnt/f/Downloads/* ."
alias getai="nvm22 && npm install -g @callstack/ai-cli && exai && cc && aikey && ai init && ai"


alias getgo10="wget https://go.dev/dl/go1.10.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.10.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo11="wget https://go.dev/dl/go1.11.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.11.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo12="wget https://go.dev/dl/go1.12.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo13="wget https://go.dev/dl/go1.13.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.13.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo14="wget https://go.dev/dl/go1.14.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.14.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo15="wget https://go.dev/dl/go1.15.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.15.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo16="wget https://go.dev/dl/go1.16.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.16.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo17="wget https://go.dev/dl/go1.17.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo18="wget https://go.dev/dl/go1.18.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo19="wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo20="wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo21="wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo22="wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"
alias getgo23="wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz && echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc && source ~/.bashrc && go version"


alias sets="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets"
alias dsets="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets/DownloadDatasets"
alias lds="bash  /mnt/f/study/shells/bash/scripts/linershortcutDB.sh"
alias mvdoc="shopt -s nullglob; mv /mnt/f/Downloads/*.docx . 2>/dev/null; mv /mnt/f/Downloads/*.html . 2>/dev/null; mv /mnt/f/Downloads/*.txt . 2>/dev/null; mv /mnt/f/Downloads/*.ipynb . 2>/dev/null; mv /mnt/f/Downloads/*.py . 2>/dev/null; mv /mnt/f/Downloads/*.pdf . 2>/dev/null; shopt -u nullglob && ls"
alias bar="ppsw bar"
alias audio="ppsw audio"
alias gkaggle="venv && pip install kaggle && mkdir -p ~/.kaggle && cp /mnt/f/backup/windowsapps/Credentials/kaggle/kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json && kaggle datasets list && kaggle datasets download -d"


alias dkag="kaggle datasets download -d"
alias nins="npm install && npm start"


alias gkag="venv && pip install kaggle && mkdir -p ~/.kaggle && cp /mnt/f/backup/windowsapps/Credentials/kaggle/kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json && kaggle datasets list"
alias java8="apt install -y openjdk-8-jdk openjdk-8-jre openjdk-8-source openjdk-8-jre-headless openjdk-8-jdk-headless openjdk-8-jre-zero openjdk-8-dbg openjdk-8-demo openjdk-8-doc && java --version"
alias java11="apt install -y openjdk-11-jdk openjdk-11-jre openjdk-11-source openjdk-11-jre-headless openjdk-11-jdk-headless openjdk-11-jre-zero openjdk-11-dbg openjdk-11-demo openjdk-11-doc && java --version"
alias java17="apt install -y openjdk-17-jdk openjdk-17-jre openjdk-17-source openjdk-17-jre-headless openjdk-17-jdk-headless openjdk-17-jre-zero openjdk-17-dbg openjdk-17-demo openjdk-17-doc && java --version"
alias java18="apt install -y openjdk-18-jdk openjdk-18-jre openjdk-18-source openjdk-18-jre-headless openjdk-18-jdk-headless openjdk-18-jre-zero openjdk-18-dbg openjdk-18-demo openjdk-18-doc && java --version"
alias java19="apt install -y openjdk-19-jdk openjdk-19-jre openjdk-19-source openjdk-19-jre-headless openjdk-19-jdk-headless openjdk-19-jre-zero openjdk-19-dbg openjdk-19-demo openjdk-19-doc && java --version"
alias java21="apt install -y openjdk-21-jdk openjdk-21-jre openjdk-21-source openjdk-21-jre-headless openjdk-21-jdk-headless openjdk-21-jre-zero openjdk-21-dbg openjdk-21-demo openjdk-21-doc openjdk-21-testsupport && java --version"
alias getflat="sudo apt install -y flatpak && sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && sudo apt install -y --reinstall libglib2.0-0 libglib2.0-bin libglib2.0-data && sudo apt install -y libglib2.0-dev && sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ && flatpak repair && flatpak install -y flathub org.gnome.Platform//44 && flatpak --version"
alias liners="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners"

alias nshell="exec $SHELL"
alias gpro="bash /mnt/f/study/Shells/powershell/scripts/enable_ubuntu_pro.sh"

alias getsnap="sudo apt install snapd -y && updates && sudo systemctl enable --now snapd.apparmor && sudo ln -s /var/lib/snapd/snap /snap && sudo systemctl start snapd && sudo snap install core && sudo snap install gnome-3-28-1804 && sudo snap install gtk-common-themes && sudo cp /lib/systemd/system/snapd.service /lib/systemd/system/snapd.service.bak && sudo sed -i s/^RestartMode=/Restart=/ /lib/systemd/system/snapd.service && sudo systemctl daemon-reload && sudo systemctl restart snapd"

alias sdat="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets/DownloadDatasets"
alias cdbs="bash /mnt/f/study/shells/bash/scripts/bashthisPath.sh"
alias 10latest="bash /mnt/f/study/shells/bash/scripts/latest_file_fullpath10.sh"
alias copyb="copy cdbs && paste"
alias game="venv && py /mnt/f/backup/windowsapps/installed/myapps/compiled_python/howlongtobeat_dataset/a.py"
alias mkclds='f() { mkdir -p "$1" && cd "$1" && bash /mnt/f/study/shells/bash/scripts/linershortcut.sh "$1"; }; f'
alias rkag="gkag && dkag"
alias caikey="copy aikey"
alias gtc="git clone"
alias svs="cd /mnt/f/study/IDE/IDEs/VScode"

alias convertico="sudo apt install imagemagick && convert -resize x16 -gravity center -crop 16x16+0+0 a.{png,jpg} -flatten -colors 256 -background transparent a.ico"
alias srun="streamlit run"
alias summ="venv && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/youtube/youtube_summarizer && exai && py a.py"
alias glare="bash /mnt/f/study/shells/bash/scripts/getcloudflard.sh"
alias gmail3="gc https://mail.google.com/mail/u/2/#inbox"
alias gngrok="curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs=22.1.0-1nodesource1 && npm install -g npm@latest && node -v && npm -v && npm install -g ngrok && ngrok -v && ngrok config add-authtoken 2qcNPrautgOBIKkgwDb2W6g8oCe_5c2XSNffF6q2y15eTMUcC"
alias sext="cd /mnt/f/study/browsers/extensions/MadeByME"
alias rmjava="sudo apt-get purge --auto-remove -y openjdk* oracle-java* && rm -rf ~/.java ~/.config/java ~/.cache/java && sudo rm -rf /usr/lib/jvm /usr/bin/java /usr/bin/javac /usr/share/java /usr/share/man/man1/java.* && sudo update-alternatives --remove-all java && sudo update-alternatives --remove-all javac && sudo apt-get autoremove -y && sudo apt-get autoclean"
alias rmnvm="sudo apt-get purge --auto-remove -y nodejs npm && [ -d ~/.nvm ] && rm -rf ~/.nvm && [ -d ~/.npm ] && rm -rf ~/.npm && [ -d ~/.node_modules ] && rm -rf ~/.node_modules && [ -d /usr/local/lib/node_modules ] && sudo rm -rf /usr/local/lib/node_modules && [ -f /usr/local/bin/node ] && sudo rm -f /usr/local/bin/node && [ -f /usr/local/bin/npm ] && sudo rm -f /usr/local/bin/npm && [ -f /usr/local/bin/npx ] && sudo rm -f /usr/local/bin/npx && sudo apt-get autoremove -y && sudo apt-get autoclean"
alias timers="sudo systemctl list-timers daily_task.timer --all"
alias subit="bash /mnt/f/study/shells/bash/scripts/dailytask.sh"



alias bleach=" apt install bleachbit -y && bleachbit"
alias downit="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/downit"
alias rmlibre="sudo apt purge --remove libreoffice* -y && sudo apt autoremove --purge -y && sudo apt autoclean"
alias keyrok="cat /mnt/f/backup/windowsapps/Credentials/ngrok/*"
alias kport="function _kport() { sudo kill -9 \$(sudo lsof -t -i:\$1); }; _kport"
alias lmvr="latemv && rmd"
alias skag="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets/DBdownloaders/kaggle"
alias copyrcn="copyrc && nalias"
alias dbdown="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets/DBdownloaders"
alias nvm0="getnvm && nvm install v0.10.48 && nvm use v0.10.48 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm1="getnvm && nvm install iojs-v1.8.4 && nvm use iojs-v1.8.4 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm2="getnvm && nvm install iojs-v2.5.0 && nvm use iojs-v2.5.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm3="getnvm && nvm install iojs-v3.3.1 && nvm use iojs-v3.3.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm4="getnvm && nvm install v4.9.1 && nvm use v4.9.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm5="getnvm && nvm install v5.12.0 && nvm use v5.12.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm6="getnvm && nvm install v6.17.1 && nvm use v6.17.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm7="getnvm && nvm install v7.10.1 && nvm use v7.10.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm8="getnvm && nvm install v8.17.0 && nvm use v8.17.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm9="getnvm && nvm install v9.11.2 && nvm use v9.11.2 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm10="getnvm && nvm install v10.24.1 && nvm use v10.24.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm11="getnvm && nvm install v11.15.0 && nvm use v11.15.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm12="getnvm && nvm install v12.22.12 && nvm use v12.22.12 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm13="getnvm && nvm install v13.14.0 && nvm use v13.14.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm14="getnvm && nvm install v14.21.3 && nvm use v14.21.3 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm15="getnvm && nvm install v15.14.0 && nvm use v15.14.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm16="getnvm && nvm install v16.20.2 && nvm use v16.20.2 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm17="getnvm && nvm install v17.9.1 && nvm use v17.9.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm18="getnvm && nvm install v18.20.5 && nvm use v18.20.5 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm19="getnvm && nvm install v19.9.0 && nvm use v19.9.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm20="getnvm && nvm install v20.18.1 && nvm use v20.18.1 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm21="getnvm && nvm install v21.7.3 && nvm use v21.7.3 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm22="getnvm && nvm install v22.12.0 && nvm use v22.12.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias nvm23="getnvm && nvm install v23.4.0 && nvm use v23.4.0 && node -v && npm install -g npm@latest && npm -v && nvm -v"
alias uz="apt install zip unzip -y"
alias rmphp="sudo apt purge php* -y && sudo apt autoremove -y"
alias heavy="cd /mnt/wslg && top100 && apt-mark showmanual"
alias purgeit='function _purgeit() { sudo apt-get purge -y "$1" && sudo apt-get autoremove --purge -y && sudo apt-get autoclean; }; _purgeit'
alias hpurge='function _purgeit() { sudo apt-get purge -y "$1" && sudo apt-get autoremove --purge -y && sudo apt-get autoclean; }; _purgeit && heavy'
kags() { kaggle datasets list -s "$1" --sort-by votes; }
gclone() { git clone "$1" && cd "$(basename "$1" .git)"; }
function addalias {
    # Get the last command without the number
    cmd=$(history | tail -n 2 | head -n 1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')

    # Create a temporary file
    temp_file=$(mktemp)

    # Write the new command first
    echo "$cmd" > "$temp_file"

    # Append the existing content
    cat "/mnt/c/Users/micha/Desktop/alias.txt" >> "$temp_file"

    # Replace the original file with the new content
    mv "$temp_file" "/mnt/c/Users/micha/Desktop/alias.txt"
}
function dalias { sed -i '$ d' /mnt/c/Users/micha/Desktop/alias.txt; }
alias spxe="cd /mnt/f/study/networking/PXE"
alias catit="bash /mnt/f/study/shells/bash/scripts/catthisPath.sh"
alias copyc="copy catit && paste"
alias repo="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/repo"

alias display="ppsw display"
alias claude="gc https://claude.ai/new"
alias lclaude="gc https://claude.ai/logout"
alias output="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/output"
alias copycrc="copy catit && pasterc && nalias"
alias copyrc="copy path && pasterc && nalias"
alias sub="ppsw sub"
alias fix="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/fix && paste"
alias end="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/end"
alias de2="ppsw de2"
alias de1="ppsw de1"
alias latest5="bash /mnt/f/study/shells/bash/scripts/5latest.sh"
alias copybrc="copyb && pasterc && nalias"
alias adalias="addalias && nalias"
alias fire="ppsw fire"
alias refire="ppsw refire"
alias fxs="ppsw fxs"
alias ghs="venv && python /mnt/f/study/Dev_Toolchain/programming/python/apps/scrapers/githubScraper/a.py"
alias getngrok="nvm20 && node -v && npm -v && npm install -g ngrok && ngrok -v && ngrok config add-authtoken 2qcNPrautgOBIKkgwDb2W6g8oCe_5c2XSNffF6q2y15eTMUcC"
alias vnp="venv && pya"


alias bst="ppsw bst"
alias stensor="cd /mnt/f/study/AI_and_Machine_Learning/DeepLearning/FrameWorks/tensorflow"
alias liner="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liner"
alias stravel="cd /mnt/f/study/Travel"
alias stermux="cd /mnt/f/study/Platforms/Android/termux"
alias sshh="gc https://b963-87-70-59-247.ngrok-free.app/"
alias latest2="ppsw latest"
alias downloadable="cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/downloadable"
alias getgo23="/mnt/f/study/shells/bash/scripts/getgo23.sh"
alias swenh="cd /mnt/f/study/hosting/WebHosting"
alias gggg="(stu && dush && cleanstu && dush && gg)"
alias ginfluxdb=" sudo apt-get install influxdb influxdb-client -y && sudo systemctl enable influxdb && sudo systemctl start influxdb && wget https://dl.influxdata.com/chronograf/releases/chronograf_1.10.6_amd64.deb && sudo dpkg -i chronograf_1.10.6_amd64.deb && sudo systemctl start chronograf && sudo systemctl enable chronograf"
alias brc="gedit ~/.bashrc &"

alias clap="ppsw clap"
alias getgo22="bash /mnt/f/study/shells/bash/scripts/getgo22.sh"
alias getgo21="bash /mnt/f/study/shells/bash/scripts/getgo21.sh"
alias getgo20="bash /mnt/f/study/shells/bash/scripts/getgo20.sh"
alias getgo19="bash /mnt/f/study/shells/bash/scripts/getgo19.sh"
alias getgo18="bash /mnt/f/study/shells/bash/scripts/getgo18.sh"
alias getgo17="bash /mnt/f/study/shells/bash/scripts/getgo17.sh"
alias getgo16="bash /mnt/f/study/shells/bash/scripts/getgo16.sh"
alias getgo15="bash /mnt/f/study/shells/bash/scripts/getgo15.sh"
alias getgo14="bash /mnt/f/study/shells/bash/scripts/getgo14.sh"
alias getgo12="bash /mnt/f/study/shells/bash/scripts/getgo12.sh"
alias getgo11="bash /mnt/f/study/shells/bash/scripts/getgo11.sh"
alias getgo10="bash /mnt/f/study/shells/bash/scripts/getgo10.sh"
alias getgo8="bash /mnt/f/study/shells/bash/scripts/getgo8.sh"
alias getgo9="bash /mnt/f/study/shells/bash/scripts/getgo9.sh"
alias getgo13="bash /mnt/f/study/shells/bash/scripts/getgo13.sh"
alias getgo4="bash /mnt/f/study/shells/bash/scripts/getgo4.sh"
alias getgo3="bash /mnt/f/study/shells/bash/scripts/getgo3.sh"
alias getgo2="bash /mnt/f/study/shells/bash/scripts/getgo2.sh"
alias getgo1="bash /mnt/f/study/shells/bash/scripts/getgo1.sh"
alias getgo5="bash /mnt/f/study/shells/bash/scripts/getgo5.sh"
alias getgo7="bash /mnt/f/study/shells/bash/scripts/getgo7.sh"
alias getgo6="bash /mnt/f/study/shells/bash/scripts/getgo6.sh"

alias gkernal="cd ~ && sudo apt install -y build-essential flex bison dwarves libssl-dev libelf-dev cpio && git clone https://github.com/microsoft/WSL2-Linux-Kernel.git && cd WSL2-Linux-Kernel && make KCONFIG_CONFIG=Microsoft/config-wsl && sudo apt install build-essential flex bison dwarves libssl-dev libelf-dev cpio -y && sudo apt-get install -y linux-headers-generic && sudo apt install --install-recommends linux-generic-hwe-22.04 -y && sudo apt install -y linux-tools-common linux-tools-generic build-essential libelf-dev htop sysstat iotop iftop net-tools iproute2 lsof bpfcc-tools linux-cloud-tools-common 2>/dev/null"
alias streamlit="streamlit run a.py"
alias rmapparmor="purgeit apparmor"
alias summ="venv && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/youtube/youtube_summarizer/C &&  exai && streamlit"
alias clean="bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu.sh"

alias plexkey="cat /mnt/f/backup/windowsapps/Credentials/plex/token.txt"
alias getdocker="bash /mnt/f/study/shells/bash/scripts/getdocker.sh"
alias swinget="cd /mnt/f/study/Shells/powershell/winget"
alias rmn='f() { rm "$1" && n "$1"; }; f'

alias alert="  for i in {1..10}; do echo -e '\a'; sleep 0.3; done"
alias gg="cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && alert"
alias ggg="(cd /mnt/f/study && docker build -t michadockermisha/backup:study . > /dev/null 2>&1 && docker push michadockermisha/backup:study > /dev/null 2>&1 && for i in {1..10}; do echo -e a; sleep 0.3; done) &"
alias gitgo="/mnt/f/backup/windowsapps/Credentials/Gitgo/AutoGitgo.sh && alert"

alias myp="copy mypass && paste"

alias gptbot="apt install python3-pip -y && pip install undetected_chromedriver fake_useragent selenium webdriver_manager && getchrome && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/bots/chatGPTbot/automateAnswerAndSend && py e.py"
alias sbrc="bash '/mnt/f/study/shells/bash/scripts/update_bashrc.sh'"

alias gssh="sudo apt-get install -y openssh-server && sudo systemctl start ssh && sudo systemctl enable ssh && sudo systemctl status ssh"
alias gngrok="nvm20 && npm install -g npm@latest && node -v && npm -v && npm install -g ngrok && ngrok -v && ngrok config add-authtoken 2qcNPrautgOBIKkgwDb2W6g8oCe_5c2XSNffF6q2y15eTMUcC"
alias semu="cd /mnt/f/study/emulation"
alias spl="cd /mnt/f/study/Platforms"

alias spl="cd /mnt/f/study/Platforms"

alias cpdfdocx='cdocx && pip install PyPDF2 && stu && dush && py /mnt/f/study/Dev_Toolchain/programming/python/apps/shrink/pdf/pdfShrinkcurrentPathWithsubFolders.py && dush'
alias cdocx='apt install python3-pip -y && pip install python-docx Pillow && stu && py /mnt/f/study/Dev_Toolchain/programming/python/apps/shrink/docx/docxShrinkcurrentPathWithsubFolders.py'
alias 10000="cd && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/g.py /root/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pip install pandas PyQt5 && pya"
alias tit="copy title && paste"
alias out="copy output && paste"
alias sand="cd /mnt/f/study/Platforms/android"

alias venv=' sudo apt install python3-venv -y && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd '
alias subs='apt install python3-pip -y && pip install google_auth_oauthlib google-api-python-client && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/youtube/Playlists/substoplaylist && py h.py'
alias 10000='cd && apt install python3-pip -y && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/g.py /root/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pip install pandas PyQt5 && pya'
alias slinux="cd /mnt/f/study/Platforms/linux"
alias sbe="cd /mnt/f/study/AI_and_Machine_Learning/benchmark"
alias swin="cd /mnt/f/study/Platforms/windows"

alias saudio='cd /mnt/c/users/micha/videos/audiobooks &&  docker run --rm -v /mnt/c/users/micha/videos/audiobooks:/backup michadockermisha/backup:audiobooks sh -c "apk update && apk add --no-cache rsync && rsync -av /home/* /backup" && docker build -t michadockermisha/backup:audiobooks . &&  docker push michadockermisha/backup:audiobooks &&  rm -rf /mnt/c/Users/micha/videos/audiobooks/*'
alias slinux="cd /mnt/f/study/Platforms/linux"
alias sbe="cd /mnt/f/study/AI_and_Machine_Learning/benchmark"
alias swin="cd /mnt/f/study/Platforms/windows"

alias gicloud='sudo apt update && sudo apt install -y python3-pip python3-dev libssl-dev libffi-dev build-essential && pip3 install icloudpd && mkdir -p ~/iCloud && icloudpd --directory ~/iCloud --username "michaelovsky55@gmail.com" --password "Blackablacka3!" --no-progress-bar'
alias sbook="cd /mnt/c/users/micha/videos/audiobooks"
alias gaudio='cd /mnt/c/users/micha/videos/audiobooks &&  docker run --rm -v /mnt/c/users/micha/videos/audiobooks:/backup michadockermisha/backup:audiobooks sh -c "apk update && apk add --no-cache rsync && rsync -av /home/* /backup" && docker build -t michadockermisha/backup:audiobooks . &&  docker push michadockermisha/backup:audiobooks'

alias compress="uz && 7z a -mx=9 workspace_compressed.7z"
alias uz='apt install zip unzip p7zip-full -y'
alias rmss="rmf /mnt/f/Downloads/*screenshot*"
alias gx11="apt install x11-apps -y && export DISPLAY=:0 && export LIBGL_ALWAYS_INDIRECT=1"
alias sme="cd /mnt/f/study/MediaEditing"
alias svi="cd /mnt/f/study/MediaEditing/VideoEditing"
alias sau="cd /mnt/f/study/MediaEditing/AudioEditing"
alias spara="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/Parallel_computing"

alias 10000='cd && apt install python3-pip -y && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/i.py /root/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pip install pandas PyQt5 && pya'
alias rmfo="find . -mindepth 1 -type d -exec rm -rf {} +"
alias ssnap="cd /mnt/f/study/Shells/tools/Package_Manager/snap"

alias addl='find /mnt/f/study -type f -name "*liner*" -exec sh -c '\''
    filename=$(basename "{}")
    if [ ! -f "/mnt/f/study/Devops/automation/oneliners/$filename" ]; then
        cp "{}" "/mnt/f/study/Devops/automation/oneliners/"
        echo "Copied: $filename"
    else
        echo "Skipped existing file: $filename"
    fi
'\'' \;'

alias addps='find /mnt/f/study -type f -name "*.ps1" -exec sh -c '\''
    filename=$(basename "{}")
    if [ ! -f "/mnt/f/study/shells/powershell/scripts/$filename" ]; then
        cp "{}" "/mnt/f/study/shells/powershell/scripts/"
        echo "Copied: $filename"
    else
        echo "Skipped existing file: $filename"
    fi
'\'' \;'

alias addsh='find /mnt/f/study -type f -name "*.sh" -exec sh -c '\''
    filename=$(basename "{}")
    if [ ! -f "/mnt/f/study/shells/bash/scripts/$filename" ]; then
        cp "{}" "/mnt/f/study/shells/bash/scripts/"
        echo "Copied: $filename"
    else
        echo "Skipped existing file: $filename"
    fi
'\'' \;'

alias addsnap='find /mnt/f/study -type f -name "*snap*" -exec sh -c '\''
    filename=$(basename "{}")
    if [ ! -f "/mnt/f/study/Shells/tools/Package_Manager/snap/$filename" ]; then
        cp "{}" "/mnt/f/study/Shells/tools/Package_Manager/snap/"
        echo "Copied: $filename"
    else
        echo "Skipped existing file: $filename"
    fi
'\'' \;'

alias addse='find /mnt/f/study -type f -name "*setup*" -exec sh -c '\''
    filename=$(basename "{}")
    if [ ! -f "/mnt/f/study/setups/$filename" ]; then
        cp "{}" "/mnt/f/study/setups/"
        echo "Copied: $filename"
    else
        echo "Skipped existing file: $filename"
    fi
'\'' \;'

alias addall="addse && addsnap && addsh && addps && addl"

alias fullgg='addll && cc && stu && dush && cleanstu && dush && gg'
alias myg='apt install python3-pip && pip install PyQt5 && py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/5.py'
alias dus='psw dush'
alias getf="sudo mkdir -p /mnt/f && sudo mount -t drvfs F: /mnt/f && cd /mnt/f"
alias 20000='apt install python3-pip -y && pip install pandas PyQt5 && cd ~ && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/a.py ~/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/watched_tv_shows.db ~/watched_tv_shows.db && wget -q https://datasets.imdbws.com/title.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.ratings.tsv.gz && wget -q https://datasets.imdbws.com/title.crew.tsv.gz && wget -q https://datasets.imdbws.com/title.principals.tsv.gz && wget -q https://datasets.imdbws.com/name.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.episode.tsv.gz && wget -q https://datasets.imdbws.com/title.akas.tsv.gz && python3 a.py'
alias myg='pyp && pip install PyQt5 && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 7.py'
alias cdf="cd /mnt/f"
alias pyp="apt install python3-pip -y"
alias fullgg='addall && cc && stu && dush && cleanstu && dush && gg'
alias sen="cd /mnt/f/study/security/encryption"

alias sfil="psw sfil"
alias sfol="psw sfol"
alias capi="cat api.txt"
alias napi="n api.txt"
alias gkag='pip install kaggle && mkdir -p ~/.kaggle && cp /mnt/f/backup/windowsapps/Credentials/kaggle/kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json && kaggle datasets list'
alias kagd="kaggle datasets download"
alias sro="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/Robotics"

alias scert="cd /mnt/f/study/security/CertificateManagement"

alias sco="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/ComputerVision"
alias scoc="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/CodeCoverage"
alias sflu="cd /mnt/f/study/Dev_Toolchain/programming/Flutter"
alias gflu='cd ~ && mkdir -p /root/flutter_project && cd /root/flutter_project && wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.6-stable.tar.xz && tar -xf flutter_linux_3.10.6-stable.tar.xz && export PATH="/root/flutter_project/flutter/bin:$PATH" && git config --global --add safe.directory /root/flutter_project/flutter && flutter config --no-analytics && yes | flutter doctor --android-licenses && flutter doctor && flutter --version'
alias sdatasets="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/datasets"
alias sbase="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases"
alias ssq="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql/sqlite"


alias game='py /mnt/f/backup/windowsapps/installed/myapps/compiled_python/howlongtobeat_dataset/howlongtobeat_dataset/a.py'
alias 20000='apt install python3-pip -y && pip install pandas PyQt5 && cd ~ && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/b.py ~/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/tv/watched_tv_shows.db ~/watched_tv_shows.db && wget -q https://datasets.imdbws.com/title.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.ratings.tsv.gz && wget -q https://datasets.imdbws.com/title.crew.tsv.gz && wget -q https://datasets.imdbws.com/title.principals.tsv.gz && wget -q https://datasets.imdbws.com/name.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.episode.tsv.gz && wget -q https://datasets.imdbws.com/title.akas.tsv.gz && python3 a.py'
alias 10000='cd && apt install python3-pip -y && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/j.py /root/a.py && cp /mnt/f/study/projects/data_analysis/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pip install pandas PyQt5 && pya'
alias rmdocker='sudo mount -o remount,rw /mnt/wslg/distro && lsof +D /var/lib/docker && systemctl stop docker && rm -rf /var/lib/docker && sudo rm -rf /mnt/wslg/distro/var/lib/docker/layout2 &&  sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose-plugin && sudo apt-get autoremove -y --purge && sudo rm -rf /var/lib/docker /etc/docker && sudo rm /etc/apparmor.d/docker && sudo groupdel docker && sudo rm -rf /var/run/docker.sock'
alias getdocker='bash /mnt/f/study/shells/bash/scripts/getdocker.sh && gcompose'
alias rprox="rmn /mnt/f/study/virtualmachines/proxmox/bashrc.txt"
alias snlp="cd /mnt/f/study/AI_and_Machine_Learning/Machine_Learning/NLP"

alias gwine='sudo dpkg --add-architecture i386 && sudo apt-get update && sudo apt-get install -y wine32 wine64 winetricks winbind libnss-mdns:i386 libnss-mdns && mkdir -p ~/.wine32 ~/.wine64 && WINEARCH=win32 WINEPREFIX=~/.wine32 winecfg && WINEARCH=win64 WINEPREFIX=~/.wine64 winecfg && function wineapp { file "$1" | grep -q "PE32 executable" && (export WINEPREFIX=~/.wine32 && WINEARCH=win32 && wine "$1") || (file "$1" | grep -q "PE32+ executable" && (export WINEPREFIX=~/.wine64 && WINEARCH=win64 && wine "$1")) || echo "Error: Unknown application type"; } && export -f wineapp'
alias spdf="cd /mnt/f/study/documents/pdf"

alias sfs="cd /mnt/f/study/FilesystemManagement/FileSharing"
alias semu='cd /mnt/f/study/emulation/games'
alias sfed="cd /mnt/f/study/Platforms/linux/fedora"
alias sdisk="cd /mnt/f/study/shells/bash/disk"
alias s3d="cd /mnt/f/study/hosting/3Dprint"
alias splayer="cd /mnt/f/study/hosting/MediaPlayers"
alias game='apt install python3-pip -y && pip install youtube_search bs4 requests pandas && py /mnt/f/backup/windowsapps/installed/myapps/compiled_python/howlongtobeat_dataset/howlongtobeat_dataset/a.py'
alias sgaming="cd /mnt/f/study/hosting/gaming"
alias sbots="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/openai/MyBots"
alias sxs="cd /mnt/f/study/remote/Xservers"

alias heavy='cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias ccc="/mnt/f/study/shells/bash/scripts/AptPackages.sh"
alias gpip="apt install python3-pip -y"
alias liner='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liner'
alias good="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/RemakeDownloadable"
alias uapp="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/upgradeapp"
alias spar="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/ParallelCodeAnalysis"

alias title='copy echo '\''remake all steps... add big long title for the tutorial... make sure the topic and tools in the tutori al are mentioned in the title'\'''
alias gx11='fix11 && apt install x11-apps -y && export DISPLAY=:0 && export LIBGL_ALWAYS_INDIRECT=1'
alias fix11="sudo apt-get install --reinstall -y libqt5core5a libqt5gui5 libqt5widgets5 libqt5dbus5 libqt5x11extras5 libqt5opengl5 libqt5network5 libqt5sql5 libqt5xml5 libqt5svg5 libqt5concurrent5 libqt5script5 libqt5sql5-sqlite libqt5scripttools5 libxcb1 libxcb-xinerama0 libxcb-render0 libxcb-shape0 libxcb-xkb1 libxkbcommon-x11-0 "
alias diary="cd /mnt/f/backup/windowsapps/installed/myapps/DailyTxT && dcu"
alias diary='cd /mnt/f/backup/windowsapps/installed/myapps/DailyTxT && dcu && gc http://localhost:8765/'
alias gg='cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert'
alias ggedit="apt install gedit -y && unset WAYLAND_DISPLAY && export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0 && brc"
alias scc="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/Data_Analysis/CodeCoverage"

alias ggg='(cd /mnt/f/study && docker build -t michadockermisha/backup:study . > /dev/null 2>&1 && docker push michadockermisha/backup:study > /dev/null 2>&1 && for i in {1..10}; do echo -e a; sleep 0.3; done) && dkill &'
alias ste="cd /mnt/f/study/emulation/terminals"


alias bad="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/bad"
alias rmss30="while true; do rm -f /mnt/f/Downloads/*screenshot*; sleep 30; done &"
alias ggg10="while true; do (cd /mnt/f/study && docker build -t michadockermisha/backup:study . > /dev/null 2>&1 && docker push michadockermisha/backup:study > /dev/null 2>&1 && for i in {1..10}; do echo -e a; sleep 0.3; done) && dkill; sleep 600; done &"

# Function to search for aliases and functions containing a specific word

gbrc() {
    grep -E "$1" /root/.bashrc ~/.bashrc | grep -E "alias|function"
}

alias repo='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/repo'
alias wupdates='copy cat "/mnt/f/study//shells/powershell/scripts/windowsupdates.ps1" && cp "/mnt/f/study/shells/powershell/scripts/windowsupdates.ps1 /mnt/c/users/micha/updates.ps1"'
alias cleanwsl='copy cat "/mnt/f/study/shells/powershell/scripts/optimizewsl.ps1" && cp /mnt/f/study/shells/powershell/scripts/optimizewsl.ps1 /mnt/c/Users/micha/ccwsl.ps1'
alias echoit='copy cat /mnt/f/study/Artificial_Intelligence/prompts/project_echo_creator'
alias 100txt='copy cat /mnt/f/study/Artificial_Intelligence/prompts/create_python_code_for_100_txt_files'
alias makes='copy cat "/mnt/f/study/Artificial_Intelligence/prompts/make_script"'
alias downloadable='copy cat /mnt/f/study/Artificial_Intelligence/prompts/downloadable'
alias applied='copy cat /mnt/c/Users/micha/Desktop/applied.txt'
alias gitoken='copy cat /mnt/f/backup/windowsapps/Credentials/github/accessToken.txt'
alias hftoken='copy cat /mnt/f/backup/Credentials/huggingface/token.txt'
alias catwallet='copy cat /mnt/f/backup/windowsapps/Credentials/monero/address'
alias catwallet2='copy cat /mnt/f/backup/windowsapps/Credentials/geth/ethereumAddress.txt'
alias calias='copy cat /mnt/c/Users/micha/Desktop/alias.txt'
alias more='copy cat /mnt/f/study/Artificial_Intelligence/prompts/more'
alias 2-3='copy cat /mnt/f/study/Artificial_Intelligence/prompts/words'
alias catalias='copy cat ~/.bashrc'
alias plextoken='copy cat /mnt/f/backup/windowsapps/Credentials/plex/token.txt'
alias name='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/name_this_liner'
alias tools='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/tools'
alias tools3='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/tools3'
alias ubuvm='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup'
alias folders='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/folders && ls'
alias hint='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/hint'
alias youapi='copy cat /mnt/f/backup/windowsapps/Credentials/youtube/2apikeysdata'
alias aikey='copy cat /mnt/f/backup/windowsapps/Credentials/openai/api.txt'
alias mypass='copy cat /mnt/f/backup/windowsapps/Credentials/mypass/mypass'
alias liners='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners'
alias downit='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/downit'
alias keyrok='copy cat /mnt/f/backup/windowsapps/Credentials/ngrok/*'
alias catit='copy cat /mnt/f/study/shells/bash/scripts/catthisPath.sh'
alias repo='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/repo'
alias output='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/output'
alias fix='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/fix && paste'
alias end='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/end'
alias liner='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liner'
alias downloadable='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/downloadable'
alias plexkey='copy cat /mnt/f/backup/windowsapps/Credentials/plex/token.txt'
alias capi='copy cat api.txt'
alias good='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/RemakeDownloadable'
alias uapp='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/upgradeapp'
alias bad='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/bad'

alias clean='bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu.sh && rm -rf ./var/lib/dpkg/info/*.list ./var/lib/dpkg/info/*.md5sums ./var/lib/dpkg/info/*.triggers ./var/lib/dpkg/info/*.shlibs ./var/lib/dpkg/info/*.symbols ./var/lib/dpkg/info/*.postinst ./var/lib/dpkg/info/*.postrm ./var/lib/dpkg/info/*.preinst ./var/lib/dpkg/info/*.prerm ./var/lib/dpkg/triggers/* ./var/lib/systemd/catalog/database ./var/lib/apt/lists/* ./var/log/* ./usr/lib/file/magic.mgc'
alias heavy='rem && cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias calias='cat /mnt/c/Users/micha/Desktop/alias.txt'
alias rem="mount -o remount,rw /mnt/wslg &&  mount -o remount,rw /mnt/wslg/distro &&  mount -o remount,rw /mnt/wslg/doc"
alias heavy='rem && cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias calias='cat /mnt/c/Users/micha/Desktop/alias.txt'
alias rem="mount -o remount,rw /mnt/wslg &&  mount -o remount,rw /mnt/wslg/distro &&  mount -o remount,rw /mnt/wslg/doc"
alias top1000="/mnt/f/study/shells/bash/scripts/top1000.sh"
alias heavy='rem && cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias calias='cat /mnt/c/Users/micha/Desktop/alias.txt'
alias rem="mount -o remount,rw /mnt/wslg &&  mount -o remount,rw /mnt/wslg/distro &&  mount -o remount,rw /mnt/wslg/doc"
alias ctop1000="copy top1000"
alias top1000="apt install -y xclip && /mnt/f/study/shells/bash/scripts/top1000.sh"
alias heavy='rem && cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias calias='cat /mnt/c/Users/micha/Desktop/alias.txt'
alias rem="mount -o remount,rw /mnt/wslg &&  mount -o remount,rw /mnt/wslg/distro &&  mount -o remount,rw /mnt/wslg/doc"
alias check="rmso && cc && docker-compose -v && dps && python --version"
alias clean='bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu.sh'
alias ctop1000="copy top1000"
alias top1000="apt install -y xclip && /mnt/f/study/shells/bash/scripts/top1000.sh"
alias heavy='rem && cd /mnt/wslg && top100 && /mnt/f/study/shells/bash/scripts/AptPackages.sh'
alias calias='cat /mnt/c/Users/micha/Desktop/alias.txt'
alias rem="mount -o remount,rw /mnt/wslg &&  mount -o remount,rw /mnt/wslg/distro &&  mount -o remount,rw /mnt/wslg/doc"
alias ncdustu="apt install ncdu -y && stu && ncdu --exclude '**/TUVTECH'"
alias aar="sudo apt-get install software-properties-common -y"
alias ggc="sudo apt install -y xdg-utils && curl -fsSL https://raw.githubusercontent.com/4U6U57/wsl-open/master/wsl-open.sh -o /usr/local/bin/wsl-open && chmod +x /usr/local/bin/wsl-open && wsl-open"
alias swslg="cd /mnt/wslg"
alias check='rmso && cc && docker-compose -v && dps && python --version && disk'
alias getcuda="sudo apt-get install software-properties-common -y && sudo add-apt-repository ppa:graphics-drivers/ppa -y && sudo apt-get update && sudo apt-get install nvidia-driver-535 -y && sudo apt-get install -y nvidia-cuda-toolkit && nvidia-smi && nvcc --version"
alias getneo4j="sudo apt-get install software-properties-common -y && apt install apt-transport-https ca-certificates curl -y && curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && sudo apt-get install software-properties-common -y && add-apt-repository deb https://debian.neo4j.com stable 4.1 && apt update && apt install neo4j -y && systemctl enable neo4j.service && systemctl start neo4j.service && cypher-shell -a neo4j+s://5c52969e.databases.neo4j.io -u neo4j -p BB_RD1QfrqRop7ajXf2MHdm7njDcv_V08IKryEf7n6I"
alias getlibssl="sudo apt-get install software-properties-common -y && sudo add-apt-repository ppa:nrbrtx/libssl1 && sudo apt-get update && sudo apt install libssl1.1 -y"
alias upython="sudo apt-get install software-properties-common -y && sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt update && sudo apt install python3.13 -y && sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1"
alias getr="sudo apt-get install software-properties-common -y && sudo apt install -y libcurl4-openssl-dev libsodium-dev libssl-dev libxml2-dev dirmngr gnupg apt-transport-https ca-certificates && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && yes | sudo apt-get install software-properties-common -y && sudo add-apt-repository deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/ && sudo apt install -y r-base && R --version && cd && wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb && sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb"
alias getfuse="sudo apt-get install software-properties-common -y && sudo add-apt-repository universe && sudo apt install -y libfuse2 && sudo modprobe fuse && sudo groupadd fuse && sudo usermod -a -G fuse \"$(whoami)\""
alias getlib='cd && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install && sudo dpkg --configure -a && echo "6" | sudo -S apt update && echo "Jerusalem" | sudo -S apt install -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt install -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt install -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install && sudo dpkg --configure -a'
alias fixnet='sudo bash -c '"'"'echo -e "[network]\ngenerateResolvConf = false" > /etc/wsl.conf && rm /etc/resolv.conf && echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1" > /etc/resolv.conf'"'"' && wsl.exe --shutdown'
alias ubuvm='cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup'
alias rmss120='while true; do rm -f /mnt/f/Downloads/*screenshot*; sleep 120; done &'

lmv100() {
    while true; do
        late && cc && mv /mnt/f/Downloads/*docx* . && ls
        sleep 100
    done
}


ssgg() {
    ggg10
    rmss120
    lmv100
}
alias compress='uz && function _compress() { 7z a -mx=9 "$1.7z" "$1" && rm -rf "$1"; }; _compress'
alias dush="psw dush"
alias dus="psw dus"
alias sin="cd /mnt/f/backup/windowsapps/installed"

alias compress='uz && function _compress() { 7z a -mx=9 "$1.7z" "$1" && rm -rf "$1"; }; _compress'
alias dush="psw dush"
alias dus="psw dus"
alias sin="cd /mnt/f/backup/windowsapps/installed"

alias top1000="psw top1000"
alias top100="psw top100"
alias fixdpkg="sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old && sudo mkdir /var/lib/dpkg/info && sudo apt-get update -y && sudo apt-get install --reinstall -y $(dpkg -l | grep ^ii | awk '{print $2}')"
alias sins='cd /mnt/f/backup/windowsapps/install'
alias com='find . -type f -exec 7z a -mx=9 "{}.7z" "{}" \; -exec rm "{}" \;'
alias sdisk="cd /mnt/f/study/shells/bash/disk/Visualize disk usage statistics"
alias sterm="cd /mnt/f/study/emulation/terminals"

alias fixupdates="sudo apt-get update && sudo dpkg --configure -a && sudo apt-get install --reinstall \$(dpkg -l | awk '/^ii/ {print \$2}') -y && sudo apt-get install --reinstall docker-ce docker-ce-cli docker-buildx-plugin containerd.io docker-compose-plugin docker-ce-rootless-extras -y"
alias sdot="cd /mnt/f/study/Dev_Toolchain/programming/.net"

alias fixdpkg2="sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install --reinstall libgl1-mesa-glx libglx-mesa0 libgl1-mesa-dri mesa-vulkan-drivers libgl1-mesa-dri:i386 -y && sudo chmod 0700 /run/user/$(id -u)"
alias dcreds='cd /mnt/f/backup/windowsapps/Credentials && built michadockermisha/backup:creds . && docker push michadockermisha/backup:creds && dkill'
alias myg='pyp && pip install PyQt5 && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 8.py'
uploadit() {
    # Ensure a file or directory name is provided
    if [ -z "$1" ]; then
        echo "Usage: upload <file_or_directory_name>"
        return 1
    fi

    ITEM_NAME="$1"

    # Check if the file or directory exists
    if [ ! -e "$ITEM_NAME" ]; then
        echo "Error: '$ITEM_NAME' not found."
        return 1
    fi

    # Set the repository details
    REPO_URL="https://Michaelunkai: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@github.com/Michaelunkai/downloadables.git"
    REPO_NAME="downloadables"

    # Clone the repository if it doesn't already exist locally
    if [ ! -d "$REPO_NAME" ]; then
        git clone "$REPO_URL" "$REPO_NAME"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to clone repository."
            return 1
        fi
    fi

    # Navigate to the repository
    cd "$REPO_NAME" || {
        echo "Error: Failed to navigate to repository directory."
        return 1
    }

    # Pull the latest changes
    git pull origin main
    if [ $? -ne 0 ]; then
        echo "Error: Failed to pull latest changes."
        cd ..
        return 1
    fi

    # Copy the file or directory to the repository
    if [ -d "../$ITEM_NAME" ]; then
        cp -r "../$ITEM_NAME" .
    else
        cp "../$ITEM_NAME" .
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy '$ITEM_NAME' to repository."
        cd ..
        return 1
    fi

    # Add, commit, and push the file or directory
    git add "$ITEM_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to add '$ITEM_NAME' to git."
        cd ..
        return 1
    fi

    git commit -m "Add $ITEM_NAME"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to commit '$ITEM_NAME'. It might already be committed."
        cd ..
        return 1
    fi

    git push origin main
    if [ $? -ne 0 ]; then
        echo "Error: Failed to push '$ITEM_NAME' to remote repository."
        cd ..
        return 1
    fi

    # Return to the original directory
    cd ..

    # Display wget and PowerShell commands to download the file or directory
    echo "'$ITEM_NAME' successfully uploaded to the repository."
    echo "Use the following command to download it via wget:"
    echo "wget https://raw.githubusercontent.com/Michaelunkai/downloadables/main/$ITEM_NAME"
    echo "For PowerShell, use the following command:"
    echo "Invoke-WebRequest -Uri https://raw.githubusercontent.com/Michaelunkai/downloadables/main/$ITEM_NAME -OutFile $ITEM_NAME"
}





alias sfol='stu && psw sfol'
alias top="psw top"
alias press='uz && function _press() { find . -mindepth 1 -type d ! -name "*.7z" -exec sh -c '"'"'for dir; do [ -f "${dir%/}.7z" ] || (7z a -mx=9 "${dir%/}.7z" "$dir" && rm -rf "$dir"); done'"'"' sh {} +; find . -type f ! -name "*.7z" -exec sh -c '"'"'for file; do [ -f "${file}.7z" ] || (7z a -mx=9 "${file}.7z" "$file" && rm -f "$file"); done'"'"' sh {} +; }; _press'
alias unzipit="/mnt/f/study/shells/bash/scripts/extract_all_archives.sh"
alias fixlock='pids=$(pgrep -x dpkg); if [ -n "$pids" ]; then sudo kill -9 $pids; fi; sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/dpkg/updates/*; sudo dpkg --configure -a && sudo rm /var/lib/dpkg/lock-frontend && sudo rm /var/lib/dpkg/lock && sudo apt-get install --fix-broken'
alias smys="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql/mysql"
alias slite="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/sql/sqlite"

alias uploads="bash /mnt/f/study/shells/bash/scripts/upload2github.sh"
alias combine="/mnt/f/study/shells/bash/scripts/conbineTXTfiles.sh"
alias 3db="rmf combined.db combined.txt && combine && 2db"
alias 30000='gpip && pip install requests pandas bs4 pyqt5 && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/media/games/topgames && pya'
alias watched2='cp -r /root/watched_tv_shows.db /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000/tv'
alias watched="cp -r /root/watched_movies.db /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000"
alias 20000='apt install python3-pip -y && pip install pandas PyQt5 && cd ~ && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000/tv/b.py ~/a.py && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000/tv/watched_tv_shows.db ~/watched_tv_shows.db && wget -q https://datasets.imdbws.com/title.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.ratings.tsv.gz && wget -q https://datasets.imdbws.com/title.crew.tsv.gz && wget -q https://datasets.imdbws.com/title.principals.tsv.gz && wget -q https://datasets.imdbws.com/name.basics.tsv.gz && wget -q https://datasets.imdbws.com/title.episode.tsv.gz && wget -q https://datasets.imdbws.com/title.akas.tsv.gz && python3 a.py'
alias 10000='cd && apt install python3-pip -y && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000/j.py /root/a.py && cp /mnt/f/study/Dev_Toolchain/programming/python/apps/media/movies/top1000imdbMovies/10000/watched_movies.db /root && cd && wget https://datasets.imdbws.com/title.basics.tsv.gz && wget https://datasets.imdbws.com/title.ratings.tsv.gz && wget https://datasets.imdbws.com/title.crew.tsv.gz && wget https://datasets.imdbws.com/title.principals.tsv.gz && wget https://datasets.imdbws.com/name.basics.tsv.gz && wget https://datasets.imdbws.com/title.episode.tsv.gz && wget https://datasets.imdbws.com/title.akas.tsv.gz && pip install pandas PyQt5 && pya'
alias 2db='getsqlite && /mnt/f/study/shells/bash/scripts/convertXTtoDB.sh'
alias top2="psw top2"
alias wtc="watch -n"
alias zipit='uz && find . -type f ! -name "*.7z" | while read -r file; do 7z a -mx=9 "$file.7z" "$file" && rm -f "$file"; done'
alias stud="stu && dus ."
alias getlib='cd && sudo apt install  libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 -y &&  sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install && sudo dpkg --configure -a && echo "6" | sudo -S apt update && echo "Jerusalem" | sudo -S apt install -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt install -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt install -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install && sudo dpkg --configure -a'
alias ftime='sudo date -s "$(curl -sI http://www.google.com | grep -i "^date:" | cut -d" " -f3-6)Z"'
alias sdisk='cd /mnt/f/study/shells/bash/disk/"Visualize disk usage statistics"'
alias myg='gx11 && pyp && pip install PyQt5 && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 8.py'
alias ftime2="sudo apt install --reinstall tzdata -y"
alias 3db='rmf combined.db combined.txt && combine && 2db && pya'
alias clean2="/mnt/f/study/shells/bash/scripts/CleanWSL2ubu2.sh"
alias sgpg="cd /mnt/f/study/security/gpg"

alias plex='gc http://192.168.1.100:32400'
alias savegames='cd /mnt/f/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c '\''apk add rsync && rsync -aP /home/* /c/backup/gamesaves && exit'\'' && built michadockermisha/backup:gamesaves . && docker push michadockermisha/backup:gamesaves && rm -rf ./* && dkill'
alias smaps="cd /mnt/f/study/Travel/maps"
alias slog="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/LogAnalyzers"

alias 30000='gpip && gx11 && pip install requests pandas bs4 pyqt5 && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/media/games/topgames && pya'
alias mvx="late mv /mnt/f/Downloads/*.docx* ."
alias nvid="n /mnt/c/Users/micha/Desktop/vidIdeas.txt"
alias rmvid="rm /mnt/c/users/micha/videos/*"
alias stask="cd /mnt/f/study/FilesystemManagement/taskmanager"
alias smo="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/models"
alias shy="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/databases/Hybrid"
alias srecord="cd /mnt/f/study/hosting/recording"
alias smi="cd /mnt/c/users/micha"
alias svid="cd /mnt/c/users/micha/videos"

alias liners2="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners2"
alias scptv='down && rsync -av --progress tv/ root@192.168.1.100:/home/TV'
alias rmflat='flatpak uninstall --unused -y && rm -rf ~/.local/share/flatpak /var/lib/flatpak && apt remove --purge -y flatpak && apt autoremove -y && apt clean && rm -rf /mnt/wslg/*flatpak*'
alias unzip='f(){ if [ "$1" = "." ]; then find . -type f \( -iname "*.tar.bz2" -o -iname "*.tar.gz" -o -iname "*.bz2" -o -iname "*.rar" -o -iname "*.gz" -o -iname "*.tar" -o -iname "*.tbz2" -o -iname "*.tgz" -o -iname "*.zip" -o -iname "*.Z" -o -iname "*.7z" \) -print0 | while IFS= read -r -d "" file; do case "$file" in *.tar.bz2) tar xjf "$file" && rm "$file" ;; *.tar.gz) tar xzf "$file" && rm "$file" ;; *.bz2) bunzip2 "$file" && rm "$file" ;; *.rar) unrar x "$file" && rm "$file" ;; *.gz) gunzip "$file" && rm "$file" ;; *.tar) tar xf "$file" && rm "$file" ;; *.tbz2) tar xjf "$file" && rm "$file" ;; *.tgz) tar xzf "$file" && rm "$file" ;; *.zip) command unzip "$file" && rm "$file" ;; *.Z) uncompress "$file" && rm "$file" ;; *.7z) 7z x "$file" && rm "$file" ;; *) echo "unzip: '\''$file'\'' cannot be extracted" ;; esac; done; else for file in "$@"; do if [ -f "$file" ]; then case "$file" in *.tar.bz2) tar xjf "$file" && rm "$file" ;; *.tar.gz) tar xzf "$file" && rm "$file" ;; *.bz2) bunzip2 "$file" && rm "$file" ;; *.rar) unrar x "$file" && rm "$file" ;; *.gz) gunzip "$file" && rm "$file" ;; *.tar) tar xf "$file" && rm "$file" ;; *.tbz2) tar xjf "$file" && rm "$file" ;; *.tgz) tar xzf "$file" && rm "$file" ;; *.zip) command unzip "$file" && rm "$file" ;; *.Z) uncompress "$file" && rm "$file" ;; *.7z) 7z x "$file" && rm "$file" ;; *) echo "unzip: '\''$file'\'' cannot be extracted" ;; esac; else echo "unzip: '\''$file'\'' is not a valid file"; fi; done; fi; }; f'
alias liners2='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners2/liners2'
alias liners='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners/liners'
alias rm7="rmf *.7z*"
alias liners2='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners2/liners2'
alias liners='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners/liners'
alias rm7="rmf *.7z*"
alias 5wo="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/thistoolis?in5words"
alias simage="cd /mnt/f/study/hosting/image"
alias sdi="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/visualization/Diagrams"
alias sgr="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/visualization/Graphs"

alias brc='mousepad ~/.bashrc &'
alias latemv='late && cc && mv /mnt/f/Downloads/*docx* . && ls'
alias menu='py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/DockerMenu/noGui/a.py/a.py'
alias lmv="late && cc && mv /mnt/f/Downloads/*docx* . && ls"
alias ugg='alias syncgg="sshpass -p \"123456\" rsync -aHAXW --delete --progress -e \"ssh -o StrictHostKeyChecking=no\" /mnt/f/study/ ubuntu@192.168.1.193:/home/ubuntu/study"; alias vmgg="sshpass -p \"123456\" ssh ubuntu@192.168.1.193 '\''docker login -u \"michadockermisha\" -p \"Aa111111!\" && cd /home/ubuntu/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && docker ps -aq | xargs -r docker stop || true && docker ps -aq | xargs -r docker rm || true && ( docker ps -q | grep -q . || (docker images -q | xargs -r docker rmi || true) ) && ( docker ps -q | grep -q . || docker system prune -a --volumes --force ) && docker network prune --force || true'\''"; syncgg; vmgg'
alias syncgg='sshpass -p "123456" rsync -aHAXW --delete --progress -e "ssh -o StrictHostKeyChecking=no" /mnt/f/study/ ubuntu@192.168.1.193:/home/ubuntu/study'
alias 10gg='(stress-ng --vm 1 --vm-keep --vm-bytes 10G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias conf2="n /mnt/c/Users/micha/.wslconfig"
alias swi="cd /mnt/f/study/networking/packets/PacketCapture/wireshark"
alias 2gg='(stress-ng --vm 1 --vm-keep --vm-bytes 2G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 3gg='(stress-ng --vm 1 --vm-keep --vm-bytes 3G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 4gg='(stress-ng --vm 1 --vm-keep --vm-bytes 4G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 5gg='(stress-ng --vm 1 --vm-keep --vm-bytes 5G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 6gg='(stress-ng --vm 1 --vm-keep --vm-bytes 6G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 7gg='(stress-ng --vm 1 --vm-keep --vm-bytes 7G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 8gg='(stress-ng --vm 1 --vm-keep --vm-bytes 8G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 9gg='(stress-ng --vm 1 --vm-keep --vm-bytes 9G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 10gg='(stress-ng --vm 1 --vm-keep --vm-bytes 10G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 11gg='(stress-ng --vm 1 --vm-keep --vm-bytes 11G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 12gg='(stress-ng --vm 1 --vm-keep --vm-bytes 12G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 13gg='(stress-ng --vm 1 --vm-keep --vm-bytes 13G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 14gg='(stress-ng --vm 1 --vm-keep --vm-bytes 14G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'

alias lmv="late && cc && mv /mnt/f/Downloads/*docx* . && ls"
alias ugg='alias syncgg="sshpass -p \"123456\" rsync -aHAXW --delete --progress -e \"ssh -o StrictHostKeyChecking=no\" /mnt/f/study/ ubuntu@192.168.1.193:/home/ubuntu/study"; alias vmgg="sshpass -p \"123456\" ssh ubuntu@192.168.1.193 '\''docker login -u \"michadockermisha\" -p \"Aa111111!\" && cd /home/ubuntu/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && docker ps -aq | xargs -r docker stop || true && docker ps -aq | xargs -r docker rm || true && ( docker ps -q | grep -q . || (docker images -q | xargs -r docker rmi || true) ) && ( docker ps -q | grep -q . || docker system prune -a --volumes --force ) && docker network prune --force || true'\''"; syncgg; vmgg'
alias syncgg='sshpass -p "123456" rsync -aHAXW --delete --progress -e "ssh -o StrictHostKeyChecking=no" /mnt/f/study/ ubuntu@192.168.1.193:/home/ubuntu/study'
alias vmgg='sshpass -p "123456" ssh ubuntu@192.168.1.193 '"'"'docker login -u "michadockermisha" -p "Aa111111!" && cd /home/ubuntu/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && docker ps -aq | xargs -r docker stop || true && docker ps -aq | xargs -r docker rm || true && ( docker ps -q | grep -q . || (docker images -q | xargs -r docker rmi || true) ) && ( docker images -q | grep -q . || docker system prune -a --volumes --force ) && docker network prune --force || true'"'"''
alias 10gg='(stress-ng --vm 1 --vm-keep --vm-bytes 10G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias conf2="n /mnt/c/Users/micha/.wslconfig"
alias swi="cd /mnt/f/study/networking/packets/PacketCapture/wireshark"
alias 2gg='(stress-ng --vm 1 --vm-keep --vm-bytes 2G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 3gg='(stress-ng --vm 1 --vm-keep --vm-bytes 3G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 4gg='(stress-ng --vm 1 --vm-keep --vm-bytes 4G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 5gg='(stress-ng --vm 1 --vm-keep --vm-bytes 5G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 6gg='(stress-ng --vm 1 --vm-keep --vm-bytes 6G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 7gg='(stress-ng --vm 1 --vm-keep --vm-bytes 7G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 8gg='(stress-ng --vm 1 --vm-keep --vm-bytes 8G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 9gg='(stress-ng --vm 1 --vm-keep --vm-bytes 9G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 10gg='(stress-ng --vm 1 --vm-keep --vm-bytes 10G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 11gg='(stress-ng --vm 1 --vm-keep --vm-bytes 11G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 12gg='(stress-ng --vm 1 --vm-keep --vm-bytes 12G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 13gg='(stress-ng --vm 1 --vm-keep --vm-bytes 13G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'
alias 14gg='(stress-ng --vm 1 --vm-keep --vm-bytes 14G & STRESS_PID=$!; cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && dkill && alert; kill -9 $STRESS_PID)'

alias vmgg='sshpass -p "123456" ssh ubuntu@192.168.1.193 '\''sudo docker login -u "michadockermisha" -p "Aa111111!" && cd /home/ubuntu/study && sudo docker build -t michadockermisha/backup:study . && sudo docker push michadockermisha/backup:study && sudo docker ps -aq | xargs -r sudo docker stop || true && sudo docker ps -aq | xargs -r sudo docker rm || true && ( sudo docker ps -q | grep -q . || (sudo docker images -q | xargs -r sudo docker rmi || true) ) && ( sudo docker images -q | grep -q . || sudo docker system prune -a --volumes --force ) && sudo docker network prune --force || true'\'''

alias syncapps='sshpass -p "123456" rsync -aHAXW --no-times --delete --progress -e "ssh -o StrictHostKeyChecking=no" /mnt/f/backup/ ubuntu@192.168.1.193:/home/ubuntu/backup'
alias vmapps='sshpass -p "123456" ssh ubuntu@192.168.1.193 '\''sudo docker login -u "michadockermisha" -p "Aa111111!" && cd /home/ubuntu/backup && sudo docker build -t michadockermisha/backup:backup . && sudo docker push michadockermisha/backup:backup && sudo docker ps -aq | xargs -r sudo docker stop || true && sudo docker ps -aq | xargs -r sudo docker rm || true && ( sudo docker ps -q | grep -q . || (sudo docker images -q | xargs -r sudo docker rmi || true) ) && ( sudo docker ps -q | grep -q . || sudo docker system prune -a --volumes --force ) && sudo docker network prune --force || true'\'
alias uapps='syncapps; while [ -n "$(sshpass -p \"123456\" rsync -aHAXW --no-times --delete -n -e \"ssh -o StrictHostKeyChecking=no\" /mnt/f/backup/ ubuntu@192.168.1.193:/home/ubuntu/backup)" ]; do sleep 1; done; vmapps'
alias uuu="ugg && uapps"
alias build2='cp /mnt/f/study/containers/docker/dockerfiles/buildthispath/buildthispath ./Dockerfile && n Dockerfile'
alias getrust='curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && source $HOME/.cargo/env && rustc --version && cargo --version && rustup update stable && rustup component add clippy rustfmt llvm-tools-preview && cargo install cargo-edit cargo-audit cargo-outdated cargo-watch cargo-expand cargo-deny cargo-bloat cargo-geiger cargo-udeps cargo-tarpaulin cargo-binutils cargo-deadlinks cargo-update cargo-modules cargo-tree cargo-llvm-cov && curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux -o $HOME/.cargo/bin/rust-analyzer && chmod +x $HOME/.cargo/bin/rust-analyzer'
alias duastu="wget https://github.com/Byron/dua-cli/releases/download/v2.30.0/dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && tar -xvf dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && sudo mv dua-v2.30.0-x86_64-unknown-linux-musl/dua /usr/local/bin/ && stu && dua"
alias fixdpkg3='sudo dpkg --configure -a && sudo apt-get -f install && sudo apt-get install --reinstall libglib2.0-0 && sudo ldconfig || (dpkg-query -W -f='\''${Package} ${Status}\n'\'' | grep '\''reinstreq'\'' | awk '\''{print $1}'\'' | xargs -r sudo dpkg --remove --force-remove-reinstreq && sudo dpkg --configure -a && sudo apt-get -f install && sudo apt-get install --reinstall libglib2.0-0 && sudo ldconfig)'
alias gbrew='cd && export HOMEBREW_ALLOW_SUPERUSER=1 && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && echo '\''eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'\'' >> ~/.bashrc && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew --version'
alias rmdocker='sudo snap remove docker 2>/dev/null || true; sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-compose docker-compose-plugin containerd.io containerd runc docker-ce-rootless-extras docker-scan-plugin 2>/dev/null || true; sudo rm -rf /var/lib/docker /etc/docker /var/lib/containerd /var/run/docker.sock ~/.docker 2>/dev/null || true; sudo rm -f /usr/local/bin/docker-compose /usr/local/bin/docker-machine 2>/dev/null || true; sudo groupdel docker 2>/dev/null || true; sudo apt-get autoremove -y 2>/dev/null || true'
alias duastu="cd && wget https://github.com/Byron/dua-cli/releases/download/v2.30.0/dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && tar -xvf dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && sudo mv dua-v2.30.0-x86_64-unknown-linux-musl/dua /usr/local/bin/ && stu && dua"
alias fixnet2='sudo rm /etc/resolv.conf && sudo bash -c "echo '\''nameserver 8.8.8.8'\'' > /etc/resolv.conf" && sudo apt-get update'
alias fixdpkg4="sudo dpkg --configure -a && sudo apt-get -f install && sudo apt-get update && sudo apt-get --reinstall install \$(dpkg -l | awk '/^ii/ {print \$2}')"
alias fixdpkg5='sudo rm /var/lib/dpkg/info/libpaper* /var/lib/dpkg/info/ghostscript* /var/lib/dpkg/info/gimp* /var/lib/dpkg/info/libgs9* && sudo dpkg --configure -a && sudo apt-get install -f && sudo apt-get clean && sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y'
alias sgnu="cd /mnt/f/study/security/gpg/GnuPG"

alias ubuvm='cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup/ubuVMbackup'
alias nubuvm='n /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ubuVMbackup/ubuVMbackup'
alias wt="psw wtc"
alias sync="rsync -aHAXW --delete --progress"
alias getplex='updates && echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list && curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add - && updates && cc && sudo apt install plexmediaserver -y && sudo systemctl enable plexmediaserver && sudo systemctl start plexmediaserver && gc http://87.70.162.212:32400/web/'
alias getplex='sudo apt update && echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list && curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | sudo tee /etc/apt/trusted.gpg.d/plex.gpg > /dev/null && sudo apt update && sudo apt install plexmediaserver -y && sudo systemctl enable --now plexmediaserver && gc http://localhost:32400/web/'
alias folders2="bash /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/folders2.sh/folders2.sh"
alias sst="cd /mnt/f/study/networking/staticIP"

alias sgamaes="cd /mnt/f/study/hosting/games"

alias sgames="cd /mnt/f/study/hosting/games"
alias smail="cd /mnt/f/study/networking/MailServer"

alias unzipit='/mnt/f/study/shells/bash/scripts/extract_all_archives.sh && rm7 && convert2file'
alias convert2file='find . -mindepth 2 -type f -exec bash -c '\''for f; do dir="${f%/*}"; dirname="${dir##*/}"; tempname="$(mktemp -u XXXXXX)"; mv "$f" "./${tempname}"; rmdir "$dir"; mv "./${tempname}" "./${dirname}"; done'\'' _ {} +'
alias sawc="cd /mnt/f/study/networking/aggregating_web_content"
alias stake="cd /mnt/f/study/AI_and_Machine_Learning/Datascience/Data_Analysis/GoogleTakeOut"

alias comb="sudo apt install imagemagick -y && convert *.png -append combined.png"
alias scpvid="svid && sshpass -p '123456' rsync -avh --progress *.mkv* ubuntu@192.168.1.193:/home/ubuntu/Downloads"
alias getc='updates && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev'
alias dbdr="dotnet build && dotnet run"
alias getc2="updates && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::=\"--force-overwrite\" install --reinstall -y \$(dpkg -l | awk \"/^ii/{print \\\$2}\") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev && sudo apt install -y dotnet-sdk-8.0 dotnet-runtime-8.0 libgtkmm-3.0-dev libwxgtk3.0-gtk3-dev libjson-c-dev libfcgi-dev libzmq3-dev libgrpc++-dev libgrpc-dev protobuf-compiler-grpc libsqlite3-dev libmysqlclient-dev libpq-dev libtbb-dev libasio-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libsdl2-dev libcairo2-dev libmongoc-dev libbson-dev libcpprest-dev libflatbuffers-dev libxxhash-dev liblua5.3-dev libtinyxml2-dev libtinyxml-dev libpugixml-dev libfuzzylite-dev libnlopt-dev libcgal-dev libodbc1 unixodbc-dev libfmt-dev libcli-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev libsdl2-net-dev libssl-dev libsasl2-dev libldap2-dev libfreetype6-dev libexpat1-dev libyaml-cpp-dev libjsoncpp-dev libiconv-hook-dev libgraphicsmagick++1-dev libmagic-dev libcrypto++-dev libprocps-dev nvidia-cuda-toolkit nvtop && echo \"Installing Visual Studio Code\" && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && sudo sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list' && rm -f packages.microsoft.gpg && sudo apt update && sudo apt install -y code && echo \"Installing C# extensions\" && sudo apt install -y mono-complete mono-dbg mono-xbuild fsharp && sudo apt install -y libomp-dev librdkafka-dev librdkafka1 && sudo apt install -y nuget mono-tools-devel && echo \"Setup completed successfully\" && cd /usr/lib/x86_64-linux-gnu/ && sudo ln -sf libtinfo.so.6 libtinfo.so.5"
alias combine='apt install -y ffmpeg && (ls --color=never -1v *.mp4 *.mkv 2>/dev/null | sed "s/^/file '\''/" | sed "s/$/'\''/" > file_list.txt && [ -s file_list.txt ] && ffmpeg -y -f concat -safe 0 -i file_list.txt -c copy output.mkv && rm file_list.txt || echo "No video files found.")'
alias short='f() { apt install -y ffmpeg bc && DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1") && NEW_DURATION=$(echo "$DURATION - $2" | bc) && ffmpeg -i "$1" -c copy -t "$NEW_DURATION" "shorted_$1"; }; f'
# Search for aliases in ~/.bashrc and /mnt/f/backup/linux/wsl/alias.txt
function brcs() {
    # Check if a search term was provided
    if [[ -z "$1" ]]; then
        echo "Usage: brcs <search-term>"
        return 1
    fi
    # Perform the search
    grep -E "^alias.*$1" ~/.bashrc /mnt/f/backup/linux/wsl/alias.txt
}


function brcs2() {
    # Require a search term
    if [[ -z "$1" ]]; then
        echo "Usage: brcs2 <search-term>"
        return 1
    fi

    # Look for lines starting with `alias` whose NAME contains the search term,
    # and strip off everything except the alias name.
    grep -E "^alias[[:space:]]+[^=]*$1[^=]*=" ~/.bashrc /mnt/f/backup/linux/wsl/alias.txt 2>/dev/null \
        | sed -E 's/^.*alias[[:space:]]+([^=]+)=.*/\1/'
}

function brcs3() {
    local search_term="$1"

    if [[ -z "$search_term" ]]; then
        echo "Usage: brcs3 <search-term>"
        return 1
    fi

    # Capture the output of brcs2 in an array.
    # brcs2 <search_term> must already be defined in your shell (as per your setup).
    mapfile -t aliases < <(brcs2 "$search_term")

    # If no matching aliases were found, exit.
    if [[ ${#aliases[@]} -eq 0 ]]; then
        echo "No alias names found matching '${search_term}'."
        return 0
    fi

    # Join all alias names with " && ".
    local joined=""
    for a in "${aliases[@]}"; do
        if [[ -z "$joined" ]]; then
            joined="$a"
        else
            joined="$joined && $a"
        fi
    done

    # Print the single-line string.
    echo "$joined"
}

#########################
# brcs4
#   For each alias name given as argument(s),
#   output the full command of that alias.
#########################
function brcs4() {
    # If no arguments given, show usage
    if [[ $# -eq 0 ]]; then
        echo "Usage: brcs4 <alias_name1> [<alias_name2> ...]"
        return 1
    fi

    # Loop over each alias name provided
    for alias_name in "$@"; do
        # Search for the alias definition (the full line) in both ~/.bashrc and alias.txt
        #   - Grab only the first match, in case multiple lines match.
        #   - The pattern means: line must start with "alias <alias_name>=" 
        line="$(grep -E "^alias[[:space:]]+${alias_name}=" ~/.bashrc /mnt/f/backup/linux/wsl/alias.txt 2>/dev/null | head -n1)"

        # If not found, print a warning and move on
        if [[ -z "$line" ]]; then
            echo "No alias found for '$alias_name'" >&2
            continue
        fi

        # Extract everything after the '='
        cmd="$(echo "$line" | cut -d= -f2-)"

        # Remove possible leading/trailing single or double quotes
        cmd="${cmd#\"}"    # remove leading  "
        cmd="${cmd#\'}"    # remove leading  '
        cmd="${cmd%\"}"    # remove trailing "
        cmd="${cmd%\'}"    # remove trailing '

        # Show the result
        echo "$alias_name => $cmd"
    done
}

function brcs5() {
    # Check if a search term was provided
    if [[ -z "$1" ]]; then
        echo "Usage: brcs5 <search-term>"
        return 1
    fi

    local search_term="$1"
    
    # Get alias names matching the search term using brcs2
    mapfile -t aliases < <(brcs2 "$search_term")
    
    # If no matching aliases were found, exit.
    if [[ ${#aliases[@]} -eq 0 ]]; then
        echo "No alias names found matching '${search_term}'."
        return 0
    fi

    # Remove duplicate alias names.
    declare -A seen
    unique_aliases=()
    for alias in "${aliases[@]}"; do
        if [[ -z "${seen[$alias]}" ]]; then
            seen[$alias]=1
            unique_aliases+=( "$alias" )
        fi
    done

    # Join all unique alias names with a space.
    local joined=""
    for a in "${unique_aliases[@]}"; do
        if [[ -z "$joined" ]]; then
            joined="$a"
        else
            joined="$joined $a"
        fi
    done

    # Print the single-line string.
    echo "$joined"
}


alias m="mousepad"
alias rmc='sudo apt remove --purge -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev dotnet-sdk-8.0 dotnet-runtime-8.0 libgtkmm-3.0-dev libwxgtk3.0-gtk3-dev libjson-c-dev libfcgi-dev libzmq3-dev libgrpc++-dev libgrpc-dev protobuf-compiler-grpc libmysqlclient-dev libpq-dev libtbb-dev libasio-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libsdl2-dev libcairo2-dev libmongoc-dev libbson-dev libcpprest-dev libflatbuffers-dev libxxhash-dev liblua5.3-dev libtinyxml2-dev libtinyxml-dev libpugixml-dev libfuzzylite-dev libnlopt-dev libcgal-dev libodbc1 unixodbc-dev libfmt-dev libcli-dev libsdl2-image-dev libsdl2-ttf-dev libsdl2-mixer-dev libsdl2-net-dev libssl-dev libsasl2-dev libldap2-dev libfreetype6-dev libexpat1-dev libyaml-cpp-dev libjsoncpp-dev libiconv-hook-dev libgraphicsmagick++1-dev libmagic-dev libcrypto++-dev libprocps-dev nvidia-cuda-toolkit nvtop code mono-complete mono-dbg mono-xbuild fsharp libomp-dev librdkafka-dev librdkafka1 nuget mono-tools-devel && sudo apt autoremove -y && sudo apt autoclean -y && sudo rm -f /etc/apt/sources.list.d/vscode.list && sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg && sudo apt update && sudo rm -f /usr/lib/x86_64-linux-gnu/libtinfo.so.5 && sudo rm -rf /var/lib/dpkg/info && sudo mv /var/lib/dpkg/info.bak /var/lib/dpkg/info && echo "All packages installed by getc2 have been purged and system changes reverted."'
alias fdpkg="sudo rm -f /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock && sudo dpkg --configure -a && sudo apt-get -f install && sudo dpkg --add-architecture i386 && sudo apt-get update -y --fix-missing && sudo apt-get install --reinstall apt dpkg -y && sudo apt-get install --reinstall libgl1-mesa-glx libglx-mesa0 libgl1-mesa-dri mesa-vulkan-drivers libgl1-mesa-dri:i386 -y && sudo chmod 0700 /run/user/\$(id -u) && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old 2>/dev/null && sudo mkdir /var/lib/dpkg/info && sudo apt-get update -y && sudo apt-get install --reinstall -y \$(dpkg -l | grep '^ii' | awk '{print \$2}') && sudo dpkg --configure -a && sudo apt-get -f install && dpkg-query -W -f='\${Package} \${Status}\\n' | grep 'reinstreq' | awk '{print \$1}' | xargs -r sudo dpkg --remove --force-remove-reinstreq && sudo dpkg --configure -a && sudo apt-get -f install && sudo rm /var/lib/dpkg/info/libpaper* /var/lib/dpkg/info/ghostscript* /var/lib/dpkg/info/gimp* /var/lib/dpkg/info/libgs9* 2>/dev/null && sudo dpkg --configure -a && sudo apt-get install -f && sudo apt-get clean && sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo ldconfig"alias dup='awk -F '\''[= ]'\'' '\''/^alias/ {alias[$2]++} END {for (a in alias) if (alias[a] > 1) print a}'\'' ~/.bashrc | xargs -I {} grep '\''^alias {}='\'' ~/.bashrc'
alias sahk="cd /mnt/f/study/Platforms/windows/autohotkey"

rmit() { if [ -z "$1" ]; then echo "Usage: rmit <pattern> (e.g., rmit 'lib*')"; return 1; fi; packages=$(apt list --installed "$1" 2>/dev/null | grep -v '^Listing' | cut -d/ -f1 | grep -vE '^(qt|r-|libreoffice|libnvidia|libodb|libc\+\+|libunwind|libhts|libmysqlclient)' | tr '\n' ' '); [ -z "$packages" ] && echo "No packages matching: $1" && return 1; echo "Removing: $packages"; sudo apt remove --purge -y $packages; sudo apt update -y && sudo apt upgrade -y; sudo apt autoremove --purge -y; sudo apt autoclean -y; sudo apt clean -y; sudo dpkg --configure -a; sudo dpkg -l | grep '^rc' | awk '{print $2}' | xargs -r sudo apt purge -y; sudo find /var/log -type f -exec truncate -s 0 {} + -o -name "*.gz" -exec rm -f {} + -o -regex ".*\.[0-9]+" -exec rm -f {} +; sudo rm -rf /var/cache/* ~/.cache/* ~/.local/share/Trash/* ~/.cache/thumbnails/* /tmp/* /var/tmp/* /usr/share/man/* /usr/share/doc/* /usr/share/info/* /usr/share/lintian/* /usr/share/linda/*; sudo find / -xdev \( -type f \( -name "*.pyc" -o -name "*.pyo" \) -delete -o -type d -name "__pycache__" -exec rm -rf {} + -o -xtype l -delete \); sudo find / -xdev -type f -size +50M ! -path "/proc/*" ! -path "/sys/*" ! -path "/dev/*" -exec rm -f {} +; sudo systemctl stop snapd 2>/dev/null; sudo apt remove --purge -y snapd; sudo rm -rf /var/cache/snapd /var/snap /snap /root/snap /home/*/snap; command -v docker &>/dev/null && sudo docker system prune -a --volumes -f; sudo dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null; sudo rm -f /EMPTY; command -v e4defrag &>/dev/null && sudo e4defrag /; df -h; sudo rm -rf /var/lib/{dpkg/info/*,apt/lists/*,polkit-1/*} /var/log/alternatives.log /usr/lib/x86_64-linux-gnu/dri/* /usr/share/python-wheels/* /var/cache/apt/{pkgcache.bin,srcpkgcache.bin}; }
getit() { if [ -z "$1" ]; then echo "Usage: getit <pattern> (e.g., getit 'lib*')"; return 1; fi; ! command -v aptitude &>/dev/null && sudo apt install -y aptitude; packages=$(apt list --all-versions "$1" 2>/dev/null | grep -v '^Listing\|\[installed\]' | grep 'jammy' | cut -d/ -f1 | grep -vE '^(qt|r-|libreoffice|libnvidia|libodb|libc\+\+|libunwind|libhts|libmysqlclient)' | tr '\n' ' '); [ -z "$packages" ] && echo "No packages matching: $1" && return 1; echo "Installing: $packages"; sudo aptitude install -y -o Aptitude::CmdLine::SolverTimeout=600 $packages; [ $? -eq 0 ] && echo "Success" || echo "Failed"; }
alias myg='gx11 && pyp && pip install pyqt5 requests &&  py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/19.py'
alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy &&  py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/19.py'
alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy &&  py /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/22.py'
alias diskit="wtc 10 du -sh /mnt/wslg"
alias getlib2='fdpkg && fixupdates && ftime2 &&  cd && sudo apt install libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 -y && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install && sudo dpkg --configure -a && echo "6" | sudo -S apt update && echo "Jerusalem" | sudo -S apt install -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt install -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt install -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install && sudo dpkg --configure -a && sudo apt install -y libcurl4-openssl-dev libglib2.0-dev libpango1.0-dev libgdk-pixbuf2.0-dev libgtk-3-dev libatk1.0-dev libatk-bridge2.0-dev libcups2-dev libdbus-1-dev libgirepository1.0-dev libgee-0.8-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libwayland-dev libdrm-dev libxdamage-dev libxrandr-dev libxcomposite-dev libxi-dev libxtst-dev libxfixes-dev libxinerama-dev libxcursor-dev libxss-dev libxkbcommon-dev libinput-dev libevdev-dev libudev-dev libusb-1.0-0-dev libbluetooth-dev libnss3-dev libnspr4-dev libpq-dev libpcre3-dev libsnappy-dev libzip-dev libexpat1-dev libmpfr-dev libmpc-dev libicu-dev libgcrypt20-dev libseccomp-dev libtirpc-dev libxext-dev libxrender-dev libfontconfig1-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-render-util0-dev && sudo apt --fix-broken install && sudo dpkg --configure -a && sudo apt install -y libeigen3-dev libglm-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev libboost-program-options-dev libboost-regex-dev libpugixml-dev libyaml-cpp-dev libcurl4-openssl-dev libx11-dev libxext-dev libxi-dev libxrandr-dev libxrender-dev libxfixes-dev libxft-dev libxinerama-dev libxmu-dev libxpm-dev libxt-dev libsm-dev libice-dev libxv-dev libxcb-util0-dev libgl1-mesa-dev libglu1-mesa-dev libglfw3-dev libglew-dev libosmesa6-dev libxcursor-dev libxxf86vm-dev libvdpau-dev libva-dev libfribidi-dev libwebp-dev libgif-dev libraw1394-dev libpulse-dev libasound2-dev libsamplerate0-dev libvorbis-dev libogg-dev libflac-dev libfaad-dev libmp3lame-dev libmodplug-dev libopenal-dev libopencv-dev libv4l-dev && sudo apt --fix-broken install && sudo dpkg --configure -a'
alias sizeit='wtc 10 "find . -type f -print | wc -l && du -sh"'
alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 22.py'
alias swebtop="cd /mnt/f/study/containers/docker/scripts/webtop"

alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 23.py'
alias bigitgo='backitup && gitgo'
alias songs="gpip && pip install  yt-dlp && apt install ffmpeg -y && py /mnt/f/study/Dev_Toolchain/programming/python/apps/music/MusicDownloadFromFile"

scp2ubu() {
  if [ -z "$1" ]; then
    echo "Usage: scp2ubu <folder_name>"
    return 1
  fi
  sshpass -p "123456" rsync -aHAXW --delete --progress "$1" ubuntu@192.168.1.193:/home/ubuntu
}
alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 24.py'
alias gkag='gpip && pip install kaggle && mkdir -p ~/.kaggle && cp /mnt/f/backup/windowsapps/Credentials/kaggle/kaggle.json ~/.kaggle/ && chmod 600 ~/.kaggle/kaggle.json && kaggle datasets list'
alias smyg="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui"
alias ddd='cp /mnt/f/study/shells/bash/scripts/echobuildpush.sh . && chmod +x echobuildpush.sh && ./echobuildpush.sh'
alias myg='gx11 && pyp && pip install pyqt5 requests howlongtobeatpy && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 31.py'
alias ddd='cp /mnt/f/study/shells/bash/scripts/echobuildpush.sh ./a.sh && chmod +x ./a.sh && ./a.sh'
alias uploadvid="sshpass -p '123456' ssh -o StrictHostKeyChecking=no ubuntu@192.168.1.193 'echo \"ubuntu ALL=(ALL) NOPASSWD: ALL\" | sudo EDITOR=\"tee -a\" visudo && sudo su -c \"cd /root && python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd /home/ubuntu && python upload.py\"'"
alias vidup="scpvid && uploadvid"
alias scpyt=' scp /mnt/f/backup/windowsapps/Credentials/youtube/client_secret.json ubuntu@192.168.1.193:/home/ubuntu/'
alias ssand="cd /mnt/f/study/Platforms/windows/sandbox"

alias saveapk="cd /mnt/f/backup/apk &&  docker build -t michadockermisha/backup:apk .&& docker push michadockermisha/backup:apk"
alias mvc='f() { mv "$1" "$2" && cd "$2"; }; f'
alias backitup='backupapk && backupapps && gg && backupwsl'
alias backitup='sprofile && backupapk && backupapps && gg && backupwsl'
alias sgg="sprofile && gg"
alias sprofile="cd /mnt/f/backup/windowsapps/profile && docker build -t michadockermisha/backup:profile . && docker push michadockermisha/backup:profile"
alias top='psw -command "top"'
alias backupapk="cd /mnt/f/backup/apk && built michadockermisha/backup:apk . && docker push michadockermisha/backup:apk"
alias gitgo='apt install -y git && /mnt/f/backup/windowsapps/Credentials/Gitgo/AutoGitgo.sh && alert'
alias slua="cd /mnt/f/study/Dev_Toolchain/programming/lua"

alias getgcloud='gpip && pip install pyqt5 && sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install -y apt-transport-https ca-certificates gnupg curl sudo && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && sudo apt-get update -y && sudo apt-get install -y google-cloud-cli && gcloud init'
alias scri2="cd /mnt/f/study/shells/powershell/scripts"

alias backitup='sprofile && backupapps && gg && backupwsl'
alias venv=' sudo apt install python3-venv -y && cd /mnt/f/backup/linux/wsl &&  python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd '
alias sexe="cd /mnt/f/study/Platforms/windows/exe"
alias scron="cd /mnt/f/study/Devops/automation/cron"

alias game='apt install python3-pip -y && venv && pip install youtube_search bs4 requests pandas && py /mnt/f/backup/windowsapps/installed/myapps/compiled_python/howlongtobeat_dataset/howlongtobeat_dataset/a.py'
alias srss="cd /mnt/f/study/networking/aggregating_web_content/rss"

alias myg='gx11 && venv && pyp && pip install pyqt5 requests howlongtobeatpy && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui && py 31.py'
alias scsv="cd /mnt/f/study/documents/csv"

alias sreddit="cd /mnt/f/study/search_engines/searchEngines/reddit"

alias rcp='rmn main.cpp'
alias getlib='cd && getlibssl1 && wget http://mirrors.kernel.org/ubuntu/pool/universe/g/glew/libglew2.1_2.1.0-4_amd64.deb && sudo dpkg -i libglew2.1_2.1.0-4_amd64.deb && sudo apt install -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install && sudo dpkg --configure -a && echo "6" | sudo -S apt update && echo "Jerusalem" | sudo -S apt install -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt install -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt install -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install && sudo dpkg --configure -a && echo "Jerusalem" | sudo -S apt install -y libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev'
alias getc='ftime2 && updates && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev libz3-dev libomp-dev libc++-dev libc++abi-dev libcriterion-dev libcsfml-dev libdlib-dev libeigen3-dev libfaac-dev libfaad-dev libflac-dev libfluidsynth-dev libfreeimage-dev libfreetype6-dev libftgl-dev libgd-dev libglew-dev libglfw3-dev libglm-dev libgmp-dev libgnutls28-dev libgrpc-dev libgtk-3-dev libgtkmm-3.0-dev libhidapi-dev libicu-dev libidn11-dev libisl-dev libjsoncpp-dev liblapack-dev liblua5.3-dev libmagick++-dev libmariadb-dev libmetis-dev libmpfr-dev libmysqlclient-dev libnetcdf-dev libogg-dev libopenal-dev libopenblas-dev libopus-dev libpcap-dev libpng-dev libpq-dev libpthread-stubs0-dev libqhull-dev libqt5charts5-dev libqt5opengl5-dev libqt5svg5-dev libqt5webkit5-dev libqt5xmlpatterns5-dev libraw-dev librtaudio-dev librtmidi-dev libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-net-dev libsdl2-ttf-dev libsfml-dev libsndfile1-dev libsoil-dev libsoundtouch-dev libssl-dev libsuitesparse-dev libtbb-dev libtiff-dev libtinyxml2-dev libusb-1.0-0-dev libvorbis-dev libvtk7-dev libwxgtk3.0-gtk3-dev libx11-dev libx264-dev libxerces-c-dev libxml2-dev libxmu-dev libxrandr-dev libxslt1-dev libxxf86vm-dev libyaml-cpp-dev libzip-dev nasm yasm zlib1g-dev mono-complete nuget dotnet6 dotnet-runtime-6.0 dotnet-sdk-6.0 dotnet-targeting-pack-6.0 ros-desktop-full clangd ccls bear libonig-dev libpqxx-dev libquickfix-dev libreadline-dev libserial-dev libsigc++-2.0-dev libsodium-dev libsoup2.4-dev libsvm-dev libtensorflow-dev libtomcrypt-dev libtommath-dev libtorch-dev liburiparser-dev libutf8proc-dev libuv1-dev libwebsockets-dev libxapian-dev libxml++2.6-dev libxt-dev libyara-dev libzmq3-dev libzstd-dev libzzip-dev mingw-w64 nasm nodejs npm opencl-headers ocl-icd-opencl-dev python3-dev python3-pip python3-venv ruby-dev rustc cargo swig tcl-dev tk-dev texinfo texi2html uuid-dev valac vlc wget xorg-dev yasm zip zlib1g-dev libboost-python-dev libcgal-dev libceres-dev libcln-dev libcoin-dev libcollada-dom-dev libdcmtk-dev libdeal.ii-dev libdune-common-dev libdune-geometry-dev libdune-grid-dev libdune-istl-dev libdune-localfunctions-dev libdune-uggrid-dev libepoxy-dev libexiv2-dev libfcl-dev libflann-dev libgdal-dev libgeos++-dev libgeotiff-dev libgmsh-dev libgphoto2-dev libgraphicsmagick++1-dev libgtk2.0-dev libgtkglext1-dev libgts-dev libhdf4-dev libheif-dev libkml-dev liblensfun-dev libmagick++-6.q16-dev libmapnik-dev libmuparser-dev libnetcdf-c++4-dev libopenexr-dev libopenvdb-dev libosgworks-dev libpcl-dev libplib-dev libproj-dev libpugixml-dev libqrupdate-dev libqt5scripttools5 libqt5serialport5-dev libqt5texttospeech5-dev libqt5x11extras5-dev librsb-dev libscotch-dev libslicot-dev libsndobj-dev libsofia-sip-ua-dev libsquish-dev libstxxl-dev libsuperlu-dev libtulip-dev libwildmagic-dev libxalan-c-dev libxqilla-dev libyaml-dev mpi-default-dev mpi-default-bin nvidia-cuda-dev nvidia-cuda-toolkit nvidia-opencl-dev oce-draw liboce-foundation-dev liboce-modeling-dev liboce-ocaf-dev liboce-visualization-dev libopenni2-dev libopenscenegraph-dev libpdal-dev libplplot-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '"'"'{print $1}'"'"') && sudo apt-get install -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt install mingw-w64 -y && getlib'
alias compc='rm -f main.exe main.moc; [ -f b.png ] || { echo "Error: b.png not found"; exit 1; }; chmod 0644 b.png; cp main.cpp main_tmp.cpp; if grep -q Q_OBJECT main_tmp.cpp; then if ! tail -n1 main_tmp.cpp | grep -q "main.moc"; then echo -e "\n#include \"main.moc\"" >> main_tmp.cpp; fi; moc main_tmp.cpp -o main.moc; status=$?; if [ $status -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root && cp main.exe b.png /tmp/runtime-root && (cd /tmp/runtime-root && ./main.exe); fi; else echo "Compilation failed"; fi; else echo "moc failed: consider moving your Q_OBJECT class to its own header or guarding code with #ifndef Q_MOC_RUN"; fi; fi; rm -f main_tmp.cpp'
alias getc='ftime2 && updates && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '"'"'{print $1}'"'"') && sudo apt-get install -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt install mingw-w64 -y && getlib'
alias getc='ftime2 && updates && apt install -y build-essential && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '\''{print $1}'\'') && sudo apt-get install -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt install mingw-w64 -y && getlib'
alias compc='rm -f main.exe main.moc; [ -f b.png ] || { echo "Error: b.png not found"; false; }; chmod 0644 b.png; cp main.cpp main_tmp.cpp; if grep -q Q_OBJECT main_tmp.cpp; then if ! tail -n1 main_tmp.cpp | grep -q "main.moc"; then echo -e "\n#include \"main.moc\"" >> main_tmp.cpp; fi; moc main_tmp.cpp -o main.moc; status=$?; if [ $status -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root && cp main.exe b.png /tmp/runtime-root && (cd /tmp/runtime-root && ./main.exe); fi; else echo "Compilation failed"; fi; else echo "moc failed: consider moving your Q_OBJECT class to its own header or guarding correctly"; fi; fi; rm -f main_tmp.cpp'
alias rmc="sudo apt purge -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 gconf2-common gconf-service-backend gconf-service libgconf-2-4 build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev qtcreator libqt5core5a libqt5gui5 drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt6-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev mingw-w64 && sudo apt autoremove -y && sudo rm -f ~/libglew2.1_2.1.0-4_amd64.deb"
alias getc='ftime2 && updates && apt install -y  g++-mingw-w64 build-essential && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt update && sudo apt -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt install -f -y && sudo dpkg --configure -a && sudo apt install -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '\''{print $1}'\'') && sudo apt-get install -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt install mingw-w64 -y && getlib'
alias getc='ftime2 && updates && sudo apt-get update && sudo apt-get install --no-install-recommends -y g++-mingw-w64 build-essential qtbase5-dev qt5-qmake autoconf automake libtool-bin gettext gperf intltool libtool libxml-parser-perl python3 wget g++ git && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt-get update && sudo apt-get -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt-get install -f -y && sudo dpkg --configure -a && sudo apt-get install --no-install-recommends -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '\''{print $1}'\'') && sudo apt-get install --no-install-recommends -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt-get install --no-install-recommends -y mingw-w64 && cd && getlibssl1 && wget -nc http://mirrors.kernel.org/ubuntu/pool/universe/g/glew/libglew2.1_2.1.0-4_amd64.deb && sudo dpkg -i libglew2.1_2.1.0-4_amd64.deb || sudo apt --fix-broken install -y && sudo apt-get install --no-install-recommends -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "6" | sudo -S apt-get update && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt-get install --no-install-recommends -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt-get install --no-install-recommends -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev'
alias compc='rm -f main.exe main.moc; cp main.cpp main_tmp.cpp; if grep -q Q_OBJECT main_tmp.cpp; then if ! tail -n1 main_tmp.cpp | grep -q "main.moc"; then echo -e "\n#include \"main.moc\"" >> main_tmp.cpp; fi; moc main_tmp.cpp -o main.moc; status=$?; if [ $status -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; else echo "moc failed: consider moving your Q_OBJECT class to its own header or guarding correctly"; fi; else echo "No Q_OBJECT found, compiling normally"; if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root && cp main.exe /tmp/runtime-root && (cd /tmp/runtime-root && ./main.exe); fi; else echo "Compilation failed"; fi; rm -f main_tmp.cpp'
alias smsys="cd /mnt/f/study/virtualmachines/msys2"
alias getc='ftime2 && updates && sudo apt-get update && sudo apt-get install --no-install-recommends -y g++-mingw-w64 portaudio19-dev libportaudio2 libportaudiocpp0 build-essential qtbase5-dev qt5-qmake autoconf automake libtool-bin gettext gperf intltool libtool libxml-parser-perl python3 wget g++ git && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt-get update && sudo apt-get -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt-get install -f -y && sudo dpkg --configure -a && sudo apt-get install --no-install-recommends -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '\''{print $1}'\'') && sudo apt-get install --no-install-recommends -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt-get install --no-install-recommends -y mingw-w64 && cd && getlibssl1 && wget -nc http://mirrors.kernel.org/ubuntu/pool/universe/g/glew/libglew2.1_2.1.0-4_amd64.deb && sudo dpkg -i libglew2.1_2.1.0-4_amd64.deb || sudo apt --fix-broken install -y && sudo apt-get install --no-install-recommends -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "6" | sudo -S apt-get update && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt-get install --no-install-recommends -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt-get install --no-install-recommends -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev'
alias npy='n a.ipynb'
alias sipynb="cd /mnt/f/study/Dev_Toolchain/programming/python/ipynb"

alias ncp="n main.cpp"
alias liners4="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners/liners4"
alias liners3="copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liners/liners3"
alias comc='g++ main.cpp -o main.exe -lsfml-graphics -lsfml-window -lsfml-system && ./main.exe'
alias gaudio="getaudio && audio"
alias audio="down && edge-tts --file a.txt --write-media audio.mp3"
alias getaudio='venv && cd /mnt/f/study/Dev_Toolchain/programming/python/apps/convert/Text2Audio/epub2tts && sudo apt install -y espeak-ng ffmpeg -y && pip install coqui-tts --only-binary spacy &&  pip install . &&  python -m nltk.downloader punkt_tab && edge-tts --list-voices | grep -i hebrew'
alias getfuse='sudo dpkg --configure -a; yes "" | sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" -f install -y; sudo apt-get update; yes "" | sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --fix-missing install -y; sudo rm -f /var/lib/dpkg/info/unattended-upgrades*; yes "" | sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install --reinstall unattended-upgrades -y; sudo dpkg --configure -a; yes "" | sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y fuse libfuse2 libegl1 software-properties-common; yes | sudo add-apt-repository universe; sudo apt-get update; sudo modprobe fuse; sudo groupadd fuse 2>/dev/null || true; sudo usermod -a -G fuse $USER; echo "FUSE fully configured. Log out/in or reboot for changes to apply."'
alias scli="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/terminalAI"
alias myapps="cd /mnt/f/backup/windowsapps/installed/myapps/compiled_python"

alias duawsl='cd && wget https://github.com/Byron/dua-cli/releases/download/v2.30.0/dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && tar -xvf dua-v2.30.0-x86_64-unknown-linux-musl.tar.gz && sudo mv dua-v2.30.0-x86_64-unknown-linux-musl/dua /usr/local/bin/ && cd /mnt/wslg && dua'
alias rmfs='rm -rf -- * .[!.]* ..?*'
alias getnvm='apt install npm -y && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
alias seng="cd /mnt/f/study/Dev_Toolchain/programming/engines"

alias cco="copy cat"
alias greact="cd && nvm23 && npm install react react-dom && yes "y" | npx create-react-app my-app && cd my-app && nsj && npm start"
alias nsj='rmn src/App.js'
alias cpmyg="cp -r  user_session.json time.txt   tag_settings.json tabs_config.json games_data.json custom_buttons.json active_users.json b.png /root"
alias cpsec="cp -r /mnt/f/backup/windowsapps/Credentials/youtube/client_secret.json /mnt/c/Users/micha/Downloads"
alias rmp='rmf /mnt/c/Users/micha/Pictures/Screenshots/*'
alias getunity='cd &&  curl -sLo ugs_installer ugscli.unity.com/v1 && shasum -c <<<"3bbc507d4776a20d5feb4958be2ab7d4edcea8eb  ugs_installer" && bash ugs_installer'
alias drun='docker run -v /mnt/f/:/f/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --name'
alias savegames='cd /mnt/f/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c '\''apk add rsync && rsync -aP /home/* /f/backup/gamesaves && exit'\'' && built michadockermisha/backup:gamesaves . && docker push michadockermisha/backup:gamesaves && rm -rf /mnt/f/backup/gamesaves/* && dkill'
alias sunity="cd /mnt/f/study/AI_and_Machine_Learning/DeepLearning/Unity"

alias getandroid=" sudo apt install -y openjdk-11-jdk wget unzip && wget https://dl.google.com/dl/android/studio/ide-zips/2023.1.1.17/android-studio-2023.1.1.17-linux.tar.gz -P /tmp && sudo tar -xvzf /tmp/android-studio-2023.1.1.17-linux.tar.gz -C /opt && sudo ln -s /opt/android-studio/bin/studio.sh /usr/local/bin/android-studio && android-studio"
alias pipit3="bash /mnt/f/study/shells/bash/scripts/pipit3.sh"
alias smygm='cd /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/modular/frontBack'
alias cpmyg="cp -r /mnt/f/study/Dev_Toolchain/programming/python/apps/pyqt5menus/GamesDockerMenu/gui/*.{png,json,txt} . "
alias getlibgl="sudo apt-get install -y libgl1-mesa-glx"
alias venv=' sudo apt install python3-venv -y && cd /mnt/f/backup/linux/wsl &&  python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd && gpip'
alias ccoa="cco a.py"
alias and="android-studio"
alias cpsec='cp -r /mnt/f/backup/windowsapps/Credentials/youtube/client_secret.json . '
alias sgames2="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/media/games"

alias venv=' sudo apt install python3-venv -y && cd /mnt/f/backup/linux/wsl &&  python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip && cd && gpip && apt install git -y'
alias slo="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/local"

alias skot="cd /mnt/f/study/Dev_Toolchain/programming/kotlin"
alias getjava='wget https://download.java.net/java/GA/jdk23/3c5b90190c68498b986a97f276efd28a/37/GPL/openjdk-23_linux-x64_bin.tar.gz && tar -xvzf openjdk-23_linux-x64_bin.tar.gz && mv jdk-23 /usr/local/ && update-alternatives --install /usr/bin/java java /usr/local/jdk-23/bin/java 1 && update-alternatives --install /usr/bin/javac javac /usr/local/jdk-23/bin/javac 1 && update-alternatives --set java /usr/local/jdk-23/bin/java && update-alternatives --set javac /usr/local/jdk-23/bin/javac && java -version && getsnap && sudo snap install --classic kotlin'

alias gethadoop='sudo apt-get update && sudo apt-get install -y openjdk-11-jdk wget && wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && tar -xzvf hadoop-3.3.6.tar.gz -C /usr/local && sudo mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && export HADOOP_HOME=/usr/local/hadoop && export PATH=$PATH:$HADOOP_HOME/bin && export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 && $HADOOP_HOME/bin/hadoop version && getsnap && sudo snap install --classic kotlin'

alias getjava8='sudo apt-get install -y openjdk-8-jdk && getsnap && sudo snap install --classic kotlin'

alias getjava11='sudo apt-get install -y openjdk-11-jdk && getsnap && sudo snap install --classic kotlin'

alias fulljava='sudo apt install -y default-jre default-jdk maven gradle ant ivy libcommons-lang3-java libcommons-io-java libcommons-collections3-java libcommons-codec-java libcommons-logging-java libcommons-dbcp-java libcommons-dbcp2-java libcommons-pool-java libcommons-pool2-java libswt-gtk-4-java libasm-java libaspectj-java libjcommon-java libjfreechart-java libhamcrest-java libmockito-java libcglib-java libjavassist-java libehcache-java libc3p0-java libproguard-java liblogback-java libdom4j-java libhibernate3-java libhibernate-validator-java libspring-core-java libspring-beans-java libspring-context-java libspring-web-java libaopalliance-java libjoda-time-java libcommons-compress-java libzip4j-java liblz4-java libsnappy-java libsqljet-java libhsqldb-java libderby-java libcommons-cli-java libcommons-math-java libcommons-math3-java libcommons-net-java libcommons-exec-java libcommons-validator-java libcommons-collections4-java libcommons-csv-java libxerces2-java libxml-commons-external-java libxml-commons-resolver1.1-java libbcel-java libsaxon-java libsaxonb-java libfreemarker-java libitext-java libjboss-logging-java libjboss-logging-tools-java libaopalliance-java libactivation-java libjgoodies-forms-java libxstream-java libfindbugs-java libslf4j-java liblog4j1.2-java libjoda-convert-java libapache-poi-java libjna-java libeclipselink-java libjaxb-api-java libxmlbeans-java libbatik-java libfop-java libswtchart-java libkxml2-java libcommons-discovery-java libaxis-java && getsnap && sudo snap install --classic kotlin'

alias getmvn='getjava && apt install maven -y && getsnap && sudo snap install --classic kotlin'

alias java8='apt install -y openjdk-8-jdk openjdk-8-jre openjdk-8-source openjdk-8-jre-headless openjdk-8-jdk-headless openjdk-8-jre-zero openjdk-8-dbg openjdk-8-demo openjdk-8-doc && java --version && getsnap && sudo snap install --classic kotlin'

alias java11='apt install -y openjdk-11-jdk openjdk-11-jre openjdk-11-source openjdk-11-jre-headless openjdk-11-jdk-headless openjdk-11-jre-zero openjdk-11-dbg openjdk-11-demo openjdk-11-doc && java --version && getsnap && sudo snap install --classic kotlin'

alias java17='apt install -y openjdk-17-jdk openjdk-17-jre openjdk-17-source openjdk-17-jre-headless openjdk-17-jdk-headless openjdk-17-jre-zero openjdk-17-dbg openjdk-17-demo openjdk-17-doc && java --version && getsnap && sudo snap install --classic kotlin'

alias java18='apt install -y openjdk-18-jdk openjdk-18-jre openjdk-18-source openjdk-18-jre-headless openjdk-18-jdk-headless openjdk-18-jre-zero openjdk-18-dbg openjdk-18-demo openjdk-18-doc && java --version && getsnap && sudo snap install --classic kotlin'

alias java19='apt install -y openjdk-19-jdk openjdk-19-jre openjdk-19-source openjdk-19-jre-headless openjdk-19-jdk-headless openjdk-19-jre-zero openjdk-19-dbg openjdk-19-demo openjdk-19-doc && java --version && getsnap && sudo snap install --classic kotlin'

alias java21='apt install -y openjdk-21-jdk openjdk-21-jre openjdk-21-source openjdk-21-jre-headless openjdk-21-jdk-headless openjdk-21-jre-zero openjdk-21-dbg openjdk-21-demo openjdk-21-doc openjdk-21-testsupport && java --version && getsnap && sudo snap install --classic kotlin'

alias getgh="apt install git gh -y && gitoken && gh auth login"
alias liner='copy cat /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/liner/liner'
alias smyapps="cd /mnt/f/backup/windowsapps/installed/myapps/compiled_python"

alias sjs="/mnt/f/study/Dev_Toolchain/programming/frontend/javascript/projects"
alias ninr="npm install && npm run dev"
alias LS="ls"
alias backupapps='cd /mnt/f/backup/windowsapps && built michadockermisha/backup:windowsapps . && docker push michadockermisha/backup:windowsapps'
alias restorestudy='getf && mkc study && drun study michadockermisha/backup:study sh -c "apk add rsync && rsync -aP /home/* /f/study/ && exit"'
alias cdbackup='getf && cd backup'
alias restorebackup='getf && mkdir backup && drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /f/backup/ && cd /f/backup/ && mv home windowsapps && exit" && cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /f/backup/linux && cd /f/backup/linux && mv home wsl && exit" '
alias cod="psw -command code ."
alias srag="cd /mnt/f/study/AI_and_Machine_Learning/Machine_Learning/RAG"

alias restoreapps='drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /f/backup/ && cd /f/backup/ && mv home windowsapps && exit" '
alias compc='rm -f main.exe main.o; if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then gcc -Wall -std=c11 main.c -o main.exe; else gcc -Wall -std=c11 main.c -o main.exe; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root && cp main.exe /tmp/runtime-root && (cd /tmp/runtime-root && ./main.exe); fi; else echo "Compilation failed"; fi'
alias compccc='rm -f main.exe main.moc; cp main.cpp main_tmp.cpp; if grep -q Q_OBJECT main_tmp.cpp; then if ! tail -n1 main_tmp.cpp | grep -q "main.moc"; then echo -e "\n#include \"main.moc\"" >> main_tmp.cpp; fi; moc main_tmp.cpp -o main.moc; status=$?; if [ $status -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; else echo "moc failed: consider moving your Q_OBJECT class to its own header or guarding correctly"; fi; else echo "No Q_OBJECT found, compiling normally"; if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I"C:/Qt/5.15.2/mingw81_64/include" -I"C:/Qt/5.15.2/mingw81_64/include/QtWidgets" -I"C:/Qt/5.15.2/mingw81_64/include/QtCore"; else PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig g++ -Wall -std=c++17 main_tmp.cpp -o main.exe $(pkg-config --cflags --libs Qt5Widgets Qt5Core Qt5Gui Qt5Network Qt5Concurrent) -fPIC -I/usr/include/x86_64-linux-gnu/qt5 -I/usr/include/x86_64-linux-gnu/qt5/QtWidgets -I/usr/include/x86_64-linux-gnu/qt5/QtCore; fi; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root && cp main.exe /tmp/runtime-root && (cd /tmp/runtime-root && ./main.exe); fi; else echo "Compilation failed"; fi; rm -f main_tmp.cpp'
alias compcc='rm -f main.exe; if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then csc /out:main.exe main.cs; else mcs -out:main.exe main.cs; fi; if [ $? -eq 0 ]; then if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then ./main.exe; else mono main.exe; fi; else echo "Compilation failed"; fi'
alias compcc='proj=$(basename "$(pwd)") && rm -f "$proj.exe" && mcs -r:System.Windows.Forms -r:System.Drawing -out:"$proj.exe" *.cs && mono "$proj.exe"'
alias getc='ftime2 && updates && sudo apt-get update && sudo apt-get install --no-install-recommends -y g++-mingw-w64 portaudio19-dev libportaudio2 libportaudiocpp0 build-essential qtbase5-dev qt5-qmake autoconf automake libtool-bin gettext gperf intltool libtool libxml-parser-perl python3 wget g++ git && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt-get update && sudo apt-get -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt-get install -f -y && sudo dpkg --configure -a && sudo apt-get install --no-install-recommends -y build-essential gcc g++ clang mono-devel dotnet-sdk-7.0 cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\b(c\+\+|csharp)\b" | awk '\''{print $1}'\'') && sudo apt-get install --no-install-recommends -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt-get install --no-install-recommends -y mingw-w64 && cd && getlibssl1 && wget -nc http://mirrors.kernel.org/ubuntu/pool/universe/g/glew/libglew2.1_2.1.0-4_amd64.deb && sudo dpkg -i libglew2.1_2.1.0-4_amd64.deb || sudo apt --fix-broken install -y && sudo apt-get install --no-install-recommends -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "6" | sudo -S apt-get update && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt-get install --no-install-recommends -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt-get install --no-install-recommends -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev mono-complete'
alias getc='ftime2 && updates && sudo apt-get update && sudo apt-get install --no-install-recommends -y g++-mingw-w64 portaudio19-dev libportaudio2 libportaudiocpp0 build-essential qtbase5-dev qt5-qmake autoconf automake libtool-bin gettext gperf intltool libtool libxml-parser-perl python3 wget g++ git && sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bak && sudo mkdir /var/lib/dpkg/info && sudo apt-get update && sudo apt-get -o Dpkg::Options::="--force-overwrite" install --reinstall -y $(dpkg -l | awk "/^ii/{print \$2}") && sudo apt-get install -f -y && sudo dpkg --configure -a && sudo apt-get install --no-install-recommends -y build-essential gcc g++ clang mono-devel cmake gdb valgrind make automake libtool autoconf pkg-config ninja-build git qtchooser qtbase5-dev qt5-qmake qtbase5-dev-tools libssh-dev libgtest-dev libboost-all-dev libevent-dev libdouble-conversion-dev libgoogle-glog-dev libgflags-dev libiberty-dev liblz4-dev liblzma-dev libsnappy-dev libjemalloc-dev libunwind-dev libfmt-dev libboost-context-dev clang-format lldb cppcheck lcov libcurl4-openssl-dev doxygen cscope strace ltrace linux-tools-common linux-tools-generic ccache meson splint flex bison clang-tidy check re2c gcovr exuberant-ctags gdb-multiarch llvm systemtap ddd binutils astyle uncrustify indent clang-tools coccinelle libcppunit-dev graphviz gnuplot openocd exuberant-ctags global gdbserver checkinstall fakeroot autotools-dev libclang-dev llvm-dev make-doc mercurial meld cmake-curses-gui libopencv-dev libpoco-dev libsfml-dev libcereal-dev libprotobuf-dev protobuf-compiler libspdlog-dev libhdf5-dev libarmadillo-dev libsoci-dev libsqlite3-dev libcapnp-dev libtclap-dev libxerces-c-dev nlohmann-json3-dev $(apt-cache search . | grep -Ei "\\b(c\\+\\+|csharp)\\b" | awk "{print \$1}") && sudo apt-get install --no-install-recommends -y qtcreator libqt5core5a libqt5gui5 qtbase5-dev drumstick-data drumstick-tools libdrumstick-dev libdrumstick-file2 libdrumstick-plugins libdrumstick-rt-backends libdrumstick-rt2 libdrumstick-widgets2 libcgal-dev libcgal-qt5-dev qcoro-doc qcoro-qt5-dev libjreen-qt5-dev libquotient-dev libqscintilla2-qt5-dev libqwt-qt5-dev libqwtmathml-qt5-dev libqwtplot3d-qt5-dev libsingleapplication-dev libsoqt520-dev libtelepathy-qt5-dev libudisks2-qt5-dev libqt6core5compat6-dev && sudo apt-get install --no-install-recommends -y mingw-w64 && cd && getlib && getlibssl1 && wget -nc http://mirrors.kernel.org/ubuntu/pool/universe/g/glew/libglew2.1_2.1.0-4_amd64.deb && sudo dpkg -i libglew2.1_2.1.0-4_amd64.deb || sudo apt --fix-broken install -y && sudo apt-get install --no-install-recommends -y libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon-x11-0 libasound2 libnss3 && sudo dpkg --purge --force-all gconf2-common gconf-service-backend gconf-service libgconf-2-4 && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "6" | sudo -S apt-get update && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y build-essential libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev libgdbm-dev liblzma-dev zlib1g-dev libdb-dev uuid-dev libxml2-dev libxslt1-dev libgmp-dev libnss3 && for i in {1..35}; do echo "Jerusalem"; done | sudo -S apt-get install --no-install-recommends -y libx11-xcb-dev libxcb1-dev libxcb-render0-dev libxcb-shm0-dev libxcb-dri3-dev libxcomposite1 libxdamage1 libxrandr2 libxtst6 libxss1 libasound2 && echo "6" | sudo -S apt-get install --no-install-recommends -y libwayland-client0 libwayland-cursor0 libwayland-egl1-mesa libxkbcommon0 libjpeg-dev libpng-dev libtiff-dev libfreetype6-dev libharfbuzz-dev libpixman-1-dev && sudo apt --fix-broken install -y && sudo dpkg --configure -a && echo "Jerusalem" | sudo -S apt-get install --no-install-recommends -y libqt6bodymovin6-dev libqt6charts6-dev libqt6core5compat6-dev libqt6datavisualization6-dev libqt6networkauth6-dev libqt6opengl6-dev libqt6quicktimeline6-dev libqt6sensors6-dev libqt6serialbus6-dev libqt6serialport6-dev libqt6shadertools6-dev libqt6svg6-dev libqt6virtualkeyboard6-dev libqt6webchannel6-dev libqt6websockets6-dev qcoro-qt6-dev qt6-3d-dev qt6-base-dev qt6-base-dev-tools qt6-base-private-dev qt6-connectivity-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-declarative-private-dev qt6-multimedia-dev qt6-pdf-dev qt6-positioning-dev qt6-quick3d-dev qt6-quick3d-dev-tools qt6-remoteobjects-dev qt6-scxml-dev qt6-tools-dev qt6-tools-dev-tools qt6-tools-private-dev qt6-wayland-dev qt6-wayland-dev-tools qt6-webengine-dev qt6-webengine-dev-tools qt6-webengine-private-dev qt6-webview-dev qtkeychain-qt6-dev mono-complete && sudo apt-get purge -y "dotnet-*" "aspnetcore-*" "netstandard-targeting-pack-2.1*" || true && sudo rm -rf /usr/share/dotnet && sudo mkdir -p /usr/lib/dotnet && curl -sSL https://dot.net/v1/dotnet-install.sh | sed "s/basename -b/basename/" | sudo bash -s -- --channel 5.0 --install-dir /usr/lib/dotnet --skip-non-versioned-files --no-path && curl -sSL https://dot.net/v1/dotnet-install.sh | sed "s/basename -b/basename/" | sudo bash -s -- --channel 6.0 --install-dir /usr/lib/dotnet --skip-non-versioned-files --no-path && curl -sSL https://dot.net/v1/dotnet-install.sh | sed "s/basename -b/basename/" | sudo bash -s -- --channel 7.0 --install-dir /usr/lib/dotnet --skip-non-versioned-files --no-path && curl -sSL https://dot.net/v1/dotnet-install.sh | sed "s/basename -b/basename/" | sudo bash -s -- --channel 8.0 --install-dir /usr/lib/dotnet --skip-non-versioned-files --no-path && curl -sSL https://dot.net/v1/dotnet-install.sh | sed "s/basename -b/basename/" | sudo bash -s -- --channel 9.0 --quality preview --install-dir /usr/lib/dotnet --skip-non-versioned-files --no-path && sudo ln -sf /usr/lib/dotnet/dotnet /usr/local/bin/dotnet'
alias sdks="dotnet --list-sdks"
alias saveweb2='cd /mnt/c/Users/micha/videos/webinars && docker run --rm -v /mnt/c/Users/micha/videos/webinars:/backup michadockermisha/backup:webinars2 sh -c "apk update && apk add --no-cache rsync && rsync -av /home/* /backup" && docker build -t michadockermisha/backup:webinars2 . && docker push michadockermisha/backup:webinars2 && rm -rf /mnt/c/Users/micha/videos/webinars/*'
alias slocal="cd /mnt/f/study/AI_and_Machine_Learning/Artificial_Intelligence/local"

alias sjs='cd /mnt/f/study/Dev_Toolchain/programming/frontend/javascript/projects'
alias fulldpkg='sudo killall -9 apt apt-get dpkg 2>/dev/null; sudo rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/cache/debconf/*.dat.lock; sudo rm -rf /var/cache/debconf/config.dat; sudo mkdir -p /var/cache/debconf; sudo touch /var/cache/debconf/config.dat; sudo dpkg --status-fd 13 --configure -a; for i in /var/lib/dpkg/info/*.list; do if [ ! -s "$i" ]; then sudo rm -f "$i"; fi; done; sudo dbus-daemon --system || true; sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old 2>/dev/null; sudo mkdir -p /var/lib/dpkg/info; sudo dpkg --configure -a; sudo apt-get -f install -y; sudo dpkg --add-architecture i386; sudo apt-get update -y --fix-missing; sudo apt-get install --reinstall apt dpkg debconf -y; sudo apt-get install --reinstall libc6 libc6:i386 libgcc-s1 libgcc-s1:i386 gcc-12-base gcc-12-base:i386 -y; sudo apt-get install --reinstall libgl1-mesa-glx libglx-mesa0 libgl1-mesa-dri mesa-vulkan-drivers libgl1-mesa-dri:i386 -y; sudo chmod 0700 /run/user/$(id -u) 2>/dev/null || true; sudo apt-get update -y; dpkg-query -l | grep "^..H" | awk "{print \$2}" | xargs -r sudo apt-get -y --force-yes install --reinstall; sudo apt-get install --reinstall -y $(dpkg -l | grep "^ii" | awk "{print \$2}"); sudo apt-get install --reinstall base-files base-passwd lsb-release libxml2 libxml2:i386 libstdc++6 libstdc++6:i386 -y; sudo apt-get install --reinstall libglib2.0-0 -y; sudo dpkg --configure -a; sudo apt-get -f install -y; dpkg-query -W -f="${Package} ${Status}\n" | grep -E "(half-installed|unpacked|half-configured|triggers-awaited|triggers-pending|reinstreq)" | awk "{print \$1}" | xargs -r sudo dpkg --remove --force-remove-reinstreq; sudo rm -f /var/lib/dpkg/info/libpaper* /var/lib/dpkg/info/ghostscript* /var/lib/dpkg/info/gimp* /var/lib/dpkg/info/libgs9* 2>/dev/null; sudo apt-get clean; sudo apt-get update -y; sudo apt-get upgrade -y --allow-downgrades; sudo apt-get dist-upgrade -y --allow-downgrades; sudo apt-get autoremove -y; sudo apt-get autoclean -y; sudo ldconfig'
alias restorelinux='cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /f/backup/linux && cd /f/backup/linux && mv home wsl && exit" '
alias sma="cd /mnt/f/study/management"

alias ssys="cd /mnt/f/study/exams/SysAdmin"
alias tre='stu && copy tree'
alias cdyt="cd /mnt/f/yt"
alias yts="cco /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/ytsearch"
alias gg='cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && sprofile && dkill && alert'
alias scomp="cd /mnt/f/study/Dev_Toolchain/programming/compile"

alias backuptuv='cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/data_analysis/TUVTECH && git remote set-url origin https://github.com/michaelunkai/TUVTECH.git && git add . && git commit -m "Initial commit" && git branch -M main && git push -u origin main'
alias restoretuv='cd /mnt/f/study/AI_and_Machine_Learning/Datascience/data_analysis && git clone https://github.com/michaelunkai/TUVTECH.git'
alias sbot="cd /mnt/f/study/Devops/automation/bots"
alias selden="cd /mnt/f/study/Dev_Toolchain/programming/python/apps/media/games/LaunchGameWithTools/WemodLassosSf4DeskN3SGtools/eldenring"

alias restoreproj='cd /mnt/f/study && rm -rf projects && mkdir -p projects && cd projects && apt install git gh -y && gh auth status || (gh auth login --web) && git clone https://github.com/michaelunkai/projects.git . && git submodule init || true && git submodule update --init --recursive || true && echo "Project has been restored from GitHub to /mnt/f/study/projects"'
alias backuproj='cd /mnt/f/study/projects && apt install git gh python3-pip -y && pip3 install git-filter-repo && git init && repo=$(basename "$PWD") && git submodule init || true && git submodule update || true && gh repo view michaelunkai/$repo || gh repo create michaelunkai/$repo --public --source=. --push && git remote get-url origin 2>/dev/null || git remote add origin https://github.com/michaelunkai/$repo.git && git add --all -f && git commit -m "Initial clean commit" --allow-empty && git filter-repo --path-glob "client_secret*.json" --path-glob "*.pickle" --path-glob "*google*.json" --path-glob "*youtube*.json" --path "python/youtube/Playlists/substoplaylist/*.py" --path "python/pyqt5Menus/GamesDockerMenu/gui/Modular/frontBack/f/client_secret.json" --invert-paths --force && git branch -M main && git remote add origin https://github.com/michaelunkai/$repo.git && git push -f -u origin main'
alias ghlog="gitoken && gh auth login"
alias wchrome="chromedriver --version && which chrome && chromedriver --version && which chromedriver"
alias getchrome='export DEBIAN_FRONTEND=noninteractive && echo "dash dash/sh boolean true" | sudo debconf-set-selections && sudo killall -9 apt apt-get dpkg 2>/dev/null; sudo rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/cache/debconf/*.dat.lock; sudo rm -rf /var/cache/debconf/config.dat; sudo mkdir -p /var/cache/debconf && sudo touch /var/cache/debconf/config.dat; sudo dpkg --status-fd 13 --configure -a; for i in /var/lib/dpkg/info/*.list; do [ ! -s "$i" ] && sudo rm -f "$i"; done; sudo dbus-daemon --system || true; sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old 2>/dev/null; sudo mkdir -p /var/lib/dpkg/info; sudo dpkg --configure -a; sudo apt-get -f install -y -o Dpkg::Options::="--force-confold"; sudo dpkg --add-architecture i386; sudo apt-get update -y --fix-missing; sudo apt-get install --reinstall -y apt dpkg debconf libc6 libc6:i386 libgcc-s1 libgcc-s1:i386 gcc-12-base gcc-12-base:i386 libgl1-mesa-glx libglx-mesa0 libgl1-mesa-dri mesa-vulkan-drivers libgl1-mesa-dri:i386 base-files base-passwd lsb-release libxml2 libxml2:i386 libstdc++6 libstdc++6:i386 libglib2.0-0 -o Dpkg::Options::="--force-confold"; sudo chmod 0700 /run/user/$(id -u) 2>/dev/null || true; dpkg-query -l | grep "^..H" | awk "{print \$2}" | xargs -r sudo apt-get -y install --reinstall -o Dpkg::Options::="--force-confold"; sudo dpkg --configure -a; sudo apt-get -f install -y -o Dpkg::Options::="--force-confold"; dpkg-query -W -f="\${Package} \${Status}\n" | grep -E "(half-installed|unpacked|half-configured|triggers-awaited|triggers-pending|reinstreq)" | awk "{print \$1}" | xargs -r sudo dpkg --remove --force-remove-reinstreq; sudo rm -f /var/lib/dpkg/info/libpaper* /var/lib/dpkg/info/ghostscript* /var/lib/dpkg/info/gimp* /var/lib/dpkg/info/libgs9* 2>/dev/null; sudo apt-get clean && sudo apt-get update -y && sudo apt-get upgrade -y --allow-downgrades && sudo apt-get dist-upgrade -y --allow-downgrades && sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo ldconfig && sudo apt update -y && sudo apt install -y zip unzip p7zip-full wget curl gnupg apt-transport-https -o Dpkg::Options::="--force-confold" && cd ~ && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb -o Dpkg::Options::="--force-confold" && ver=$(google-chrome --version | grep -oP "[0-9.]+" | head -1) && cd /tmp && wget -q "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$ver/linux64/chromedriver-linux64.zip" -O chromedriver.zip && unzip -qo chromedriver.zip && sudo mv -f chromedriver-linux64/chromedriver /usr/local/bin/chromedriver && sudo chmod +x /usr/local/bin/chromedriver && sudo rm -f /usr/bin/chromedriver || true && sudo ln -sf /usr/local/bin/chromedriver /usr/bin/chromedriver && sudo ln -sf $(which google-chrome) /usr/local/bin/chrome && echo "== Google Chrome ==" && google-chrome --version && which google-chrome && echo "== ChromeDriver ==" && chromedriver --version && which chromedriver && echo "== Chrome Alias ==" && chrome --version && which chrome'


alias wchrome='chromedriver --version && which chrome && chrome --version && which chromedriver'
alias games='cdf && cd /f/games'
alias gamesit="bash /mnt/f/study/shells/bash/scripts/Games2myg.sh"
alias games="cdf && cd /mnt/f/games"

alias cpahk="mv /mnt/f/Downloads/*.ahk* /mnt/f/study/Platforms/windows/autohotkey"
alias size='du -sh /mnt/c/wsl2/ubuntu /mnt/c/wsl2/ubuntu2 /mnt/c/wsl2/ubuntu3'
alias sizes='du -sh /mnt/c/wsl2/ubuntu /mnt/c/wsl2/ubuntu2 /mnt/c/wsl2/ubuntu3 && df -h /mnt/c'
alias size3='du -sh /mnt/c/wsl2/ubuntu{,2,3}'
alias fubuntu='echo "wsl --unregister ubuntu; wsl --unregister ubuntu2; wsl --unregister ubuntu3; wsl --import ubuntu C:\\wsl2\\ubuntu C:\\backup\\linux\\wsl\\ubuntu.tar; wsl --import ubuntu2 C:\\wsl2\\ubuntu2 C:\\backup\\linux\\wsl\\ubuntu.tar; wsl --import ubuntu3 C:\\wsl2\\ubuntu3 C:\\backup\\linux\\wsl\\ubuntu.tar"'
alias backupubu='echo "wsl --export ubuntu C:\\backup\\linux\\ubuntu.tar; wsl --export ubuntu2 C:\\backup\\linux\\ubuntu2.tar; wsl --export ubuntu3 C:\\backup\\linux\\ubuntu3.tar"'
alias fall='echo "wsl --unregister kali-linux; wsl --import kali-linux C:\\wsl2 C:\\backup\\linux\\wsl\\kalifull.tar; wsl --unregister ubuntu; wsl --unregister ubuntu2; wsl --unregister ubuntu3; wsl --import ubuntu C:\\wsl2\\ubuntu C:\\backup\\linux\\wsl\\ubuntu.tar; wsl --import ubuntu2 C:\\wsl2\\ubuntu2 C:\\backup\\linux\\wsl\\ubuntu.tar; wsl --import ubuntu3 C:\\wsl2\\ubuntu3 C:\\backup\\linux\\wsl\\ubuntu.tar"'
alias sshubuntu='ssh ubuntu@192.168.1.193'
alias sshubuntu2='ssh ubuntu@192.168.1.194'
alias sshubuntu3='ssh ubuntu@192.168.1.195'

alias redocker="cd && cp /mnt/f/study/shells/bash/scripts/redocker.sh ./a.sh && as"
alias slibre="cd /mnt/f/study/ide/Libre"
alias spmc="cd /mnt/f/study/Devops/automation/bots/MacroCreator"
alias down="cd /mnt/f/downloads"
alias mvahk="mv /mnt/f/downloads/*.ahk* /mnt/f/study/Platforms/windows/autohotkey"
alias mvpmc="mv /mnt/f/downloads/*.pmc* /mnt/f/study/Devops/automation/bots/MacroCreator"
alias crack="n '/mnt/f/study/Hacking/Piracy/Cracked software, games, movies, tv shows and more websites'"
alias spiracy="cd /mnt/f/study/Hacking/Piracy"
alias ser="cd /mnt/f/study/Dev_Toolchain/programming/Erlang"

alias clean3="bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu3.sh"
alias clean3="bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu3.sh"
alias movies='gc "https://chatgpt.com/g/g-p-67687a51e9fc8191bc0be1ffe1128ddc-media/c/684c5021-3758-8004-a598-35c6785f1ad5" && gc https://2ecbbd610840-trakt.baby-beamup.club/eyJsaXN0cyI6WyJ0cmFrdF9wb3B1bGFyIiwidHJha3RfdHJlbmRpbmciLCJ0cmFrdF9zZWFyY2giXSwiaWRzIjpbIm1pY2hhZWxvdnNreTU6dG8td2F0Y2g6cmFuayxhc2MiXSwiYWNjZXNzX3Rva2VuIjoiYjViZThlZDk3MzM0ZDQ5YWEwNTU0N2QzNjJmZmIwNzU1ZDg1MmQzMDBlYjI3NjgyMGNkMTkyYTg3Y2Y1ZTk4ZiIsInJlZnJlc2hfdG9rZW4iOiIxYmVmMWE3NzA4OWZkOTQwMmU2NTU3ZTU0YWU2OGU2YjEzODIxNzQwYWE1OGQ4MzdlYTQzNzFmMDNkZGQzNmQxIiwiZXhwaXJlcyI6MTc0OTkxMDg2OCwicmVtb3ZlUHJlZml4IjpmYWxzZX0=/configure && gc "https://trakt.tv/users/michaelovsky5/lists" && n /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/TV/a.sh && bash /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/movies/b.sh'
alias tv='gc "https://chatgpt.com/g/g-p-67687a51e9fc8191bc0be1ffe1128ddc-media/c/684c5021-3758-8004-a598-35c6785f1ad5" && gc https://2ecbbd610840-trakt.baby-beamup.club/eyJsaXN0cyI6WyJ0cmFrdF9wb3B1bGFyIiwidHJha3RfdHJlbmRpbmciLCJ0cmFrdF9zZWFyY2giXSwiaWRzIjpbIm1pY2hhZWxvdnNreTU6dG8td2F0Y2g6cmFuayxhc2MiXSwiYWNjZXNzX3Rva2VuIjoiYjViZThlZDk3MzM0ZDQ5YWEwNTU0N2QzNjJmZmIwNzU1ZDg1MmQzMDBlYjI3NjgyMGNkMTkyYTg3Y2Y1ZTk4ZiIsInJlZnJlc2hfdG9rZW4iOiIxYmVmMWE3NzA4OWZkOTQwMmU2NTU3ZTU0YWU2OGU2YjEzODIxNzQwYWE1OGQ4MzdlYTQzNzFmMDNkZGQzNmQxIiwiZXhwaXJlcyI6MTc0OTkxMDg2OCwicmVtb3ZlUHJlZml4IjpmYWxzZX0=/configure && gc "https://trakt.tv/users/michaelovsky5/lists" && n /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/TV/a.sh && bash /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/TV/a.sh'
alias trakt="cat '/mnt/f/study/networking/aggregating_web_content/Video_Aggregators/stremio/tutorial how to add trakt to stremio with my own lists and use it in samsung tv'"
alias rmsa="rms && as"
alias dstart="sudo service docker start || sudo dockerd > /dev/null 2>&1 &"
alias sst="cd /mnt/f/study/networking/aggregating_web_content/Video_Aggregators/stremio"

alias tv='gpip && pip install simplejson requests && gc "https://chatgpt.com/g/g-p-67687a51e9fc8191bc0be1ffe1128ddc-media/c/684c5021-3758-8004-a598-35c6785f1ad5" && gc https://2ecbbd610840-trakt.baby-beamup.club/eyJsaXN0cyI6WyJ0cmFrdF9wb3B1bGFyIiwidHJha3RfdHJlbmRpbmciLCJ0cmFrdF9zZWFyY2giXSwiaWRzIjpbIm1pY2hhZWxvdnNreTU6dG8td2F0Y2g6cmFuayxhc2MiXSwiYWNjZXNzX3Rva2VuIjoiYjViZThlZDk3MzM0ZDQ5YWEwNTU0N2QzNjJmZmIwNzU1ZDg1MmQzMDBlYjI3NjgyMGNkMTkyYTg3Y2Y1ZTk4ZiIsInJlZnJlc2hfdG9rZW4iOiIxYmVmMWE3NzA4OWZkOTQwMmU2NTU3ZTU0YWU2OGU2YjEzODIxNzQwYWE1OGQ4MzdlYTQzNzFmMDNkZGQzNmQxIiwiZXhwaXJlcyI6MTc0OTkxMDg2OCwicmVtb3ZlUHJlZml4IjpmYWxzZX0=/configure && gc "https://trakt.tv/users/michaelovsky5/lists" && n /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/TV/a.sh && bash /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/TV/a.sh'
alias movies='gc "https://chatgpt.com/g/g-p-67687a51e9fc8191bc0be1ffe1128ddc-media/c/684c5021-3758-8004-a598-35c6785f1ad5" && gc https://2ecbbd610840-trakt.baby-beamup.club/eyJsaXN0cyI6WyJ0cmFrdF9wb3B1bGFyIiwidHJha3RfdHJlbmRpbmciLCJ0cmFrdF9zZWFyY2giXSwiaWRzIjpbIm1pY2hhZWxvdnNreTU6dG8td2F0Y2g6cmFuayxhc2MiXSwiYWNjZXNzX3Rva2VuIjoiYjViZThlZDk3MzM0ZDQ5YWEwNTU0N2QzNjJmZmIwNzU1ZDg1MmQzMDBlYjI3NjgyMGNkMTkyYTg3Y2Y1ZTk4ZiIsInJlZnJlc2hfdG9rZW4iOiIxYmVmMWE3NzA4OWZkOTQwMmU2NTU3ZTU0YWU2OGU2YjEzODIxNzQwYWE1OGQ4MzdlYTQzNzFmMDNkZGQzNmQxIiwiZXhwaXJlcyI6MTc0OTkxMDg2OCwicmVtb3ZlUHJlZml4IjpmYWxzZX0=/configure && gc "https://trakt.tv/users/michaelovsky5/lists" && gpip && pip install simplejson requests &&  n /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/Movies/b.sh && bash /mnt/f/backup/windowsapps/Credentials/trakt/uploadtolist/movies/b.sh'
alias mvapk="mv /mnt/f/downloads/*.apk* /mnt/f/backup/windowsapps/APKS"
alias mvpy="mv /mnt/f/downloads/*.py* ."
alias savedg='cd /mnt/f/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c '\''apk add rsync && rsync -aP /home/* /f/backup/gamesaves && exit'\'''
alias comb='cp -r /mnt/f/study/Dev_Toolchain/programming/python/apps/CombineProject2onefile/a.py . && py a.py &&  nano app.py && py app.py'
alias folders2='bash /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts/folders2.sh/folders2.sh'
alias prompt="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/prompts"
alias sdata="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Datascience/databases"
alias snvidia="cd /mnt/f/study/AI_ML/nvidia"
alias sizes='du -sh /mnt/c/wsl2/ubuntu /mnt/c/wsl2/ubuntu2 && df -h /mnt/c'
alias sbackup="cd /mnt/c/study/devops/backup"
alias smyg="cd /mnt/f/backup/windowsapps/installed/myapps/compiled_python/myg"
alias ssearch="cd /mnt/f/study/WebBuilding/Tools/search_engines"
alias skube="cd /mnt/f/study/Service_Mesh_Orchestration/Orchestration/kubernetes" 
alias sdis="cd /mnt/f/study/Distributed_Systems"
alias iac="cd /mnt/f/study/devops/Infrastructure_as_Code"
alias mvit="bash /mnt/f/study/shells/bash/scripts/mvit.sh"
alias cicd="cd /mnt/f/study/devops/CI-CD"
alias sautu="cd /mnt/f/study/devops/automation"
alias sob="cd /mnt/f/study/Observability"
alias smon="cd /mnt/f/study/Observability/monitoring"
alias snot="cd /mnt/f/study/Observability/notifications"
alias sst="cd /mnt/f/study/Storage_and_Filesystems"
alias smicro="cd /mnt/f/study/Service_Mesh_Orchestration/microservices"
alias sde="cd /mnt/c/study/devops"
alias scrm="cd /mnt/f/study/Enterprise_Apps/crm"
alias ssap="cd /mnt/f/study/Enterprise_Apps/sap"
alias sai="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence"
alias menu="py /mnt/f/study/Dev_Toolchain/programming//python/apps/pyqt5menus/DockerMenu/noGui/a.py/a.py"
alias sapps="cd /mnt/f/study/Dev_Toolchain/programming//python/apps"
alias spython="cd /mnt/f/study/Dev_Toolchain/programming//python"
alias conf2="n /mnt/c/users/micha/.wslconfig"
alias sdev="cd /mnt/f/study/Dev_Toolchain"

alias scl="cd /mnt/f/study/AI_ML/AI_and_Machine_Learning/Artificial_Intelligence/Claude"

alias sprog="cd /mnt/f/study/Dev_Toolchain/programming/"

alias myg="psw myg"
alias changepath='f(){ OLD_ESC=$(echo "$1" | sed "s/[[\.*^$()+{}|]/\\\\&/g"); NEW_ESC=$(echo "$2" | sed "s/[[\.*^$()+{}|]/\\\\&/g"); if grep -q "$OLD_ESC" ~/.bashrc; then sed -i "s|$OLD_ESC|$NEW_ESC|g" ~/.bashrc; else echo "export PATH=\"$2:\$PATH\"" >> ~/.bashrc; fi && echo -e "\033[32mSuccessfully updated path from '\''$1'\'' to '\''$2'\'' in bash profile\033[0m" && source ~/.bashrc; }; f'
alias clean3='bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu4.sh'
alias scon="cd /mnt/f/study/containers"

alias recents="gc https://claude.ai/recents"
alias redocker='sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose docker-compose-plugin docker-buildx-plugin 2>/dev/null || true && sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release && sudo mkdir -p /etc/apt/keyrings && sudo rm -f /etc/apt/keyrings/docker.gpg && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin && sudo usermod -aG docker $USER && sudo service docker start && newgrp docker'
alias cursor="psw cursor"
alias sbaas="cd /mnt/f/study/cloud/Baas"
alias smygm="cd /mnt/f/study/Dev_Toolchain/programming//python/apps/pyqt5menus/GamesDockerMenu/nogui/new"
alias gg="dlog && cd /mnt/f/study && docker build -t michadockermisha/backup:study . && docker push michadockermisha/backup:study && sprofile && dkill && alert"
alias dlog="bash /mnt/f/backup/windowsapps/Credentials/docker/creds.ps1"
alias backitup='t(redocker && bash /mnt/f/backup/windowsapps/Credentials/docker/creds.ps1 && sprofile && backupapps && gg && backupwsl)'

alias dlog="bash /mnt/f/backup/windowsapps/Credentials/docker/creds.sh"
alias backitup=" bash /mnt/f/backup/windowsapps/Credentials/docker/creds.ps1 && sprofile && backupapps && gg && backupwsl"
alias backitup=' bash /mnt/f/backup/windowsapps/Credentials/docker/creds.sh && sprofile && backupapps && gg && backupwsl'
alias before="psw before"
alias mvps="mv /mnt/f/downloads/*.ps1* /mnt/f/study/shells/powershell/scripts"
alias backitup=' bash /mnt/f/backup/windowsapps/Credentials/docker/creds.sh && sprofile && backupapps && gg && savegames && backupwsl'
alias mvbs="mv /mnt/f/downloads/*.vbs* /mnt/f/study/Platforms/windows/VBScript"
alias mvbat="mv /mnt/f/downloads/*.bat* /mnt/f/study/Platforms/windows/bat"
alias down='cd /mnt/f/downloads && ls'
alias mvcmd="mv /mnt/f/downloads/*.cmd* /mnt/f/study/shells/CMD"
alias sahk="cd /mnt/f/study/Platforms/windows/autohotkey/mymainahk"
alias redocker2="sudo rm -f /usr/local/lib/docker/cli-plugins/docker-buildx && sudo apt update && sudo apt install -y docker-buildx-plugin && unset DOCKER_BUILDKIT && sed -i '/export DOCKER_BUILDKIT=0/d' ~/.bashrc && sudo systemctl restart docker"
alias cpyt="cp /mnt/f/backup/windowsapps/Credentials/youtube/client_secret.json ."
alias clean3="bash /mnt/f/study/shells/bash/scripts/CleanWSL2ubu3.sh"
export PATH="/mnt/c/Users/micha:$PATH"
alias cc4="t(clean3 && redocker && check && gg)"
alias redocker='sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-compose docker-compose-plugin docker-buildx-plugin 2>/dev/null || true && sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg lsb-release && sudo mkdir -p /etc/apt/keyrings && sudo rm -f /etc/apt/keyrings/docker.gpg && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin && sudo usermod -aG docker $USER && sudo service docker start && newgrp docker && apt install docker-buildx-plugin -y'
alias cpath="changepath  /mnt/c/Users/micha/  /mnt/c/Users/micha/ && changepath  /mnt/c/Users/micha/  /mnt/c/Users/micha/ && brc2 && brc2" 
alias cpath="changepath  /mnt/c/Users/micha/  /mnt/c/Users/micha/ && changepath  /mnt/c/Users/Administrator/  /mnt/c/Users/micha/ && brc2 && brc2" 
alias github='gc https://github.com/Michaelunkai?tab=repositories'
alias conf2='n /mnt/c/users/misha/.wslconfig'

alias mvps='mv /mnt/f/downloads/*.ps1* .'
alias gitit='git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; (git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b main); git add -A; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files"); (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"); (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public 2>/dev/null && git push -u origin main)); rmgit 2>/dev/null || true'
alias sproxmox="cd /mnt/f/study/Systems_Virtualization/virtualmachines/proxmox"

alias myrepos="gh repo list --limit 9999 --json name -q '.[].name'"
alias gits7='stu && find . -maxdepth 7 -mindepth 7 -type d -exec bash -c '\''cd "{}" && git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; (git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b main); git add -A; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files"); (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"); (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public 2>/dev/null && git push -u origin main)); rmgit 2>/dev/null || true'\'' \;'
alias gits6='stu && find . -maxdepth 7 -mindepth 6 -type d -print0 | xargs -0 -P $(nproc) -I {} bash -c '\''cd "{}" && git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; (git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b main); git add -A; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files"); (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"); (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public 2>/dev/null && git push -u origin main)); rmgit 2>/dev/null || true'\'''
alias gits5='stu && find . -maxdepth 7 -mindepth 5 -type d -not -path "*.git*" -print0 | xargs -0 -P $(nproc) -I {} bash -c '\''dir="{}"; if [ -w "$dir" ] && [ -d "$dir" ]; then cd "$dir" || { echo "Error: Cannot change directory to $dir" >&2; exit 1; }; rm -f .git/index.lock 2>/dev/null; find . -type d -name ".git" -exec rm -rf {} + 2>/dev/null; git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; if ! (git rev-parse --is-inside-work-tree >/dev/null 2>&1); then git init -b main || { echo "Error: Failed to init Git in $dir" >&2; exit 1; }; fi; git add -A || { echo "Error: git add failed in $dir" >&2; exit 1; }; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files") || { echo "Warning: git commit failed in $dir" >&2; }; (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git") 2>/dev/null || { echo "Warning: Git remote setup failed in $dir" >&2; }; (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public >/dev/null 2>&1 && git push -u origin main)) || { echo "Warning: Git push failed in $dir" >&2; }; rm -rf .git/index.lock 2>/dev/null || true; else echo "Skipping $dir: Not writable, accessible, or valid directory" >&2; fi'\'''

alias gits4='stu && rmgit && find . -maxdepth 7 -mindepth 4 -type d -not -path "*.git*" -print0 | xargs -0 -P $(nproc) -I {} bash -c '\''dir="{}"; if [ -w "$dir" ] && [ -d "$dir" ]; then cd "$dir" || { echo "Error: Cannot change directory to $dir" >&2; exit 1; }; rm -f .git/index.lock 2>/dev/null; find . -type d -name ".git" -exec rm -rf {} + 2>/dev/null; git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; if ! (git rev-parse --is-inside-work-tree >/dev/null 2>&1); then git init -b main || { echo "Error: Failed to init Git in $dir" >&2; exit 1; }; fi; git add -A || { echo "Error: git add failed in $dir" >&2; exit 1; }; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files") || { echo "Warning: git commit failed in $dir" >&2; }; (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git") 2>/dev/null || { echo "Warning: Git remote setup failed in $dir" >&2; }; (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public >/dev/null 2>&1 && git push -u origin main)) || { echo "Warning: Git push failed in $dir" >&2; }; rm -rf .git/index.lock 2>/dev/null || true; else echo "Skipping $dir: Not writable, accessible, or valid directory" >&2; fi'\'''
alias gits3='stu && rmgit && find . -maxdepth 7 -mindepth 3 -type d -not -path "*.git*" -print0 | xargs -0 -P $(nproc) -I {} bash -c '\''dir="{}"; if [ -w "$dir" ] && [ -d "$dir" ]; then cd "$dir" || { echo "Error: Cannot change directory to $dir" >&2; exit 1; }; rm -f .git/index.lock 2>/dev/null; find . -type d -name ".git" -exec rm -rf {} + 2>/dev/null; git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)")"; if ! (git rev-parse --is-inside-work-tree >/dev/null 2>&1); then git init -b main || { echo "Error: Failed to init Git in $dir" >&2; exit 1; }; fi; git add -A || { echo "Error: git add failed in $dir" >&2; exit 1; }; (git diff --cached --quiet || git commit -m "Auto commit $(date) - updated/deleted files") || { echo "Warning: git commit failed in $dir" >&2; }; (git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git") 2>/dev/null || { echo "Warning: Git remote setup failed in $dir" >&2; }; (git push --force origin main 2>/dev/null || (gh repo create "$USERNAME/$REPO_NAME" --public >/dev/null 2>&1 && git push -u origin main)) || { echo "Warning: Git push failed in $dir" >&2; }; rm -rf .git/index.lock 2>/dev/null || true; else echo "Skipping $dir: Not writable, accessible, or valid directory" >&2; fi'\'''
alias rmrepos='GHUSER="Michaelunkai" && printf "%s\0" 1 2 3 bad logs Cache CachedData CachedProfilesData DawnGraphiteCache Crashpad .qodo tasKiller tmp test demo draft example output a b.py c d e f g R B VEN_144D_DEV_A80A VEN_14C3_DEV_0616 VEN_1022_DEV_1668 Drivers EFI Boot 9.0.7 9.0.6 8.0.17 build resources locales af-ZA am-ET ar-SA as-IN az-Latn-AZ bg-BG bn-IN bs-Latn-BA ca-ES ca-ES-valencia cs-CZ da-DK de-DE el-GR en-GB en-US es-ES es-MX et-EE eu-ES fa-IR fi-FI fil-PH fr-CA fr-FR ga-IE gd-GB gl-ES he-IL hi-IN hr-HR hu-HU hy-AM id-ID is-IS it-IT ja-JP ka-GE kk-KZ km-KH kn-IN ko-KR ky-KZ lt-LT lv-LV mk-MK mn-MN ms-MY nb-NO nl-NL pl-PL pt-BR ro-RO ru-RU sk-SK sl-SI sr-SP sv-SE th-TH tr-TR uk-UA uz-UZ vi-VN zh_CN zh_TW Top_10_Ways_to_Use_ChatGPTs_Code_Interpreter.txt top_10_cluade_pros_over_chatgpt Top_10_ChatGPT_Pros_Over_Claude Prompt_Engineering_Principles.txt Prompt_Engineering_Article.txt Anthropic_Publishes_the_System_Prompts_Powering_Claude_AI_Models.txt Unveiling-Hermes-3-The-First-Full-Parameter-Fine-Tuned-Llama-3.1-405B-Model-is-on-Lambda-s-Cloud.pdf SearchGPT_Exclusive_Preview_OpenAI_Search_Engine.txt Transcribing_Hebrew_Audio_Files_Whisper-3_Groq.txt liner_that_clones_YOLOv5-_enters_its_directory-_sets_up_and_activates_a_virtual_environment-_upgrade step-by-step_guide_to_installing_and_configuring_Nginx_as_a_reverse_proxy_server_in_ubuntu_with_ngin Setting_Up_and_Running_vLLM_on_Ubuntu_Using_Python-_Virtualenv-_and_EleutherAIs_GPT_Models Setting_Up_and_Running_the_Hugging_Face_Transformers_Library_in_Ubuntu_with_Python-_Virtual_Environm -- | xargs -0 -I{} gh repo delete "$GHUSER/{}" --confirm'


alias gits='stu && rmgit && find . -maxdepth 7 -mindepth 0 -type d -not -path "*/.*" -print0 | xargs -0 -P $(nproc) -I {} bash -c "dir=\"{}\"; [ -w \"\$dir\" ] && [ -d \"\$dir\" ] || { echo \"Skipping \$dir: Not accessible\" >&2; exit 0; }; cd \"\$dir\" || { echo \"Error: Cannot cd to \$dir\" >&2; exit 1; }; rm -f .git/index.lock .git/HEAD.lock 2>/dev/null; [ -d .git ] && rm -rf .git 2>/dev/null; git config --global user.name \"Michaelunkai\" 2>/dev/null; git config --global user.email \"Michaelunkai@users.noreply.github.com\" 2>/dev/null; git config --global --add safe.directory \"\$(pwd)\" 2>/dev/null; git config --global core.autocrlf false 2>/dev/null; USERNAME=\"Michaelunkai\"; REPO_NAME=\"\$(basename \"\$(pwd)\" | tr \" \" \"-\" | tr \"[:upper:]\" \"[:lower:]\")\"; git init -b main >/dev/null 2>&1 || { echo \"Git init failed in \$dir\" >&2; exit 1; }; git config core.filemode false 2>/dev/null; if [ \"\$(find . -maxdepth 1 -type f | wc -l)\" -gt 0 ] || [ \"\$(find . -mindepth 2 -type f | wc -l)\" -gt 0 ]; then git add -A 2>/dev/null || git add . 2>/dev/null || git add * 2>/dev/null || { echo \"All git add methods failed in \$dir, creating empty commit\" >&2; git commit --allow-empty -m \"Empty repo init \$(date +\"%Y-%m-%d %H:%M:%S\")\" >/dev/null 2>&1; }; git status >/dev/null 2>&1 && { git diff --cached --quiet >/dev/null 2>&1 || git commit -m \"Auto commit \$(date +\"%Y-%m-%d %H:%M:%S\") - batch update\" >/dev/null 2>&1; }; else git commit --allow-empty -m \"Empty directory init \$(date +\"%Y-%m-%d %H:%M:%S\")\" >/dev/null 2>&1; fi; git remote remove origin 2>/dev/null; git remote add origin \"https://github.com/\$USERNAME/\$REPO_NAME.git\" 2>/dev/null; git branch -M main 2>/dev/null; git push --set-upstream origin main --force >/dev/null 2>&1 || { gh repo create \"\$USERNAME/\$REPO_NAME\" --public >/dev/null 2>&1 && sleep 2 && git push --set-upstream origin main --force >/dev/null 2>&1; } || echo \"Push failed for \$dir\" >&2; rm -f .git/*.lock 2>/dev/null; echo \"✓ \$dir\"" && stu && rmgit'

alias gitit='rm -f .git/index.lock .git/HEAD.lock 2>/dev/null; git config --global user.name "Michaelunkai" 2>/dev/null; git config --global user.email "Michaelunkai@users.noreply.github.com" 2>/dev/null; git config --global --add safe.directory "$(pwd)" 2>/dev/null; git config --global init.defaultBranch main 2>/dev/null; git config --global core.autocrlf false 2>/dev/null; USERNAME="Michaelunkai"; REPO_NAME="$(basename "$(pwd)" | tr " " "-" | tr "[:upper:]" "[:lower:]" | sed "s/[^a-z0-9-]//g")"; git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { git init -b main >/dev/null 2>&1 && git config core.filemode false 2>/dev/null; }; if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 0 ] || [ "$(find . -mindepth 2 -type f | wc -l)" -gt 0 ]; then git add -A >/dev/null 2>&1 || git add . >/dev/null 2>&1 || git add * >/dev/null 2>&1 || { echo "All git add methods failed, creating empty commit"; git commit --allow-empty -m "Empty repo init $(date +"%Y-%m-%d %H:%M:%S")" >/dev/null 2>&1; }; git status >/dev/null 2>&1 && { git diff --cached --quiet >/dev/null 2>&1 || git commit -m "Auto commit $(date +"%Y-%m-%d %H:%M:%S") - batch update" >/dev/null 2>&1; }; else git commit --allow-empty -m "Empty directory init $(date +"%Y-%m-%d %H:%M:%S")" >/dev/null 2>&1; fi; git remote remove origin 2>/dev/null; git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git" 2>/dev/null; git branch -M main 2>/dev/null; git push --set-upstream origin main --force >/dev/null 2>&1 || { gh repo create "$USERNAME/$REPO_NAME" --public >/dev/null 2>&1 && sleep 3 && git push --set-upstream origin main --force >/dev/null 2>&1; } || echo "Push failed, but repo processed"; rm -f .git/*.lock 2>/dev/null; rmgit 2>/dev/null || true; echo "✓ Processed: $(pwd)"'

alias gitt='rmgit && REPO_NAME=$(basename "$PWD") && git init && echo "Last updated: $(date)" > .last_update && git add -A && git commit -m "auto update $(date)" && (git remote | grep -q origin || git remote add origin https://github.com/Michaelunkai/$REPO_NAME.git) && git branch -M main && (git push -u origin main 2>/dev/null || (gh repo create $REPO_NAME --public && git push -u origin main)) && rmgit'
alias gg2="ppsw gg"
alias gitt='rmgit && REPO_NAME=$(basename "$PWD" | tr -d " ") && git init && echo "Last updated: $(date)" > .last_update && git add -A && git commit -m "auto update $(date)" && (git remote get-url origin >/dev/null 2>&1 || git remote add origin https://github.com/Michaelunkai/$REPO_NAME.git) && git branch -M main && (git push -u origin main 2>/dev/null || (gh repo create $REPO_NAME --public --source=. --remote=origin && git push -u origin main)) && rmgit'
alias sfin="cd /mnt/f/study/Enterprise_Apps/Business/finance"
alias gc="ppsw gcl"
alias ggenv='echo "GEMINI_API_KEY=$1" > .env && echo "✓ Created .env with Gemini API key in $(pwd)"'
alias ggem="gemini --yolo"
alias ggemini="sudo apt-get install -y npm nodejs && sudo npm install -g @google/gemini-cli && gemini --yolo"
alias ggapi="gc https://aistudio.google.com/app/apikey"
alias gjira="bash /mnt/f/study/Enterprise_Apps/management/Workflow_Management/jira/AutoSetupJiraUbuntu.sh"
alias ccwsl="bash /mnt/f/study/shells/bash/scripts/cleanWSL2/cleanWSL2reinstalldocker.sh"
alias ggemini='sudo apt remove --purge nodejs npm libnode-dev node-* -y 2>/dev/null; sudo apt autoremove -y 2>/dev/null; curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs && sudo npm install -g @google/gemini-cli && gemini --yolo'
alias ggenv='f(){ echo "GEMINI_API_KEY=$1" > .env && echo "✓ Created .env with Gemini API key in $(pwd) $1"; }; f'
alias clean3="bash /mnt/f/study/shells/bash/scripts/CleanWSL2/CleanWSL2ubu3.sh"
alias cpenv="cp /root/.env ."
alias glama3='update && cd && curl -fsSL https://ollama.com/install.sh | sh && sleep 5 && ollama run llama3.3 && docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main && gc http://localhost:8080'
alias term='update && sudo apt-get install --reinstall libicu70 && bash /mnt/f/study/shells/bash/scripts/ngrokTerminal.sh && gmail'
alias cpenv2=" cp /mnt/f/downloads/.env ."
alias tovgit='f() { git add . && git commit -m "$1" && git push --force-with-lease origin main; }; f'
alias cpenv2='cp /home/.env .'
alias term2="ccwsl && sudo apt remove --purge nodejs npm libnode-dev node-* -y 2>/dev/null; sudo apt autoremove -y 2>/dev/null; curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs && sudo npm install -g @google/gemini-cli && term"
alias term='update && sudo apt-get install --reinstall libicu70 && bash /mnt/f/study/shells/bash/scripts/ngrokTerminal.sh'
