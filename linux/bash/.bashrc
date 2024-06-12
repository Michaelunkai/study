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



alias ds='docker search'
alias dps='docker ps --size'
alias dpsa='docker ps -a --size'
alias dim='docker images'
alias built='docker build -t'
alias dp='docker push'
alias drun='docker run -v /mnt/c/:/c/ -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --name'
alias dr='docker exec -it'
alias drc='docker rm -f'
alias dri='docker rmi -f'
alias dc='docker commit'

alias dkill='docker stop $(docker ps -aq) || true && docker rm $(docker ps -aq) || true && ( [ "$(docker ps -q)" ] || docker rmi $(docker images -q) || true ) && ( [ "$(docker images -q)" ] || docker system prune -a --volumes --force ) && docker network prune --force || true'

alias commit='bash /mnt/c/study/docker/files/scripts/commit.sh'
alias push='docker images --format '{{.Repository}}:{{.Tag}}' | xargs -L1 docker push'


alias containerip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "

alias killc='docker stop $(docker ps -q)
docker rm $(docker ps -aq)'

alias dcu='docker-compose up -d'


alias backupwsl='cd /mnt/c/backup/linux/wsl && built michadockermisha/backup:wsl . && docker push michadockermisha/backup:wsl'
alias backupst='stu && built michadockermisha/backup:study . && docker push michadockermisha/backup:study'
alias backupapps='cd /mnt/c/backup/windowsapps && built michadockermisha/backup:windowsapps . && docker push michadockermisha/backup:windowsapps'



alias backitup='backupapps && backupst && backupwsl'

#restore

alias restoreapps='drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup/ && mv home windowsapps && exit" '

alias restorelinux='cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/linux && cd /c/backup/linux && mv home wsl && exit" '


alias restoreasus='cdbackup && drun asus michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup && mv home asus && exit" '


alias restorebackup='c && mkdir backup && drun windowsapps michadockermisha/backup:windowsapps sh -c "apk add rsync && rsync -aP /home /c/backup/ && cd /c/backup/ && mv home windowsapps && exit" && cdbackup && mkdir linux && drun linux michadockermisha/backup:wsl sh -c "apk add rsync && rsync -aP /home /c/backup/linux && cd /c/backup/linux && mv home wsl && exit" '


alias ps='docker ps -a --size && docker ps --size && docker images'
alias cc='clear'
alias brc='gedit ~/.bashrc'
alias brc1='source ~/.bashrc && source /root/.bashrc'
alias brc2='brc1 && rsync -aP /root/.bashrc /mnt/c/backup/linux/wsl/alias.txt && rsync -aP /root/.bashrc ~/.bashrc && rsync -aP /root/.bashrc /mnt/c/study/linux/bash/.bashrc'
alias updates='sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y'
alias update='apt update'
alias os='cat /etc/os-release'
alias cpbash='sudo cp /root/.bashrc /home/kali/.bashrc'

alias gatway="netstat -rn | grep '^0.0.0.0'"

alias ssk='ssh-keygen -t rsa -b 2048 && ssh-copy-id'
alias sshprox="ssh root@192.168.1.222"
alias sshubuntu="ssh ubuntu@192.168.1.193"


alias c='cd /mnt/c/'
alias stu='cd /mnt/c/study'
alias cdwsl='cd /mnt/c/backup/linux/wsl'
alias games='cd /mnt/c/games'
alias down='cd /mnt/c/Users/micha/Downloads'
alias pfiles="c && cd 'Program Files'"
alias wapps='pfiles && cd WindowsApps'
alias cdbackup="c && cd backup"
alias cdapps="cd /mnt/c/backup/windowsapps"


alias scloud='cd /mnt/c/study/cloud'
alias sdocker='cd /mnt/c/study/docker'
alias sfirewall='cd /mnt/c/study/firewall'
alias slinux='cd /mnt/c/study/linux'
alias smonitoring='cd /mnt/c/study/monitoring'
alias spowershell='cd /mnt/c/study/powershell'
alias sssh='cd /mnt/c/study/ssh'
alias sdatabases='cd /mnt/c/study/datascience/databases'
alias sgit='cd /mnt/c/study/git'
alias smalware='cd /mnt/c/study/malware'
alias snetworking='cd /mnt/c/study/networking'
alias spython='cd /mnt/c/study/programming/python'
alias svirtualmachines='cd /mnt/c/study/virtualmachines'
alias sbash='cd /mnt/c/study/linux/bash'
alias sexams='cd /mnt/c/study/exams'
alias skubernetes='cd /mnt/c/study/kubernetes'
alias swindows='cd /mnt/c/study/windows'
alias sproxmox="cd /mnt/c/study/virtualmachines/proxmox"
alias sserver="cd /mnt/c/study/windows/server"



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


