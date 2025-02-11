#!/bin/bash
# 适用于 Ubuntu 的设置脚本
export INSTANCE_INDEX=${instance_index}
export ENV_VAR=${env_var}
# 设置 Go 环境变量
export GOPATH=/root/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export HOME=/root
echo "Starting the setup..."

# 更新系统
echo "Updating the system..."
sudo apt update -y
sudo apt upgrade -y

# 安装必要的软件包
echo "Installing necessary packages..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release wget unzip

# 添加 Docker 的 GPG 密钥
echo "Adding Docker's GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 设置 Docker 的 APT 仓库
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新 APT 包索引
echo "Updating APT package index..."
sudo apt update -y

# 安装 Docker Engine
echo "Installing Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 启动并启用 Docker 服务
echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Docker setup completed."

# 创建 /data 目录并设置权限
echo "Creating /data directory..."
sudo mkdir -p /data
sudo chown -R "$USER:$USER" /data

cd /data


# 安装开发工具
echo "Installing development tools..."
sudo apt install -y make gcc

echo "Development tools installation completed."

# 安装 Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.20.2"  # 请根据需要更改为最新版本
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建符号链接（可选）
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
echo "Verifying Docker Compose installation..."
docker-compose --version

echo "Docker Compose $DOCKER_COMPOSE_VERSION installation completed."

# 安装 AWS CLI
echo "Installing AWS CLI..."
# 下载 AWS CLI v2 安装包
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 解压安装包
unzip awscliv2.zip

# 运行安装程序
sudo ./aws/install

# 验证安装
echo "Verifying AWS CLI installation..."
aws --version

echo "AWS CLI installation completed."

# 清理安装文件
echo "Cleaning up installation files..."
rm awscliv2.zip
rm -rf aws

# 确保当前用户可以使用 Docker 命令
echo "Adding user ubuntu to docker group..."
sudo usermod -aG docker "ubuntu"

echo "Setup completed successfully."

# 提示用户重新登录以应用 Docker 组更改
echo "Please log out and log back in to apply the Docker group changes."
# 下载并安装 Go 1.18
echo "Downloading and installing Go 1.18..."
GO_VERSION="1.18"
GO_TAR_FILE="go$GO_VERSION.linux-amd64.tar.gz"
GO_INSTALL_DIR="/usr/local"
# 下载 Go 1.18
echo "Downloading Go $GO_VERSION..."
wget https://go.dev/dl/"$GO_TAR_FILE"

# 解压并安装 Go
echo "Extracting Go..."
sudo tar -C "$GO_INSTALL_DIR" -xzf "$GO_TAR_FILE"

# 设置 Go 环境变量
echo "Setting up Go environment..."

echo "export GOPATH=/root/go" >> /etc/profile
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=\$PATH:/usr/local/go:/root/go/bin:/usr/local/go/bin" >> /etc/profile
echo "export GOCACHE=$HOME/.cache/go-build" >> /etc/profile
echo "export XDG_CACHE_HOME=$HOME/.cache" >> /etc/profile

source /etc/profile


# 验证安装
echo "Verifying Go installation..."
go version



# cd /data

# git clone --branch feature/3.0.1 https://github.com/treasurenetprotocol/treasurenet.git

# cd /data/treasurenet
# go env -w GO111MODULE=on
# go mod tidy
# make install

# ls $(go env GOPATH)/bin
# sudo cp $(go env GOPATH)/bin/treasurenetd /usr/bin
# #切换用户

# sudo chown -R ubuntu:ubuntu /data/
# sudo -E -u ubuntu bash -c 'echo "node=$INSTANCE_INDEX" > .env'
# sudo -u ubuntu chmod +x init_nodes.sh
# sudo -u ubuntu chmod +x init_node_template.sh
# sudo -u ubuntu chmod +x node_config.json
# sudo -u ubuntu bash init_nodes.sh





