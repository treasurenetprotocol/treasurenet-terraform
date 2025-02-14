# treasurenet-terraform

## 1. 初始化

```bash
terraform init
```
用于初始化 Terraform 环境。

### 2. 配置和部署
```bash
terraform apply
```
用于购买 RDS、配置 Secrets Manager、购买 EC2、配置 Cloudflare 的 DNS 信息。
configuration.sh 用于初始化 EC2 服务器，包括：
安装 Docker、Docker-Compose、Go
更新系统
安装 AWS CLI
配置环境变量
创建目录

### 3. 克隆并切换到指定分支
```bash
git clone https://github.com/treasurenetprotocol/treasurenet.git
git checkout feature/3.1.0
```
若无修改内容，进入 Actions 查找最新的 commit 并进行 R-run all jobs。

### 4. 提交代码
```bash
git push
```
等待 EC2 创建完成并初始化完成后，触发 workflow。
workflow 用于：
创建 treasurenetd 二进制文件
初始化 node 节点和 seednode 节点
合并创世区块信息
将必要信息写入 .env 文件
创建和配置 Nginx 目录信息
获取 EC2 服务器的 IP 信息和标签信息
触发 Ansible

### 5. 使用 Ansible 配置 EC2
Ansible 用于：
将文件复制到所有指定的 EC2 服务器
根据服务器修改 .env 文件并替换相关信息
最后启动 Docker Compose

### 6. 克隆并切换到区块链浏览器分支

```bash
git clone https://github.com/treasurenetprotocol/blockscout.git
git checkout testnet-feature-1.0.0
```
若无修改内容，进入 Actions 查找最新的 commit 并进行 R-run all jobs。

### 7. 提交代码
```bash
git push
```
等待 treasurenet 的 workflow 完成后，触发 workflow 部署区块链浏览器。

### 8. 克隆并切换到监控中心分支
```bash
git clone https://github.com/treasurenetprotocol/monitoring-hub.git

git checkout DEV-79
```
若无修改内容，进入 Actions 查找最新的 commit 并进行 R-run all jobs。

### 9. 提交代码
```bash
git push
```
等待 blockscout 的 workflow 完成后，触发 workflow 启动 Grafana。

### 10. 销毁资源
```bash
terraform destroy
```
用于销毁部署的资源。