alias gl='apt install gh -y && gh auth login'
alias gadd=' git add . && git commit -m "commit" && git push -u origin main'


alias fkali='echo "wsl --unregister kali-linux; wsl --import kali-linux C:\wsl2 C:\backup\linux\wsl\kalifull.tar"'


alias backupw='echo "wsl --export kali-linux C:\backup\linux\kalifull.tar; wsl --export ubuntu C:\backup\linux\ubuntu.tar"' 

alias wupdates='cat "/mnt/c/study/powershell/scripts/windowsupdates.ps1" && cp "/mnt/c/study/powershell/scripts/windowsupdates.ps1 /mnt/c/users/micha/updates.ps1"'


alias getsnap='sudo apt install snapd -y && updates && systemctl enable --now snapd.apparmor'

alias getdocker='sudo apt update -y && sudo apt upgrade -y && \
  sudo apt install -y -qq docker.io && \
  sudo usermod -aG docker $USER && newgrp docker && sudo service docker start && \
  sudo apt install -y -qq docker.io && sudo usermod -aG docker $USER && \
  newgrp docker && sudo service docker start && sudo sh -c "sudo setfacl -m user:$USER:rw /var/run/docker.sock && sudo apt update -y && sudo apt upgrade -y'

alias getpython='sudo apt install -y -qq python3 python3-pip pyinstaller && \
  sudo apt update -y && sudo apt upgrade -y && \
  sudo apt install -y -qq sshpass && sudo apt autoremove -y -qq'
  
alias getpycharm=' wget https://download.jetbrains.com/python/pycharm-community-2021.2.3.tar.gz && tar -xzf pycharm-community-2021.2.3.tar.gz && sudo mv pycharm-community-2021.2.3 /opt/ && cd /opt/pycharm-community-2021.2.3/bin && ./pycharm.sh'


alias getext='apt install tesseract-ocr -y'
alias text=tesseract


alias basicinstall='sudo apt install -y -qq wireless-tools kali-win-kex && net-tools gedit kali-desktop-xfce curl wget jq libgtk-3-dev libcurl4-openssl-dev -y'

# Install SSH
alias getssh='sudo apt install -y -qq openssh-server && sudo service ssh start && sudo apt install -y -qq sshpass'

  
export DOCKER_BUILDKIT=1
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"


alias ed='echo $DISPLAY'
alias x11='export DISPLAY=:0'

#system
alias reset='echo "systemreset.exe" '
alias conf=' nano /etc/wsl.conf'
alias conf2='nano /mnt/c/Users/micha/.wslconfig'
alias cleanwsl=' cat "/mnt/c/study/powershell/scripts/optimizewsl.ps1" && cp /mnt/c/study/powershell/scripts/optimizewsl.ps1 /mnt/c/Users/micha/ccwsl.ps1'
alias ccwsl='echo "wsl --shutdown; ./ccwsl.ps1; wsl"'
alias poweroff='shutdown.exe /s /t 0'
alias reboot='shutdown.exe /r /t 0'


#firefox/chrome
alias gc="cmd.exe /c start chrome"
alias ff='cmd.exe /c start firefox'
alias ffd='ff https://hub.docker.com/repository/docker/michadockermisha/backup/tags?page=1&ordering=last_updated'
alias yt='gc youtube.com'
alias gt='gc github.com'
alias gpt='ff https://chat.openai.com/'
alias pocket='ff https://getpocket.com/saves?src=navbar'
alias 1337='ff https://1337x.to/home/'
alias gmail='ff https://mail.google.com/mail/u/0/'
alias ytlater='gc https://www.youtube.com/playlist?list=WL'
alias gamespot='ff https://www.gamespot.com/'
alias awsweb="gc https://us-east-1.console.aws.amazon.com/console/home?region=us-east-1#"

export PATH=$PATH:/snap/bin
export DISPLAY=:0


alias qcow='qemu-img convert -f vmdk -O qcow2'
alias dfs='df -h /mnt/c'
alias disk='du -sh /mnt/c /mnt/wslg'
alias compare='ff https://www.textcompare.org/python/'

