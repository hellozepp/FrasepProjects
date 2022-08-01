sudo apt update && sudo apt upgrade -y

sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

sudo dockerd &
sudo docker run hello-world

sudo usermod -aG docker $USER

sudo vi /etc/sudoers
%docker ALL=(ALL)  NOPASSWD: /usr/bin/dockerd


3. Create the startup script in /usr/local/bin/docker-service.sh with the following contents:

#!/bin/bash

DOCKER_SOCK="/var/run/docker.sock"
export DOCKER_HOST="unix://$DOCKER_SOCK"
if [ ! -S "$DOCKER_SOCK"] ; then
    sh -c "nohup sudo -b dockerd < /dev/null > /var/log/dockerd.log 2>&1"
fi

~/.bashrc
/usr/local/bin/docker-service.sh
5. Initialize the log file with writable permissions:
sudo touch /var/log/dockerd.log
sudo chmod 666 /var/log/dockerd.log
6. Restart WSL by closing any active sessions, then open a new one.

