# Prerequisites
Windows 10 versions 2004 et ultérieures (build 19041 et versions ultérieures) ou Windows 11.
 
# To check win version :
(windows+r), and : winver
 
# Get list of available linux distro
wsl --list --online
 
# Install wsl subsystem
wsl --install -D Ubuntu

# Reboot du poste

# List 
wsl -l -v
 
# Install windows terminal (for multi tab terminals)

# Install Docker engine

sudo apt update && sudo apt upgrade -y

## 1. If installed, uninstall Docker Desktop in Windows. 
## 2. Remove old versions from Linux, if installed:
sudo apt-get remove docker docker-engine docker.io containerd runc
## 3. Install prerequisites:
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
 
## 4. Add the repository:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
## 5. Install Docker engine:
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
## 6. Test it out:
sudo dockerd &
sudo docker run hello-world
## 7. Startup Script
Since WSL doesn't use systemd, Docker won't automatically start when WSL comes up. I added a startup script which gets called in my .profile script to address this.
### 1. Add yourself to the docker group:
sudo usermod -aG docker $USER
### 2. Give the docker group passwordless sudo access to dockerd:
sudo visudo
 
Add the following line:
%docker ALL=(ALL)  NOPASSWD: /usr/bin/dockerd
### 3. Create the startup script in /usr/local/bin/docker-service.sh with the following contents:
/usr/local/bin/docker-service.sh
#!/bin/bash
 
DOCKER_SOCK="/var/run/docker.sock"
export DOCKER_HOST="unix://$DOCKER_SOCK"
if [ ! -S "$DOCKER_SOCK"] ; then
    sh -c "nohup sudo -b dockerd < /dev/null > /var/log/dockerd.log 2>&1"
fi
### 4. Add the script to the bottom of .bashrc (or whatever shell rc you use):
~/.bashrc
/usr/local/bin/docker-service.sh
### 5. Initialize the log file with writable permissions:
sudo touch /var/log/dockerd.log
sudo chmod 666 /var/log/dockerd.log
### 6. Restart WSL by closing any active sessions, then open a new one.