alias pyc=' bash /opt/pycharm-community-2021.2.3/bin/pycharm.sh'
alias biggest=' echo "du -h --max-depth=1 -a | sort -rh" '
alias wslg='cd /mnt/wslg && biggest'



alias psw='powershell.exe'
alias ex='explorer.exe .'
alias venv='python3 -m venv venv && source venv/bin/activate'
alias mp3='docker run --rm -v $HOME/Downloads:/root/Downloads dizcza/youtube-mp3 $1'
alias mp4='docker run --rm -i -e PGID=$(id -g) -e PUID=$(id -u) -v "$(pwd)":/workdir:rw mikenye/youtube-dl'
alias txt='tesseract'
alias drmariadb='docker run -d --name mariadb -e MYSQL_ROOT_PASSWORD=123456 -p 3307:3307 mariadb:latest && sleep 30 && docker exec -it mariadb mariadb -u root -p'
alias wcompile="cat '/mnt/c/study/programming/python/basics/compile in windows powershell'"
alias wl="py /mnt/c/study/Credentials/orderbylength.py"
alias pubip="echo 'http://87.70.162.212'"
alias rip="ff 'http://192.168.1.1'"
alias plex="ff 'http://87.70.162.212:32400'"
alias getplex="updates && echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list && curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add - && updates && cc && sudo apt install plexmediaserver -y && sudo systemctl enable plexmediaserver && sudo systemctl start plexmediaserver && ff http://87.70.162.212:32400/web/"
alias getff="apt install firefox-esr -y"
alias defender='cmd.exe /c C:/backup/windowsapps/install/afterformat/windows-defender-remover-main/windows-defender-remover-main/Script_Run.bat'
alias act="cd /mnt/c/backup/windowsapps/install/Microsoft-Activation-Scripts-master/mas/All-In-One-Version && cmd MAS_AIO.cmd"
alias python='python3'
alias py='python3'
alias myg="py /mnt/c/study/programming/python/apps/dockermenu/4.py"
alias editg="gedit /mnt/c/study/programming/python/apps/dockermenu/4.py"
alias aliases="gedit /mnt/c/backup/linux/wsl/alias.txt"
alias cpalias="cp /mnt/c/backup/linux/wsl/alias.txt /root/.bashrc && cp /mnt/c/backup/linux/wsl/alias.txt ~/.bashrc"
alias cmd='cmd.exe /c'
complete -C '/mnt/c/Users/micha/mc' mc
alias savegames="cd /mnt/c/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c 'apk add rsync && rsync -aP /home/* /c/backup/gamesaves && exit' && built michadockermisha/backup:gamesaves . && docker push michadockermisha/backup:gamesaves && rm -rf ./*"
alias sshct="ssh root@192.168.1.100"
alias pihole="gc http://192.168.1.100/admin/"
alias savedg="cd /mnt/c/backup/gamesaves && drun gamesdata michadockermisha/backup:gamesaves sh -c 'apk add rsync && rsync -aP /home/* /c/backup/gamesaves && exit'"
alias sjavascript="cd /mnt/c/study/programming/frontend/javascript"
alias sfront="cd /mnt/c/study/programming/frontend"
alias scomptia="cd /mnt/c/study/exams/compTIA"
alias sizes="dfs && size"
alias allips="nmap -sn 192.168.1.1/24"
alias kstart="minikube start --driver=docker --force"
alias sbash="cd /mnt/c/study/linux/bash"
alias sshwindows="ssh Administrator@192.168.1.230"
alias fixwin="echo 'choco upgrade all -y --force; Repair-WindowsImage -Online -ScanHealth; Repair-WindowsImage -Online -RestoreHealth; sfc /scannow ; DISM.exe /Online /Cleanup-Image /CheckHealth ; DISM.exe /Online /Cleanup-Image /RestoreHealth ; dism /online /cleanup-image /startcomponentcleanup; chkdsk /f /r; net start wuauserv; ./updates.ps1 '"
alias fubuntu="echo 'wsl --unregister ubuntu; wsl --import ubuntu C:\wsl2\ubuntu C:\backup\linux\wsl\ubuntu.tar'"
alias backupubu="echo 'wsl --export ubuntu C:\backup\linux\ubuntu.tar'"
alias sserver="cd /mnt/c/study/windows/server"
alias gcp="gc https://console.cloud.google.com/"
alias sansible="cd /mnt/c/study/automation/ansible"
alias sautomation="cd /mnt/c/study/automation"
alias ssecurity="cd /mnt/c/study/security"
alias shacking="cd /mnt/c/study/security/hacking"
alias libre="libreoffice --writer"
alias swebhosting="cd /mnt/c/study/webhosting"
alias fall="echo 'wsl --unregister kali-linux; wsl --import kali-linux C:\wsl2 C:\backup\linux\wsl\kalifull.tar; wsl --unregister ubuntu; wsl --import ubuntu C:\wsl2\ubuntu\ C:\backup\linux\wsl\ubuntu.tar'"



