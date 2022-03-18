#!/bin/bash

#### This script is intended to setup all AI dependencies i.e CUDA , Nvidia Drivers, TensorRT cuDNN & Deepstream on Ubuntu 20.04.4 LTS ####

####### Versions #######

# CUDA 11.4 (Update 4) / CUDA 10.1
# Nvidia Driver 470.82.01 / 418
# TensorRT 8.2.3-1
# cuDNN 8.2.4
# Deepstream 6.0.0.1
# GStreamer 1.0
# Librdkafka commit ID 7101c2310341ab3f4675fc565f64f0967e135a6a
# Kafka 3.0.0_2.13
# Redis 6.0.0
# NodeJs 14/16
# Docker 20 Docker-Compose 3
# Zabbix Agent 5/6
# Elastic Metricbeat 7.17
# Elastic APM 7.17

#### Please set the values to 1 against the switches you wanted to do ####

doUpgrade=0
doSystemDependencies=0
doDocker=0
doDockerCompose=0
doRedis=0
doKafka=0
doKafkaTopics=0
## If you selected to $dokafkaTopics please must fill in the veriable for topic names and number of partitions below ##
KAFKA_TOPIC1='st-interloop-config-prod'
partitions_COUNT_TOPIC1='1'
KAFKA_TOPIC2='st-interloop-central-prod'
partitions_COUNT_TOPIC2='3'
KAFKA_TOPIC3='st-interloop-logs-prod'
partitions_COUNT_TOPIC3='1'
### end of do kafkaTopics ###

doPostgreSQL14=0
doCuda10=0 #Ubuntu 18.04.6
doCuda11=0 #Ubuntu 20.04.4
doTensorRT8=0
docuDNN8=0
doLibrdkafka=0 # cuDNN8.2.3
dogstreamer1=0
doDeepstream6=0
doNodeJs14=0
doNodeJs16=0
doSupervisor=0 
doZabbix5Agent2=0 #TODO
doZabbix6Agent2=0 
doMetricbeat7=0 #In-Progres
doAPM7=0 #TODO
doReboot=0

### Please do Place all .DEB file for CUDA, TensorRT, cuDNN Runtime, cuDNN Development at /opt/ai-dep-installation ###
### Note: Please create the DIR if its a new machine

sudo chown -R $(whoami). /opt/ai-dep-installation
cd /opt/ai-dep-installation

if [ $doUpgrade == 1 ]; then
  echo "Initializing."
  sudo apt-get -y update
  sudo apt-get -y upgrade
  sudo apt-get install -y apt-utils
  sudo apt-get install -y locate
  sudo apt-get -y upgrade
  sudo ldconfig
  sudo updatedb
fi

if [ $doSystemDependencies == 1 ]; then

  echo "Installing system dependencies"
  sudo apt-get install -y wget
  sudo apt-get install -y tar
  sudo apt-get install -y zip
  sudo apt-get install -y unzip
  sudo apt-get install -y ufw
  sudo apt-get install -y net-tools
  sudo apt-get install -y git
  sudo apt-get install python3-venv
  sudo apt-get install -y pkg-config
  sudo apt-get install -y pkgconf
  sudo apt-get -y install curl
  sudo apt-get -y install libcurl3-dev
  sudo apt-get install -y cmake
  sudo apt-get install -y cmake-gui

  echo "Installing editors vim and nano"
  sudo apt-get install -y vim nano
fi

if [ $doDocker == 1 ]; then
 echo "Removeing Docker if any previous installation is there in system"
 sudo apt-get -y purge docker-ce docker-ce-cli containerd.io
 sudo rm -rf /var/lib/docker
 sudo rm -rf /var/lib/containerd
 
 echo "installing Docker"
 curl -fsSL https://get.docker.com -o get-docker.sh
 sudo sh get-docker.sh
fi

if [ $doDockerCompose == 1 ]; then
  echo "Removeing Docker-Compose if any previous installation is there in syste"
  sudo rm /usr/local/bin/docker-compose
  
  echo "Installating the latest version of Docker Compose"
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  docker-compose --version
fi

