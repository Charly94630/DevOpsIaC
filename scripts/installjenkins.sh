#!/bin/bash
sudo apt update -y
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo apt install fontconfig openjdk-17-jre -y
sudo systemctl enable jenkins
jenkinsPath="/var/lib/jenkins/secrets/initialAdminPassword"
if [-e $jenkinsPath ]; then
sudo cat $jenkinsPath
fi