alias dcode='docker run -v /mnt/c/:/c/ -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -it --rm --name my_container michadockermisha/backup:python bash -c "echo 'y' | code --no-sandbox --user-data-dir=~/vscode-data && bash"'


alias fixer="py /mnt/c/study/programming/python/apps/filesfixer/gptpastefix.py"

alias drmariadb='docker run -v /mnt/c/:/c/ -it -d --name mariadb -e MYSQL_ROOT_PASSWORD=123456 -p 3307:3307 mariadb:latest && sleep 30 && docker exec -it mariadb mariadb -u root -p'


alias dei="docker exec -it"


alias playlist="py /mnt/c/users/micha/videos/a.py"


alias size='du -sh /mnt/c/wsl2/ext4.vhdx && du -sh /mnt/c/wsl2/ubuntu/ext4.vhdx'


alias build="cp /mnt/c/study/docker/dockerfiles/buildimage ./Dockerfile && nano Dockerfile"


alias build2='cp /mnt/c/study/docker/dockerfiles/buildthispath ./Dockerfile && nano Dockerfile'

alias compile="echo ' & \"C:\Users\micha\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.12_qbz5n2kfra8p0\LocalCache\local-packages\Python312\Scripts\pyinstaller\" --onefile --icon=a.ico --windowed --name=WinOptimize a.py ' "

alias convertico="sudo apt install imagemagick && convert -resize x16 -gravity center -crop 16x16+0+0 a.png -flatten -colors 256 -background transparent a.ico"


alias ghs="python /mnt/c/study/programming/python/apps/scrapers/githubScraper/a.py"


alias gpts=" nano /mnt/c/study/automation/AI/gpts_plugins_that_are_good"


alias trans="python /mnt/c/study/programming//python/apps/transcripts/youtubeVideoToText/b.py"


alias getjava="sudo apt install openjdk-11-jdk -y"


alias sdatascience="cd /mnt/c/study/datascience"


alias salgo=" cd /mnt/c/study/datascience/algorithms"

alias sdatasets="cd /mnt/c/study/datascience/datasets"


alias sleetcode="cd /mnt/c/study/exams/leetcode"

alias jup="jupyter notebook --allow-root"

alias editfixer="nano /mnt/c/study/programming/python/apps/filesfixer/gptpastefix.py"



alias getaudio="cd /mnt/c/study/programming//python/apps/transcripts/epub2tts && sudo apt install espeak-ng ffmpeg -y && pip install . && edge-tts --list-voices | grep -i hebrew"



alias audioh="epub2tts a.txt --engine edge --language he --speaker he-IL-AvriNeural --audioformat wav"



alias audio="epub2tts a.txt --audioformat wav"

alias gptbot="python /mnt/c/study/programming/python/apps/chatGPTbot/automateAnswerAndSend/a.py"



alias sAI="cd /mnt/c/study/automation/AI"

alias getkube='sudo mkdir -p /etc/kubernetes && sudo snap install kubectl --classic && sudo snap install kubeadm --classic && sudo snap install kubelet --classic && sudo snap install microk8s --classic && sudo snap install helm --classic && curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube && sudo touch /etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf && minikube start --driver=docker --force && kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml && kubectl create sa kube-ds-viewer -n kube-system && kubectl create sa kube-ds-editor -n kube-system && kubectl create sa kube-ds-admin -n kube-system && kubectl create clusterrolebinding kube-ds-viewer-role-binding --clusterrole=view --serviceaccount=kube-system:kube-ds-viewer && kubectl create clusterrolebinding kube-ds-editor-role-binding --clusterrole=edit --serviceaccount=kube-system:kube-ds-editor && kubectl create clusterrolebinding kube-ds-admin-role-binding --clusterrole=admin --serviceaccount=kube-system:kube-ds-admin && kubectl create secret generic kube-ds-viewer-token --from-literal=token=$(kubectl get secret $(kubectl get sa kube-ds-viewer -n kube-system -o jsonpath="{.secrets[0].name}") -n kube-system -o jsonpath="{.data.token}" | base64 -d) -n kube-system && kubectl create secret generic kube-ds-editor-token --from-literal=token=$(kubectl get secret $(kubectl get sa kube-ds-editor -n kube-system -o jsonpath="{.secrets[0}.name}") -n kube-system -o jsonpath="{.data.token}" | base64 -d) -n kube-system && kubectl create secret generic kube-ds-admin-token --from-literal=token=$(kubectl get secret $(kubectl get sa kube-ds-admin -n kube-system -o jsonpath="{.secrets[0].name}") -n kube-system -o jsonpath="{.data.token}" | base64 -d) -n kube-system && kubectl get secret kube-ds-viewer-token -n kube-system -o jsonpath="{.data.token}" | base64 -d && kubectl get secret kube-ds-editor-token -n kube-system -o jsonpath="{.data.token}" | base64 -d && kubectl get secret kube-ds-admin-token -n kube-system -o jsonpath="{.data.token}" | base64 -d || echo -e "\a"'


