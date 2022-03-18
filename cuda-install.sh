#!/bin/bash

#This script is intended to install Cuda 10.1.243 &  install Nvidia Drivers 450
USERNAME='$(whoami)'
echo "creating DIR for cuda installtion"
sudo mkdir /opt/cuda-instaltion
cd /opt/cuda-instaltion
sudo chown -R ${USERNAME}. /opt/cuda-instaltion/
echo "Purging Previous Installation"
sudo apt purge cuda-*
sudo apt-get purge nvidia*
sudo apt-get purge libnvidia-*

echo "Downloading Repo" && \
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
echo  "Extrating Repo" && \
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600

echo "Downloading Cuda 10.1.243"
wget https://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1804-10-1-local-10.1.243-418.87.00_1.0-1_amd64.deb
echo "Executing DPKG"
sudo dpkg -i cuda-repo-ubuntu1804-10-1-local-10.1.243-418.87.00_1.0-1_amd64.deb

sudo apt-key add /var/cuda-repo-10-1-local-10.1.243-418.87.00/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda

echo "Removing Nvidia-418"
sudo apt-get purge nvidia*
sudo apt-get purge libnvidia-*

echo "installing Nvidia driver 450" && echo " " && \

sudo apt-get install nvidia-driver-450-server -y


echo "Set Cuda Path in .bashrc"
# export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
sudo ldconfig
CUDA_HOME=/usr/local/cuda
echo "CUDA_HOME=$CUDA_HOME" >>~/.bashrc
echo "LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" >>~/.bashrc
echo "PATH=/usr/local/cuda-10.1/bin${PATH:+:${PATH}}" >>~/.bashrc
export ARCH_COMPUTE=$COMPUTE_ARCHITECTURE
echo "ARCH_COMPUTE=$COMPUTE_ARCHITECTURE" >>"/etc/environment"
source ~/.bashrc

echo "System reboot trigred" && \
echo "Good Bye"
sudo reboot