if [ $doKafka == 1 ]; then
  echo "Adding user"
  sudo useradd kafka -m
  #sudo adduser kafka -m
  sudo adduser kafka sudo
  echo "kafka ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/kafka
  #sudo su - kafka
  #bash
  #[ ! -d "${DIR}" ] && sudo mkdir -p "${DIR}"

  echo "Makinng DIR"
  sudo mkdir /home/kafka
  sudo chown -R $(whoami). /home/kafka
  cd /home/kafka
  wget https://downloads.apache.org/kafka/3.0.0/kafka_2.13-3.0.0.tgz
  tar -xvzf kafka_2.13-3.0.0.tgz --strip 1
  echo "delete.topic.enable = true" >> ~/config/server.properties
  #sudo mkdir /var/log/

  echo "Creating Daemon For Zookeeper"
  echo "[Unit]
  Requires=network.target remote-fs.target
  After=network.target remote-fs.target

  [Service]
  Type=simple
  User=kafka
  ExecStart=/home/kafka/bin/zookeeper-server-start.sh /home/kafka/config/zookeeper.properties
  ExecStop=/home/kafka/bin/zookeeper-server-stop.sh
  Restart=on-abnormal

  [Install]
  WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/zookeeper.service

  echo "Creating Daemon For Kafka"

  echo "[Unit]
  Requires=zookeeper.service
  After=zookeeper.service
 
  [Service]
  Type=simple
  User=kafka
  ExecStart=/bin/sh -c '/home/kafka/bin/kafka-server-start.sh /home/kafka/config/server.properties > /home/kafka/kafka.log 2>&1'
  ExecStop=/home/kafka/bin/kafka-server-stop.sh
  Restart=on-abnormal

  [Install]
  WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/kafka.service

  echo "Hnading over to kafka user"
  sudo chown -R kafka. /home/kafka

  echo "Starting Up Kafka and Zookeeper"
  sudo systemctl start kafka &&
  sudo systemctl status kafka

  sudo systemctl enable zookeeper
  sudo systemctl enable kafka


fi

if [ $doKafkaTopics == 1 ]; then

 echo "Craeting Topics"
 sudo runuser -l kafka -c "/home/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic $KAFKA_TOPIC1"
 sudo runuser -l kafka -c "/home/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 3 --topic $KAFKA_TOPIC2"
 sudo runuser -l kafka -c "/home/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic $KAFKA_TOPIC3"

fi

if [ $doPostgreSQL == 1 ]; then
  sudo apt-get  -y install gnupg2
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get -y update
  sudo apt-get -y upgrade 
  sudo apt -y install postgresql-14
  echo "Show PostgreSQL 14"

  sudo -u postgres psql -c "SELECT version();"
fi

if [ $doCuda11 == 1 ]; then

  echo "creating DIR for cuda installtion"
  #sudo mkdir /opt/cuda-instaltion
  cd /opt/ai-dep-installation
  #sudo chown -R $(whoami). /opt/cuda-instaltion/
  echo "Purging Previous Installation"
  sudo apt purge cuda-*
  sudo apt-get purge nvidia*
  sudo apt-get purge libnvidia-*

  echo "Downloading Repo" && \
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin # Ubuntu 20.04

  echo  "Extrating Repo" && \
  sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600 #Ubuntu 20.04

  echo "Downloading Cuda 11.4.4-470"
  #wget https://developer.download.nvidia.com/compute/cuda/11.4.4/local_installers/cuda-repo-ubuntu2004-11-4-local_11.4.4-470.82.01-1_amd64.deb #Ubuntu 20.04

  echo "Executing DPKG"
  sudo dpkg -i cuda-repo-ubuntu2004-11-4-local_11.4.4-470.82.01-1_amd64.deb # Ubuntu 20.04
  sudo apt-key add /var/cuda-repo-ubuntu2004-11-4-local/7fa2af80.pub # Ubuntu 20.04

  echo "Installing cuda 11.4"
  sudo apt-get update
  sudo apt-get -y install cuda
  ### If you want to remove Nvidia 470 Drivers and want to install custom versions of Drivers please un-comment these lines and replace the XYZ with your desired values ### 
  #echo "Removing Nvidia-470"
  #sudo apt-get purge nvidia*
  #sudo apt-get purge libnvidia-*

 #echo "installing Nvidia driver XYZ" && echo " " && \

 #sudo apt-get install nvidia-driver-XYZ-server -y


 echo "Seting UP Cuda Path in ~/.bashrc"
 
 sudo ldconfig
 CUDA_HOME=/usr/local/cuda
 echo "CUDA_HOME=$CUDA_HOME" >>~/.bashrc
 echo "LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" >>~/.bashrc
 echo "PATH=/usr/local/cuda-11.4/bin${PATH:+:${PATH}}" >>~/.bashrc
 export ARCH_COMPUTE=$COMPUTE_ARCHITECTURE
 echo "ARCH_COMPUTE=$COMPUTE_ARCHITECTURE" >>"/etc/environment"
 source ~/.bashrc