alias getmariadb="sudo apt install -y mariadb-server && sudo systemctl start mariadb && sudo systemctl enable mariadb && sudo mysql"



alias menu="python /mnt/c/study/programming/python/apps/ubuntuMenu/a.py"


alias upgradeit="apt --only-upgrade install"


alias word='find . -name '



alias getollama="update && cd && curl -fsSL https://ollama.com/install.sh | sh && sleep 5 && ollama run llama3 && docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main && gc http://localhost:8080"


alias restorestudy='c && cd study && drun study michadockermisha/backup:study sh -c "apk add rsync && rsync -aP /home/* /c/study/&& exit"'



alias sources="cd /etc/apt/sources.list.d"



alias ftp="gc http://192.168.1.195:5000/"



alias qna="cd /mnt/c/study/exams/QNA"



alias epub2text="apt install calibre -y && ebook-convert a.epub a.txt"



alias hebrew="py /mnt/c/study/programming/python/apps/translate2hebrew/a.py"



alias getnpm="apt install npm nodejs -y"

alias sporg="cd /mnt/c/study/programming"



alias hebrew="py /mnt/c/study/programming/python/apps/translate2hebrew/wsl/a.py"



alias getgres="sudo apt install -y postgresql postgresql-contrib && sudo systemctl start postgresql && sudo -i -u postgres psql"



alias setups="cd /mnt/c/study/setups"



alias find="grep -iRl"



alias awsconf="apt install awscli -y && cat /mnt/c/study/credentials/AWS/AccessKey.txt && aws configure"



alias saws="cd /mnt/c/study/cloud/aws/awscli"



alias pdata="cd /mnt/c/study/programming/python/datascience"


alias getelk=alias getelk='apt-get update && sudo apt-get install openjdk-17-jre-headless -y && sudo apt-get install nginx -y && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - && sudo apt-get install apt-transport-https -y && echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee –a /etc/apt/sources.list.d/elastic-7.x.list && sudo apt-get update && sudo apt-get install elasticsearch && rm -rf /etc/elasticsearch/elasticsearch.yml && cp /mnt/c/study/monitoring/ELK/installationfiles/"etc elasticsearch elasticsearch.yml" /etc/elasticsearch/elasticsearch.yml && rm -rf /etc/elasticsearch/jvm.options && cp /mnt/c/study/monitoring/ELK/installationfiles/"etc elasticsearch jvm.options" /etc/elasticsearch/jvm.options && sudo systemctl start elasticsearch.service && sudo systemctl enable elasticsearch.service && clear && curl -X GET "localhost:9200" && sudo apt-get install kibana -y && rm -rf /etc/kibana/kibana.yml && cp /mnt/c/study/monitoring/ELK/installationfiles/"etc kibana kibana.yml" /etc/kibana/kibana.yml && sudo systemctl start kibana && sudo systemctl enable kibana && sudo ufw allow 5601/tcp && sudo apt-get install logstash -y && sudo systemctl start logstash && sudo systemctl enable logstash && sudo apt-get install filebeat -y && rm -rf /etc/filebeat/filebeat.yml && cp /mnt/c/study/monitoring/ELK/installationfiles/"etc filebeat filebeat.yml" /etc/filebeat/filebeat.yml && sudo filebeat modules enable system && sudo filebeat setup --index-management -E output.logstash.enabled=false -E "output.elasticsearch.hosts=[\"localhost:9200\"]" && sudo systemctl start filebeat && sudo systemctl enable filebeat && clear && curl -XGET http://localhost:9200/_cat/indices?v'


export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
