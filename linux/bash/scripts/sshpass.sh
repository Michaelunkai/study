# Define the password and remote host variables
PASSWORD='123456'
REMOTE_HOST='192.168.1.193'

# Copy the .bashrc file to the remote host
sshpass -p "$PASSWORD" scp /root/.bashrc ubuntu@$REMOTE_HOST:/home/ubuntu/.bashrc_temp

# Move the .bashrc_temp to the correct location and source it
sshpass -p "$PASSWORD" ssh ubuntu@$REMOTE_HOST "echo $PASSWORD | sudo -S mv /home/ubuntu/.bashrc_temp /root/.bashrc && sudo cp /root/.bashrc /home/ubuntu/.bashrc && source ~/.bashrc"