fi

if [ $doCuda10 == 1 ]; then

 echo "creating DIR for cuda installtion"
 #sudo mkdir /opt/cuda-instaltion
 cd /opt/ai-dep-installation
 #sudo chown -R $(whoami). /opt/cuda-instaltion/
 echo "Purging Previous Installation"
 sudo apt purge cuda-*
 sudo apt-get purge nvidia*
 sudo apt-get purge libnvidia-*

 echo "Downloading Repo" && \
 wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin # Ubuntu 18.04

 echo  "Extrating Repo" && \
 sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600

 echo "Downloading Cuda 10.1.243"
 wget https://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda-repo-ubuntu1804-10-1-local-10.1.243-418.87.00_1.0-1_amd64.deb #Ubuntu 18.04

 echo "Executing DPKG"
 sudo dpkg -i cuda-repo-ubuntu1804-10-1-local-10.1.243-418.87.00_1.0-1_amd64.deb
 sudo apt-key add /var/cuda-repo-10-1-local-10.1.243-418.87.00/7fa2af80.pub

 echo "Installing cuda 11.4"
 sudo apt-get update
 sudo apt-get -y install cuda

 #echo "Removing Nvidia-418"
 #sudo apt-get purge nvidia*
 #sudo apt-get purge libnvidia-*

 #echo "installing Nvidia driver 450" && echo " " && \

 #sudo apt-get install nvidia-driver-450-server -y


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

fi

if [ $doTensorRT8 == 1 ]; then

 #This script is intended to install TensoRT 8.2.3 on Ubuntu 20.04.4
 #DIR='/opt/ai-dep-installation'
 echo "adding TensortRT repo /etc/apt/sources.list.d/cuda-repo.list"
 #[ ! -d "${DIR}" ] && sudo mkdir -p "${DIR}"

 echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64 /" | sudo tee /etc/apt/sources.list.d/cuda-repo.list
 wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
 sudo apt-key add 7fa2af80.pub
 sudo apt-get update

 echo "Download TensorRT 8.2.3 for Ubuntu 20.04 LTS"
 #sudo chown -R $(whoami). ${DIR}
 #cd  ${DIR}
 #wget https://developer.download.nvidia.com/compute/machine-learning/tensorrt/secure/8.2.3.0/local_repos/nv-tensorrt-repo-ubuntu2004-cuda11.4-trt8.2.3.0-ga-20220113_1-1_amd64.deb

 echo "Unpacking & installing TensorRT 8.2.3"
 sudo dpkg -i nv-tensorrt-repo-ubuntu2004-cuda11.4-trt8.2.3.0-ga-20220113_1-1_amd64.deb
 sudo apt-key add /var/nv-tensorrt-repo-ubuntu2004-cuda11.4-trt8.2.3.0-ga-20220113/7fa2af80.pub
 echo "Installing Libs"
 sudo apt-get update -y &&

 sudo apt-get install libnvinfer8=8.2.3-1+cuda11.4 libnvinfer-plugin8=8.2.3-1+cuda11.4 libnvparsers8=8.2.3-1+cuda11.4 &&
 sudo apt-get install libnvonnxparsers8=8.2.3-1+cuda11.4 libnvinfer-bin=8.2.3-1+cuda11.4 libnvinfer-dev=8.2.3-1+cuda11.4 &&
 sudo apt-get install libnvinfer-plugin-dev=8.2.3-1+cuda11.4 libnvparsers-dev=8.2.3-1+cuda11.4 libnvonnxparsers-dev=8.2.3-1+cuda11.4 &&
 sudo apt-get install libnvinfer-samples=8.2.3-1+cuda11.4 libnvinfer-doc=8.2.3-1+cuda11.4
fi

if [ $docuDNN8 == 1 ]; then
 cd /opt/ai-dep-installation
 sudo apt-get install zlib1g
 echo "Adding cuDNN 8.2.4-cuda 11.4 Runtime library in apt-get"
 sudo dpkg -i libcudnn8_8.2.4.15-1+cuda11.4_amd64.deb

 echo "Adding cuDNN 8.2.4-cuda 11.4 Development library in apt-get"
 sudo dpkg -i libcudnn8-dev_8.2.4.15-1+cuda11.4_amd64.deb

 echo "updating apt-get repository"
 sudo apt-get update

 echo "installing cuDNN 8.2.4-cuda 11.4"
 sudo apt-get install libcudnn8=8.2.4.15-1+cuda11.4
 sudo apt-get install libcudnn8-dev=8.2.4.15-1+cuda11.4
 sudo apt-get install libcudnn8-samples=8.2.4.15-1+cuda11.4

 echo "creating Short Link for python"
 sudo ln -s /usr/bin/python3.8 /usr/bin/python
 echo "installing Deepstream dependencies"

 sudo apt install libssl1.1 libssl-dev libsasl2-dev liblz4-dev zlib1g-dev libgstreamer1.0-0 gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav libgstrtspserver-1.0-0 libjansson4

fi

if [ $doLibrdkafka == 1 ]; then
 echo "cloning librdkafka"
 git clone https://github.com/edenhill/librdkafka.git
 cd librdkafka
 git reset --hard 7101c2310341ab3f4675fc565f64f0967e135a6a

 echo "compile librdkafka"
 ./configure
 make
 sudo make install

fi

if [ $doDeepstream6 == 1 ]; then
 echo "Copy the generated libraries to the deepstream directory"
 sudo mkdir -p /opt/nvidia/deepstream/deepstream-6.0/lib
 sudo cp /usr/local/lib/librdkafka* /opt/nvidia/deepstream/deepstream-6.0/lib
 sudo apt --fix-broken install
fi

if [ $doNodeJs14 == 1 ]; then
  echo "Removing Old NodeJs installation if needed"
  sudo apt-get purge -y nodejs && sudo apt-get remove -y nodejs
  sudo rm -rf ~/.npm
  sudo rm -rf /usr/bin/npm
  sudo rm -rf /usr/bin/node
  sudo rm -rf /usr/lib/node_modules
  echo "Installing NodeJS 14 with NPM 8.X.X"
  curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh
  sudo apt install nodejs
  node -v
  sudo npm install -g npm
fi

if [ $doNodeJs16 == 1 ]; then
  echo "Removing Old NodeJs installation if needed"
  sudo apt-get purge -y nodejs && sudo apt-get remove -y nodejs
  sudo rm -rf ~/.npm
  sudo rm -rf /usr/bin/npm
  sudo rm -rf /usr/bin/node
  sudo rm -rf /usr/lib/node_modules
  echo "Installing NodeJS 14 with NPM 8.X.X"
  curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh
  sudo apt install nodejs
  node -v
  sudo npm install -g npm
fi

if [ $doRedis == 1 ]; then
 sudo apt-get install -y redis
 sudo sed -i "s/supervised no/supervised systemd/g" 
 echo "requirepass $tech1" >>"/etc/redis/redis.conf"
fi

if [ $doZabbix6Agent2 == 1 ];then
  ### Only for Ubuntu 20.04 LTS ###
  wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-1+ubuntu20.04_all.deb
  sudo  dpkg -i zabbix-release_6.0-1+ubuntu20.04_all.deb
  sudo apt-get update 
  #sudo apt install zabbix-agent
  sudo apt-get -y install zabbix-agent2
  sudo sed -i "s/Server=127.0.0.1/Server=34.199.79.106/g"
  sudo systemctl restart zabbix-agent2.service
  sudo systemctl status zabbix-agent2.service
  sudo systemctl enable zabbix-agnet2.service 
fi

if [ $doZabbix5Agent2 == 1 ];then
  ### Only for Ubuntu 20.04 LTS ###
  wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+focal_all.deb
  sudo dpkg -i zabbix-release_5.0-1+focal_all.deb
  sudo apt-get update 
  #sudo apt install zabbix-agent
  sudo apt-get -y install zabbix-agent2
  sudo sed -i "s/Server=127.0.0.1/Server=34.199.79.106/g"
  sudo systemctl restart zabbix-agent2.service
  sudo systemctl status zabbix-agent2.service
  sudo systemctl enable zabbix-agnet2.service 
fi

if [ $doMetricbeat7 == 1 ];then
  #TODO: Elasticsearch Client certs/creds & Kibana creds
  sudo apt-get purge -y metricbeat && sudo apt-get remove -y metricbeat
  curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-7.17.1-amd64.deb
  sudo dpkg -i metricbeat-7.17.1-amd64.deb

  sudo metricbeat modules enable system
  sudo metricbeat setup -e
  sudo systemctl start metricbeat.service
  sudo systemctl status metricbeat.service
  sudo systemctl enable metricbeat.service
fi

if [ $doReboot == 1 ]; then
 sudo apt-get -y update && sudo apt-get -y upgrade && sudo reboot
fi