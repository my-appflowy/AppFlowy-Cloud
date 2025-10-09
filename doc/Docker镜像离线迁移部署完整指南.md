# Docker镜像离线迁移部署完整指南

## 部署概述

**部署目标**: 将本地Docker镜像集群完整迁移到远程服务器 8.152.101.166  
**部署方式**: 离线镜像导出→传输→导入→启动  
**部署日期**: 2025年10月9日  
**操作人员**: kun cao

---

## 一、部署架构说明

### 1.1 整体流程

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  本地环境   │ ───> │   镜像文件   │ ───> │ 远程服务器  │
│  (Mac OS)   │      │ (.tar格式)   │      │(8.152.101.166)│
└─────────────┘      └──────────────┘      └─────────────┘
     ↓                      ↓                      ↓
  导出镜像             SCP传输              导入并启动
```

### 1.2 涉及的Docker镜像

| 镜像名称 | 标签 | 本地大小 | 服务器大小 | 用途 |
|---------|------|---------|-----------|------|
| appflowyinc/appflowy_cloud | latest | 207MB | 140MB | 主服务 |
| appflowyinc/gotrue | dev-aliyun-sms | 75.6MB | 49.2MB | 认证服务 |
| appflowyinc/appflowy_ai | latest | 190MB | 129MB | AI服务 |
| pgvector/pgvector | pg16 | 625MB | 441MB | PostgreSQL数据库 |
| redis | latest | 200MB | 137MB | 缓存服务 |
| minio/minio | latest | 241MB | 175MB | 对象存储 |
| nginx | alpine | 79.3MB | 52.5MB | 反向代理 |
| dpage/pgadmin4 | latest | 783MB | 532MB | 数据库管理 |

**镜像总大小**: 约 2.4GB（本地）/ 约 1.6GB（服务器压缩后）

---

## 二、前置准备

### 2.1 本地环境
- macOS 23.6.0
- Docker Desktop（已安装并运行）
- 足够的磁盘空间（至少5GB空闲）
- SSH客户端
- 工作目录: `/Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud`

### 2.2 远程服务器
- IP地址: 8.152.101.166
- 操作系统: Linux
- Docker Engine已安装
- Docker Compose V2已安装
- SSH访问权限（root用户）
- 足够的磁盘空间（至少10GB）

### 2.3 网络要求
- 本地到服务器的SSH连接稳定
- 足够的带宽传输约2.4GB数据

---

## 三、步骤一：本地导出Docker镜像

### 3.1 创建镜像导出目录

```bash
# 在本地创建临时目录存放导出的镜像
cd /Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud
mkdir -p docker-images-export
cd docker-images-export
```

### 3.2 查看需要导出的镜像

```bash
# 查看本地所有相关镜像
docker images | grep -E "appflowyinc|pgvector|redis|minio|nginx.*alpine|pgadmin"
```

**预期输出**:
```
appflowyinc/appflowy_cloud   latest           3c0537691ac8   207MB
appflowyinc/gotrue           dev-aliyun-sms   a079af591276   75.6MB
appflowyinc/appflowy_ai      latest           705f9d48475b   190MB
pgvector/pgvector            pg16             c3c84b85691a   625MB
redis                        latest           f0957bcaa75f   200MB
minio/minio                  latest           14cea493d9a3   241MB
nginx                        alpine           42a516af16b8   79.3MB
dpage/pgadmin4               latest           d115bcd73794   783MB
```

### 3.3 导出所有镜像（方法一：单个导出）

```bash
# 导出 AppFlowy Cloud 主服务镜像
docker save -o appflowy_cloud.tar appflowyinc/appflowy_cloud:latest

# 导出 GoTrue 认证服务镜像
docker save -o gotrue.tar appflowyinc/gotrue:dev-aliyun-sms

# 导出 AI 服务镜像
docker save -o appflowy_ai.tar appflowyinc/appflowy_ai:latest

# 导出 PostgreSQL 数据库镜像
docker save -o pgvector.tar pgvector/pgvector:pg16

# 导出 Redis 缓存镜像
docker save -o redis.tar redis:latest

# 导出 MinIO 对象存储镜像
docker save -o minio.tar minio/minio:latest

# 导出 Nginx 反向代理镜像
docker save -o nginx.tar nginx:alpine

# 导出 PgAdmin 数据库管理镜像
docker save -o pgadmin4.tar dpage/pgadmin4:latest
```

### 3.4 导出所有镜像（方法二：批量导出到单个文件）

```bash
# 将所有镜像导出到一个tar文件（推荐用于传输）
docker save -o appflowy-cloud-all-images.tar \
  appflowyinc/appflowy_cloud:latest \
  appflowyinc/gotrue:dev-aliyun-sms \
  appflowyinc/appflowy_ai:latest \
  pgvector/pgvector:pg16 \
  redis:latest \
  minio/minio:latest \
  nginx:alpine \
  dpage/pgadmin4:latest
```

**说明**:
- 方法一：每个镜像单独导出，方便按需传输
- 方法二：所有镜像打包到一个文件，传输更方便
- 本次操作采用**方法二**

### 3.5 验证导出的镜像文件

```bash
# 查看导出文件大小
ls -lh appflowy-cloud-all-images.tar

# 预期输出类似：
# -rw-r--r--  1 kuncao  staff   2.3G Oct  9 14:30 appflowy-cloud-all-images.tar
```

### 3.6 可选：压缩镜像文件（减少传输时间）

```bash
# 使用gzip压缩（压缩率高，但速度慢）
gzip appflowy-cloud-all-images.tar
# 生成文件: appflowy-cloud-all-images.tar.gz

# 或使用pigz并行压缩（更快，需要先安装pigz）
# brew install pigz
# pigz appflowy-cloud-all-images.tar
# 生成文件: appflowy-cloud-all-images.tar.gz

# 查看压缩后文件大小
ls -lh appflowy-cloud-all-images.tar.gz
# 预期压缩后约 1.5GB - 1.8GB
```

---

## 四、步骤二：传输镜像文件到服务器

### 4.1 在服务器上创建接收目录

```bash
# SSH连接到服务器并创建目录
ssh root@8.152.101.166 "mkdir -p /root/docker-images"
```

### 4.2 使用SCP传输镜像文件

#### 方式A：传输未压缩文件

```bash
# 传输tar文件到服务器（耗时较长，约2.3GB）
scp appflowy-cloud-all-images.tar root@8.152.101.166:/root/docker-images/

# 传输进度会实时显示：
# appflowy-cloud-all-images.tar    23%  534MB  12.3MB/s   02:15 ETA
```

#### 方式B：传输压缩文件（推荐）

```bash
# 传输压缩后的文件到服务器（耗时更短，约1.5GB）
scp appflowy-cloud-all-images.tar.gz root@8.152.101.166:/root/docker-images/

# 传输完成后在服务器上解压
ssh root@8.152.101.166 "cd /root/docker-images && gunzip appflowy-cloud-all-images.tar.gz"
```

#### 方式C：边压缩边传输（最优化）

```bash
# 使用管道直接传输，无需本地存储压缩文件
docker save \
  appflowyinc/appflowy_cloud:latest \
  appflowyinc/gotrue:dev-aliyun-sms \
  appflowyinc/appflowy_ai:latest \
  pgvector/pgvector:pg16 \
  redis:latest \
  minio/minio:latest \
  nginx:alpine \
  dpage/pgadmin4:latest \
| gzip | ssh root@8.152.101.166 "cat > /root/docker-images/appflowy-cloud-all-images.tar.gz"

# 然后在服务器上解压
ssh root@8.152.101.166 "cd /root/docker-images && gunzip appflowy-cloud-all-images.tar.gz"
```

### 4.3 验证传输完成

```bash
# 检查服务器上的文件
ssh root@8.152.101.166 "ls -lh /root/docker-images/"

# 预期输出：
# -rw-r--r-- 1 root root 2.3G Oct  9 14:35 appflowy-cloud-all-images.tar
```

### 4.4 计算文件校验和（可选，确保传输完整性）

```bash
# 本地计算MD5
md5 appflowy-cloud-all-images.tar

# 服务器上计算MD5
ssh root@8.152.101.166 "md5sum /root/docker-images/appflowy-cloud-all-images.tar"

# 对比两个MD5值是否一致
```

---

## 五、步骤三：在服务器上导入镜像

### 5.1 SSH连接到服务器

```bash
ssh root@8.152.101.166
```

### 5.2 导入镜像

```bash
# 进入镜像目录
cd /root/docker-images

# 导入所有镜像（从单个tar文件）
docker load -i appflowy-cloud-all-images.tar
```

**导入过程输出示例**:
```
Loaded image: appflowyinc/appflowy_cloud:latest
Loaded image: appflowyinc/gotrue:dev-aliyun-sms
Loaded image: appflowyinc/appflowy_ai:latest
Loaded image: pgvector/pgvector:pg16
Loaded image: redis:latest
Loaded image: minio/minio:latest
Loaded image: nginx:alpine
Loaded image: dpage/pgadmin4:latest
```

### 5.3 验证镜像导入成功

```bash
# 查看所有导入的镜像
docker images

# 或者筛选查看特定镜像
docker images | grep -E "appflowyinc|pgvector|redis|minio|nginx.*alpine|pgadmin"
```

**预期输出**:
```
REPOSITORY                   TAG              IMAGE ID       SIZE
appflowyinc/appflowy_cloud   latest           3c0537691ac8   207MB
appflowyinc/gotrue           dev-aliyun-sms   a079af591276   75.6MB
appflowyinc/appflowy_ai      latest           705f9d48475b   190MB
pgvector/pgvector            pg16             c3c84b85691a   625MB
redis                        latest           f0957bcaa75f   200MB
minio/minio                  latest           14cea493d9a3   241MB
nginx                        alpine           42a516af16b8   79.3MB
dpage/pgadmin4               latest           d115bcd73794   783MB
```

### 5.4 清理镜像文件（可选）

```bash
# 导入成功后可以删除tar文件以释放空间
rm -f /root/docker-images/appflowy-cloud-all-images.tar

# 或者保留备份以便后续使用
# 建议至少保留到服务稳定运行后再删除
```

---

## 六、步骤四：传输配置文件到服务器

### 6.1 创建部署目录

```bash
# 在服务器上创建docker-compose部署目录
ssh root@8.152.101.166 "mkdir -p /root/docker-compose/nginx"
```

### 6.2 从本地传输配置文件

```bash
# 回到本地AppFlowy-Cloud项目目录
cd /Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud

# 传输.env环境变量文件
scp .env root@8.152.101.166:/root/docker-compose/

# 传输docker-compose配置文件
scp docker-compose-dev.yml root@8.152.101.166:/root/docker-compose/

# 传输nginx配置文件
scp deploy/nginx/nginx.conf root@8.152.101.166:/root/docker-compose/nginx/
```

### 6.3 验证配置文件传输成功

```bash
# 检查服务器上的配置文件
ssh root@8.152.101.166 "ls -la /root/docker-compose/"

# 预期输出：
# -rw-r--r-- 1 root root  1234 Oct  9 14:40 .env
# -rw-r--r-- 1 root root  5678 Oct  9 14:40 docker-compose-dev.yml
# drwxr-xr-x 2 root root  4096 Oct  9 14:40 nginx
```

---

## 七、步骤五：启动Docker Compose服务集群

### 7.1 SSH连接到服务器

```bash
ssh root@8.152.101.166
```

### 7.2 进入部署目录

```bash
cd /root/docker-compose
```

### 7.3 验证docker-compose配置

```bash
# 验证docker-compose配置文件语法
docker compose --file docker-compose-dev.yml config

# 查看将要启动的服务
docker compose --file docker-compose-dev.yml config --services
```

**预期输出**:
```
postgres
redis
minio
gotrue
appflowy_cloud
ai
nginx
pgadmin
```

### 7.4 启动服务集群

```bash
# 启动所有服务（后台运行）
docker compose --file docker-compose-dev.yml up -d
```

**启动过程输出**:
```
[+] Running 8/8
 ✔ Container docker-compose-postgres-1         Started
 ✔ Container docker-compose-redis-1            Started
 ✔ Container docker-compose-minio-1            Started
 ✔ Container docker-compose-gotrue-1           Started
 ✔ Container docker-compose-appflowy_cloud-1   Started
 ✔ Container docker-compose-ai-1               Started
 ✔ Container docker-compose-nginx-1            Started
 ✔ Container docker-compose-pgadmin-1          Started
```

### 7.5 查看服务启动状态

```bash
# 查看所有容器状态
docker compose --file docker-compose-dev.yml ps
```

**正常状态输出**:
```
NAME                              STATUS
docker-compose-appflowy_cloud-1   Up (healthy)
docker-compose-gotrue-1           Up (healthy)
docker-compose-postgres-1         Up (healthy)
docker-compose-redis-1            Up
docker-compose-minio-1            Up
docker-compose-nginx-1            Up
docker-compose-pgadmin-1          Up
docker-compose-ai-1               Up (或 Restarting - 可忽略)
```

### 7.6 查看服务日志

```bash
# 查看所有服务日志（实时滚动）
docker compose --file docker-compose-dev.yml logs -f

# 查看特定服务日志
docker compose --file docker-compose-dev.yml logs -f appflowy_cloud
docker compose --file docker-compose-dev.yml logs -f gotrue
docker compose --file docker-compose-dev.yml logs -f postgres

# 按Ctrl+C退出日志查看
```

---

## 八、步骤六：验证服务运行状态

### 8.1 检查容器健康状态

```bash
# 查看容器详细状态
docker compose --file docker-compose-dev.yml ps

# 查看特定容器的健康检查
docker inspect docker-compose-postgres-1 | grep -A 10 "Health"
```

### 8.2 测试服务端点（服务器内部测试）

```bash
# 测试AppFlowy Cloud主服务
curl http://localhost:8000/

# 测试GoTrue认证服务
curl http://localhost:9999/health

# 测试Nginx反向代理
curl http://localhost:9998/

# 测试PostgreSQL连接
docker compose --file docker-compose-dev.yml exec postgres psql -U postgres -c "SELECT version();"

# 测试Redis连接
docker compose --file docker-compose-dev.yml exec redis redis-cli ping
# 预期输出: PONG

# 测试MinIO
curl http://localhost:9000/minio/health/live
# 预期输出: OK
```

### 8.3 从外网访问测试（在本地执行）

```bash
# 退出SSH，回到本地终端

# 测试AppFlowy Cloud API
curl http://8.152.101.166:8000/

# 测试GoTrue认证服务
curl http://8.152.101.166:9999/health

# 测试Nginx代理
curl http://8.152.101.166:9998/

# 测试PgAdmin（浏览器访问）
# http://8.152.101.166:5400
# 默认账号: admin@example.com
# 默认密码: admin

# 测试MinIO控制台（浏览器访问）
# http://8.152.101.166:9001
# 默认账号: minioadmin
# 默认密码: minioadmin
```

### 8.4 验证数据持久化

```bash
# 查看数据卷
docker volume ls | grep docker-compose

# 预期输出：
# docker-compose_postgres_data
# docker-compose_minio_data

# 查看卷详细信息
docker volume inspect docker-compose_postgres_data
docker volume inspect docker-compose_minio_data
```

---

## 九、服务架构和端口映射

### 9.1 服务架构图

```
                        ┌─────────────────────────┐
                        │  外网访问 (Internet)    │
                        └───────────┬─────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌───────▼──────┐ ┌─────▼────┐  ┌──────▼──────┐
            │   Nginx      │ │ AppFlowy │  │   GoTrue    │
            │  :9998       │ │  :8000   │  │   :9999     │
            └──────┬───────┘ └────┬─────┘  └──────┬──────┘
                   │              │                │
                   └──────────────┼────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────┐
        │                         │                         │
 ┌──────▼──────┐          ┌──────▼──────┐         ┌───────▼───────┐
 │  PostgreSQL │          │    Redis    │         │     MinIO     │
 │    :5432    │          │    :6379    │         │  :9000/:9001  │
 └─────────────┘          └─────────────┘         └───────────────┘
        │
        │
 ┌──────▼──────┐
 │   PgAdmin   │
 │    :5400    │
 └─────────────┘
```

### 9.2 端口映射详情

| 服务名称 | 容器内端口 | 主机端口 | 协议 | 访问方式 | 说明 |
|---------|-----------|---------|------|---------|------|
| appflowy_cloud | 8000 | 8000 | HTTP | http://8.152.101.166:8000 | 主API服务 |
| gotrue | 9999 | 9999 | HTTP | http://8.152.101.166:9999 | 认证服务 |
| nginx | 9998 | 9998 | HTTP | http://8.152.101.166:9998 | 反向代理 |
| postgres | 5432 | 5432 | TCP | 8.152.101.166:5432 | 数据库服务 |
| redis | 6379 | 6379 | TCP | 8.152.101.166:6379 | 缓存服务 |
| minio | 9000 | 9000 | HTTP | http://8.152.101.166:9000 | 对象存储API |
| minio | 9001 | 9001 | HTTP | http://8.152.101.166:9001 | MinIO控制台 |
| pgadmin | 80 | 5400 | HTTP | http://8.152.101.166:5400 | 数据库管理 |
| ai | 5001 | - | HTTP | 内部调用 | AI服务（内部） |

### 9.3 服务间依赖关系

```yaml
启动顺序:
1. postgres (数据库) - 基础服务，其他服务依赖
2. redis (缓存) - 基础服务
3. minio (对象存储) - 基础服务
4. gotrue (认证) - 依赖 postgres
5. appflowy_cloud (主服务) - 依赖 postgres、redis、gotrue
6. ai (AI服务) - 依赖 postgres、redis
7. nginx (代理) - 依赖 appflowy_cloud、gotrue
8. pgadmin (管理工具) - 可选，不影响核心服务
```

---

## 十、常用运维命令

### 10.1 服务管理

```bash
# 进入工作目录
cd /root/docker-compose

# === 启动服务 ===
# 启动所有服务
docker compose --file docker-compose-dev.yml up -d

# 启动特定服务
docker compose --file docker-compose-dev.yml up -d appflowy_cloud

# === 停止服务 ===
# 停止所有服务（保留容器）
docker compose --file docker-compose-dev.yml stop

# 停止特定服务
docker compose --file docker-compose-dev.yml stop appflowy_cloud

# 停止并删除容器
docker compose --file docker-compose-dev.yml down

# 停止并删除容器和数据卷（危险操作！）
docker compose --file docker-compose-dev.yml down -v

# === 重启服务 ===
# 重启所有服务
docker compose --file docker-compose-dev.yml restart

# 重启特定服务
docker compose --file docker-compose-dev.yml restart appflowy_cloud

# === 查看状态 ===
# 查看服务运行状态
docker compose --file docker-compose-dev.yml ps

# 查看服务资源占用
docker compose --file docker-compose-dev.yml stats

# 查看服务配置
docker compose --file docker-compose-dev.yml config
```

### 10.2 日志管理

```bash
# === 实时日志 ===
# 查看所有服务日志（实时滚动）
docker compose --file docker-compose-dev.yml logs -f

# 查看特定服务日志
docker compose --file docker-compose-dev.yml logs -f appflowy_cloud

# 查看多个服务日志
docker compose --file docker-compose-dev.yml logs -f appflowy_cloud gotrue

# === 历史日志 ===
# 查看最近100行日志
docker compose --file docker-compose-dev.yml logs --tail=100

# 查看特定时间后的日志
docker compose --file docker-compose-dev.yml logs --since 2025-10-09T10:00:00

# 查看特定时间段的日志
docker compose --file docker-compose-dev.yml logs --since 2025-10-09T10:00:00 --until 2025-10-09T11:00:00

# === 导出日志 ===
# 导出所有服务日志到文件
docker compose --file docker-compose-dev.yml logs > logs_$(date +%Y%m%d_%H%M%S).txt

# 导出特定服务日志
docker compose --file docker-compose-dev.yml logs appflowy_cloud > appflowy_$(date +%Y%m%d).log
```

### 10.3 容器操作

```bash
# === 进入容器 ===
# 进入容器执行命令
docker compose --file docker-compose-dev.yml exec appflowy_cloud sh
docker compose --file docker-compose-dev.yml exec postgres bash

# 以root用户进入容器
docker compose --file docker-compose-dev.yml exec -u root appflowy_cloud sh

# === 在容器中执行命令（不进入） ===
# 在PostgreSQL容器中执行SQL
docker compose --file docker-compose-dev.yml exec postgres psql -U postgres -c "SELECT * FROM users LIMIT 10;"

# 在Redis容器中执行命令
docker compose --file docker-compose-dev.yml exec redis redis-cli INFO

# === 容器资源管理 ===
# 查看容器资源使用
docker compose --file docker-compose-dev.yml stats --no-stream

# 查看容器详细信息
docker inspect docker-compose-appflowy_cloud-1
```

### 10.4 镜像管理

```bash
# === 查看镜像 ===
# 查看所有镜像
docker images

# 查看特定镜像
docker images | grep appflowyinc

# === 更新镜像 ===
# 拉取最新镜像（在线环境）
docker compose --file docker-compose-dev.yml pull

# 重新导入镜像（离线环境）
docker load -i /root/docker-images/appflowy-cloud-all-images.tar

# === 清理镜像 ===
# 删除未使用的镜像
docker image prune -a

# 清理所有未使用的资源（镜像、容器、网络、卷）
docker system prune -a --volumes
```

### 10.5 数据卷管理

```bash
# === 查看数据卷 ===
# 列出所有数据卷
docker volume ls

# 查看特定数据卷详情
docker volume inspect docker-compose_postgres_data

# === 备份数据卷 ===
# 备份PostgreSQL数据卷
docker run --rm \
  -v docker-compose_postgres_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres_backup_$(date +%Y%m%d).tar.gz -C /data .

# 备份MinIO数据卷
docker run --rm \
  -v docker-compose_minio_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/minio_backup_$(date +%Y%m%d).tar.gz -C /data .

# === 恢复数据卷 ===
# 恢复PostgreSQL数据卷（先停止服务）
docker compose --file docker-compose-dev.yml stop postgres
docker run --rm \
  -v docker-compose_postgres_data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/postgres_backup_20251009.tar.gz"
docker compose --file docker-compose-dev.yml start postgres

# === 清理数据卷 ===
# 删除未使用的数据卷
docker volume prune
```

---

## 十一、数据备份和恢复

### 11.1 PostgreSQL数据库备份

```bash
# === 完整备份 ===
# 备份所有数据库
docker compose --file docker-compose-dev.yml exec postgres \
  pg_dumpall -U postgres > full_backup_$(date +%Y%m%d).sql

# 备份单个数据库
docker compose --file docker-compose-dev.yml exec postgres \
  pg_dump -U postgres -d postgres > postgres_backup_$(date +%Y%m%d).sql

# === 压缩备份 ===
# 备份并压缩
docker compose --file docker-compose-dev.yml exec postgres \
  pg_dump -U postgres -d postgres | gzip > postgres_backup_$(date +%Y%m%d).sql.gz

# === 定时备份脚本 ===
# 创建备份脚本
cat > /root/scripts/backup_postgres.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups/postgres"
mkdir -p $BACKUP_DIR
cd /root/docker-compose
docker compose --file docker-compose-dev.yml exec -T postgres \
  pg_dump -U postgres -d postgres | gzip > $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz
# 删除30天前的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete
EOF

chmod +x /root/scripts/backup_postgres.sh

# 添加到crontab（每天凌晨2点备份）
# crontab -e
# 0 2 * * * /root/scripts/backup_postgres.sh
```

### 11.2 PostgreSQL数据恢复

```bash
# === 从备份恢复 ===
# 恢复未压缩的备份
docker compose --file docker-compose-dev.yml exec -T postgres \
  psql -U postgres -d postgres < postgres_backup_20251009.sql

# 恢复压缩的备份
gunzip < postgres_backup_20251009.sql.gz | \
  docker compose --file docker-compose-dev.yml exec -T postgres \
  psql -U postgres -d postgres

# === 完整恢复流程 ===
# 1. 停止依赖数据库的服务
docker compose --file docker-compose-dev.yml stop appflowy_cloud gotrue ai

# 2. 清空现有数据（可选）
docker compose --file docker-compose-dev.yml exec postgres \
  psql -U postgres -c "DROP DATABASE IF EXISTS postgres;"
docker compose --file docker-compose-dev.yml exec postgres \
  psql -U postgres -c "CREATE DATABASE postgres;"

# 3. 恢复数据
gunzip < postgres_backup_20251009.sql.gz | \
  docker compose --file docker-compose-dev.yml exec -T postgres \
  psql -U postgres -d postgres

# 4. 重启所有服务
docker compose --file docker-compose-dev.yml restart
```

### 11.3 MinIO对象存储备份

```bash
# === 使用mc客户端备份 ===
# 安装mc客户端（在服务器上）
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/

# 配置mc别名
mc alias set local http://localhost:9000 minioadmin minioadmin

# 备份所有bucket
mc mirror local /root/backups/minio/$(date +%Y%m%d)

# === 使用数据卷备份（已在10.5节说明） ===
```

### 11.4 完整系统备份

```bash
# 创建完整备份脚本
cat > /root/scripts/full_backup.sh << 'EOF'
#!/bin/bash
BACKUP_ROOT="/root/backups/full"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cd /root/docker-compose

echo "开始完整备份..."

# 1. 备份配置文件
echo "备份配置文件..."
cp -r /root/docker-compose $BACKUP_DIR/

# 2. 备份PostgreSQL
echo "备份PostgreSQL..."
docker compose --file docker-compose-dev.yml exec -T postgres \
  pg_dump -U postgres -d postgres | gzip > $BACKUP_DIR/postgres.sql.gz

# 3. 备份数据卷
echo "备份数据卷..."
docker run --rm \
  -v docker-compose_postgres_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres_volume.tar.gz -C /data .

docker run --rm \
  -v docker-compose_minio_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/minio_volume.tar.gz -C /data .

# 4. 记录镜像信息
echo "记录镜像信息..."
docker compose --file docker-compose-dev.yml images > $BACKUP_DIR/images.txt

echo "备份完成: $BACKUP_DIR"

# 删除30天前的备份
find $BACKUP_ROOT -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;
EOF

chmod +x /root/scripts/full_backup.sh
```

---

## 十二、故障排查指南

### 12.1 容器无法启动

**问题现象**:
```
Error response from daemon: driver failed programming external connectivity
```

**排查步骤**:

```bash
# 1. 检查端口占用
netstat -tulnp | grep 8000
netstat -tulnp | grep 9999

# 2. 查看容器日志
docker compose --file docker-compose-dev.yml logs [服务名]

# 3. 检查镜像是否存在
docker images | grep appflowyinc

# 4. 检查磁盘空间
df -h

# 5. 检查Docker状态
systemctl status docker

# 6. 重启Docker服务
systemctl restart docker
```

**解决方案**:
- 如果端口被占用，修改docker-compose配置或停止占用进程
- 如果磁盘空间不足，清理日志和未使用的镜像
- 如果Docker服务异常，重启Docker

### 12.2 数据库连接失败

**问题现象**:
```
FATAL: password authentication failed for user "postgres"
could not connect to server: Connection refused
```

**排查步骤**:

```bash
# 1. 检查PostgreSQL容器状态
docker compose --file docker-compose-dev.yml ps postgres

# 2. 检查PostgreSQL健康状态
docker inspect docker-compose-postgres-1 | grep -A 10 "Health"

# 3. 查看PostgreSQL日志
docker compose --file docker-compose-dev.yml logs postgres

# 4. 测试数据库连接
docker compose --file docker-compose-dev.yml exec postgres \
  psql -U postgres -c "SELECT 1;"

# 5. 检查网络连通性
docker compose --file docker-compose-dev.yml exec appflowy_cloud \
  ping -c 3 postgres
```

**解决方案**:
- 检查.env文件中的POSTGRES_PASSWORD是否正确
- 确认postgres容器的健康检查通过
- 等待postgres完全启动（通常需要10-30秒）
- 检查docker-compose中的depends_on配置

### 12.3 服务间网络不通

**问题现象**:
```
dial tcp: lookup postgres on 127.0.0.11:53: no such host
```

**排查步骤**:

```bash
# 1. 查看Docker网络
docker network ls

# 2. 检查服务网络配置
docker network inspect docker-compose_default

# 3. 测试容器间连通性
docker compose --file docker-compose-dev.yml exec appflowy_cloud ping postgres
docker compose --file docker-compose-dev.yml exec gotrue ping postgres

# 4. 检查DNS解析
docker compose --file docker-compose-dev.yml exec appflowy_cloud nslookup postgres
```

**解决方案**:
- 确认所有服务在同一个Docker网络中
- 使用服务名而非IP地址进行容器间通信
- 重启Docker网络: `docker compose down && docker compose up -d`

### 12.4 AI服务持续重启

**问题现象**:
```
docker-compose-ai-1  Restarting (1) 5 seconds ago
```

**排查步骤**:

```bash
# 查看AI服务日志
docker compose --file docker-compose-dev.yml logs ai --tail=100
```

**解决方案**:
AI服务为可选组件，不影响核心功能。可以选择：

1. **忽略AI服务**（推荐）
   - AI服务重启不影响其他服务正常运行

2. **临时停止AI服务**
   ```bash
   docker compose --file docker-compose-dev.yml stop ai
   ```

3. **从配置中移除AI服务**
   - 编辑docker-compose-dev.yml，注释掉ai服务部分

### 12.5 镜像导入失败

**问题现象**:
```
Error processing tar file: unexpected EOF
```

**排查步骤**:

```bash
# 1. 检查tar文件完整性
ls -lh appflowy-cloud-all-images.tar

# 2. 验证tar文件
tar -tzf appflowy-cloud-all-images.tar > /dev/null

# 3. 对比本地和服务器文件大小
# 本地：
ls -lh appflowy-cloud-all-images.tar
# 服务器：
ssh root@8.152.101.166 "ls -lh /root/docker-images/appflowy-cloud-all-images.tar"

# 4. 比对校验和
md5sum appflowy-cloud-all-images.tar
ssh root@8.152.101.166 "md5sum /root/docker-images/appflowy-cloud-all-images.tar"
```

**解决方案**:
- 如果文件大小不一致，重新传输
- 如果MD5不匹配，重新传输
- 使用rsync代替scp传输大文件：
  ```bash
  rsync -avz --progress appflowy-cloud-all-images.tar root@8.152.101.166:/root/docker-images/
  ```

### 12.6 服务外网无法访问

**问题现象**:
```
curl: (7) Failed to connect to 8.152.101.166 port 8000: Connection refused
```

**排查步骤**:

```bash
# 1. 服务器内部测试
ssh root@8.152.101.166 "curl http://localhost:8000/"

# 2. 检查防火墙
ssh root@8.152.101.166 "iptables -L -n"
ssh root@8.152.101.166 "ufw status"

# 3. 检查端口监听
ssh root@8.152.101.166 "netstat -tulnp | grep 8000"

# 4. 检查云服务商安全组规则
# 登录云服务控制台检查安全组配置
```

**解决方案**:
- 开放防火墙端口（见第九章安全配置）
- 配置云服务商安全组，允许对应端口入站
- 检查docker-compose端口映射是否正确

---

## 十三、性能优化建议

### 13.1 Docker配置优化

```bash
# 编辑Docker daemon配置
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    }
  ]
}
EOF

# 重启Docker使配置生效
systemctl restart docker
```

### 13.2 PostgreSQL性能优化

```bash
# 进入PostgreSQL配置
docker compose --file docker-compose-dev.yml exec postgres bash

# 编辑postgresql.conf（根据服务器内存调整）
# shared_buffers = 256MB      # 25% of RAM
# effective_cache_size = 1GB  # 50-75% of RAM
# maintenance_work_mem = 64MB
# work_mem = 16MB
# max_connections = 100
```

### 13.3 资源限制配置

在docker-compose-dev.yml中添加资源限制：

```yaml
services:
  appflowy_cloud:
    # ... 其他配置 ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 13.4 日志清理

```bash
# 创建日志清理脚本
cat > /root/scripts/cleanup_logs.sh << 'EOF'
#!/bin/bash
# 清理Docker日志
truncate -s 0 /var/lib/docker/containers/*/*-json.log
# 清理旧的备份文件
find /root/backups -name "*.sql.gz" -mtime +30 -delete
# 清理Docker系统
docker system prune -f --volumes --filter "until=168h"
EOF

chmod +x /root/scripts/cleanup_logs.sh

# 添加到crontab（每周日凌晨3点执行）
# 0 3 * * 0 /root/scripts/cleanup_logs.sh
```

---

## 十四、安全加固建议

### 14.1 修改默认密码

```bash
# 编辑.env文件，修改以下密码
cd /root/docker-compose
vi .env

# 修改内容：
POSTGRES_PASSWORD=YOUR_STRONG_PASSWORD_HERE
MINIO_ROOT_PASSWORD=YOUR_MINIO_PASSWORD_HERE
GOTRUE_ADMIN_PASSWORD=YOUR_GOTRUE_PASSWORD_HERE
GOTRUE_JWT_SECRET=YOUR_JWT_SECRET_HERE  # 至少32位随机字符串
```

### 14.2 防火墙配置

```bash
# 安装并配置ufw
apt-get update
apt-get install -y ufw

# 默认策略
ufw default deny incoming
ufw default allow outgoing

# 允许SSH（重要！先配置再启用防火墙）
ufw allow 22/tcp

# 允许必要的服务端口
ufw allow 8000/tcp  # AppFlowy Cloud
ufw allow 9999/tcp  # GoTrue
ufw allow 9998/tcp  # Nginx

# 限制数据库端口仅本地访问（如果不需要外网访问）
# ufw deny 5432/tcp   # PostgreSQL
# ufw deny 6379/tcp   # Redis

# 启用防火墙
ufw enable

# 查看防火墙状态
ufw status verbose
```

### 14.3 使用Nginx反向代理和SSL

```bash
# 安装Certbot（Let's Encrypt）
apt-get install -y certbot python3-certbot-nginx

# 获取SSL证书（需要域名）
# certbot --nginx -d your-domain.com

# 配置Nginx使用HTTPS（在nginx.conf中）
# 详细配置略，参考Nginx SSL配置文档
```

### 14.4 限制容器权限

在docker-compose-dev.yml中添加安全配置：

```yaml
services:
  appflowy_cloud:
    # ... 其他配置 ...
    security_opt:
      - no-new-privileges:true
    read_only: true  # 只读根文件系统
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### 14.5 定期更新

```bash
# 创建更新检查脚本
cat > /root/scripts/check_updates.sh << 'EOF'
#!/bin/bash
echo "检查系统更新..."
apt-get update
apt-get upgrade -y

echo "检查Docker更新..."
# 从本地重新导入最新镜像
# docker load -i /root/docker-images/appflowy-cloud-all-images.tar

echo "重启服务..."
cd /root/docker-compose
docker compose --file docker-compose-dev.yml restart
EOF

chmod +x /root/scripts/check_updates.sh
```

---

## 十五、监控和告警

### 15.1 基础监控脚本

```bash
# 创建监控脚本
cat > /root/scripts/monitor.sh << 'EOF'
#!/bin/bash

ALERT_EMAIL="support@xiaomabiji.com"
COMPOSE_FILE="/root/docker-compose/docker-compose-dev.yml"

# 检查容器状态
check_containers() {
    cd /root/docker-compose
    STOPPED=$(docker compose --file $COMPOSE_FILE ps -q --filter "status=exited")
    if [ -n "$STOPPED" ]; then
        echo "发现停止的容器" | mail -s "Docker容器告警" $ALERT_EMAIL
    fi
}

# 检查磁盘使用率
check_disk() {
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $USAGE -gt 80 ]; then
        echo "磁盘使用率: ${USAGE}%" | mail -s "磁盘空间告警" $ALERT_EMAIL
    fi
}

# 检查内存使用
check_memory() {
    FREE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $FREE_MEM -gt 90 ]; then
        echo "内存使用率: ${FREE_MEM}%" | mail -s "内存告警" $ALERT_EMAIL
    fi
}

# 执行检查
check_containers
check_disk
check_memory
EOF

chmod +x /root/scripts/monitor.sh

# 添加到crontab（每5分钟检查一次）
# */5 * * * * /root/scripts/monitor.sh
```

### 15.2 日志监控

```bash
# 创建错误日志监控脚本
cat > /root/scripts/monitor_logs.sh << 'EOF'
#!/bin/bash

COMPOSE_FILE="/root/docker-compose/docker-compose-dev.yml"
LOG_FILE="/var/log/appflowy_errors.log"

cd /root/docker-compose

# 检查最近5分钟的错误日志
docker compose --file $COMPOSE_FILE logs --since 5m | \
  grep -i "error\|fatal\|panic" >> $LOG_FILE

# 如果有新错误，发送告警
if [ -s $LOG_FILE ]; then
    tail -20 $LOG_FILE | mail -s "AppFlowy错误日志告警" support@xiaomabiji.com
    > $LOG_FILE  # 清空日志文件
fi
EOF

chmod +x /root/scripts/monitor_logs.sh

# 添加到crontab
# */5 * * * * /root/scripts/monitor_logs.sh
```

### 15.3 健康检查脚本

```bash
# 创建健康检查脚本
cat > /root/scripts/health_check.sh << 'EOF'
#!/bin/bash

# 检查API健康状态
check_api() {
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
    if [ "$STATUS" != "200" ]; then
        echo "AppFlowy Cloud API异常: HTTP $STATUS"
        return 1
    fi
    return 0
}

# 检查GoTrue健康状态
check_gotrue() {
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9999/health)
    if [ "$STATUS" != "200" ]; then
        echo "GoTrue服务异常: HTTP $STATUS"
        return 1
    fi
    return 0
}

# 检查PostgreSQL
check_postgres() {
    docker compose --file /root/docker-compose/docker-compose-dev.yml \
      exec -T postgres pg_isready -U postgres > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "PostgreSQL服务异常"
        return 1
    fi
    return 0
}

# 检查Redis
check_redis() {
    docker compose --file /root/docker-compose/docker-compose-dev.yml \
      exec -T redis redis-cli ping > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Redis服务异常"
        return 1
    fi
    return 0
}

# 执行所有检查
ERRORS=""
check_api || ERRORS="$ERRORS\nAPI健康检查失败"
check_gotrue || ERRORS="$ERRORS\nGoTrue健康检查失败"
check_postgres || ERRORS="$ERRORS\nPostgreSQL健康检查失败"
check_redis || ERRORS="$ERRORS\nRedis健康检查失败"

# 如果有错误，发送告警
if [ -n "$ERRORS" ]; then
    echo -e "服务健康检查发现问题:\n$ERRORS" | \
      mail -s "服务健康检查告警" support@xiaomabiji.com
    exit 1
fi

echo "所有服务健康检查通过"
exit 0
EOF

chmod +x /root/scripts/health_check.sh

# 添加到crontab（每10分钟检查一次）
# */10 * * * * /root/scripts/health_check.sh
```

---

## 十六、完整部署命令速查表

### 16.1 本地操作（导出和传输）

```bash
# === 步骤1: 准备工作目录 ===
cd /Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud
mkdir -p docker-images-export
cd docker-images-export

# === 步骤2: 导出所有镜像 ===
docker save -o appflowy-cloud-all-images.tar \
  appflowyinc/appflowy_cloud:latest \
  appflowyinc/gotrue:dev-aliyun-sms \
  appflowyinc/appflowy_ai:latest \
  pgvector/pgvector:pg16 \
  redis:latest \
  minio/minio:latest \
  nginx:alpine \
  dpage/pgadmin4:latest

# === 步骤3: 压缩镜像（可选） ===
gzip appflowy-cloud-all-images.tar

# === 步骤4: 创建服务器目录 ===
ssh root@8.152.101.166 "mkdir -p /root/docker-images /root/docker-compose/nginx"

# === 步骤5: 传输镜像和配置 ===
# 传输镜像
scp appflowy-cloud-all-images.tar.gz root@8.152.101.166:/root/docker-images/

# 传输配置文件
cd /Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud
scp .env root@8.152.101.166:/root/docker-compose/
scp docker-compose-dev.yml root@8.152.101.166:/root/docker-compose/
scp deploy/nginx/nginx.conf root@8.152.101.166:/root/docker-compose/nginx/
```

### 16.2 服务器操作（导入和启动）

```bash
# === 步骤6: SSH连接到服务器 ===
ssh root@8.152.101.166

# === 步骤7: 解压并导入镜像 ===
cd /root/docker-images
gunzip appflowy-cloud-all-images.tar.gz
docker load -i appflowy-cloud-all-images.tar

# === 步骤8: 验证镜像导入 ===
docker images | grep -E "appflowyinc|pgvector|redis|minio|nginx.*alpine|pgadmin"

# === 步骤9: 启动服务集群 ===
cd /root/docker-compose
docker compose --file docker-compose-dev.yml up -d

# === 步骤10: 查看服务状态 ===
docker compose --file docker-compose-dev.yml ps

# === 步骤11: 查看服务日志 ===
docker compose --file docker-compose-dev.yml logs -f

# === 步骤12: 测试服务 ===
curl http://localhost:8000/
curl http://localhost:9999/health
```

### 16.3 一键部署脚本（完整流程）

```bash
# === 本地创建一键部署脚本 ===
cat > /Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud/deploy-to-server.sh << 'EOF'
#!/bin/bash

SERVER="root@8.152.101.166"
LOCAL_DIR="/Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud"
REMOTE_DIR="/root/docker-compose"

echo "=== 开始部署AppFlowy Cloud到服务器 ==="

# 1. 导出镜像
echo "步骤1: 导出Docker镜像..."
cd $LOCAL_DIR
mkdir -p docker-images-export
cd docker-images-export

docker save -o appflowy-cloud-all-images.tar \
  appflowyinc/appflowy_cloud:latest \
  appflowyinc/gotrue:dev-aliyun-sms \
  appflowyinc/appflowy_ai:latest \
  pgvector/pgvector:pg16 \
  redis:latest \
  minio/minio:latest \
  nginx:alpine \
  dpage/pgadmin4:latest

echo "步骤2: 压缩镜像文件..."
gzip -f appflowy-cloud-all-images.tar

# 2. 创建服务器目录
echo "步骤3: 创建服务器目录..."
ssh $SERVER "mkdir -p /root/docker-images $REMOTE_DIR/nginx"

# 3. 传输文件
echo "步骤4: 传输镜像到服务器（约1.5GB，请耐心等待）..."
scp appflowy-cloud-all-images.tar.gz $SERVER:/root/docker-images/

echo "步骤5: 传输配置文件..."
cd $LOCAL_DIR
scp .env $SERVER:$REMOTE_DIR/
scp docker-compose-dev.yml $SERVER:$REMOTE_DIR/
scp deploy/nginx/nginx.conf $SERVER:$REMOTE_DIR/nginx/

# 4. 服务器上导入和启动
echo "步骤6: 在服务器上导入镜像和启动服务..."
ssh $SERVER << 'ENDSSH'
cd /root/docker-images
echo "解压镜像..."
gunzip -f appflowy-cloud-all-images.tar.gz
echo "导入镜像..."
docker load -i appflowy-cloud-all-images.tar
echo "启动服务..."
cd /root/docker-compose
docker compose --file docker-compose-dev.yml down
docker compose --file docker-compose-dev.yml up -d
echo "等待服务启动..."
sleep 10
docker compose --file docker-compose-dev.yml ps
ENDSSH

echo "=== 部署完成！==="
echo "请访问以下地址验证："
echo "  - AppFlowy Cloud: http://8.152.101.166:8000"
echo "  - GoTrue: http://8.152.101.166:9999/health"
echo "  - Nginx: http://8.152.101.166:9998"
echo "  - PgAdmin: http://8.152.101.166:5400"
EOF

chmod +x deploy-to-server.sh

# === 执行部署 ===
./deploy-to-server.sh
```

---

## 十七、部署验证清单

部署完成后，请按照以下清单逐项验证：

### 17.1 镜像验证

- [ ] 本地成功导出8个Docker镜像
- [ ] 镜像文件大小正常（约2.3GB未压缩，约1.5GB压缩）
- [ ] 镜像文件成功传输到服务器
- [ ] 服务器上成功导入所有镜像
- [ ] 镜像ID与本地一致

### 17.2 配置文件验证

- [ ] .env文件传输成功
- [ ] docker-compose-dev.yml文件传输成功
- [ ] nginx配置文件传输成功
- [ ] 配置文件权限正确

### 17.3 服务运行验证

- [ ] postgres容器运行正常（状态：healthy）
- [ ] redis容器运行正常
- [ ] minio容器运行正常
- [ ] gotrue容器运行正常（状态：healthy）
- [ ] appflowy_cloud容器运行正常（状态：healthy）
- [ ] nginx容器运行正常
- [ ] pgadmin容器运行正常
- [ ] ai容器运行或重启（可忽略）

### 17.4 端口访问验证

- [ ] 服务器内部访问：http://localhost:8000 正常
- [ ] 服务器内部访问：http://localhost:9999/health 正常
- [ ] 外网访问：http://8.152.101.166:8000 正常
- [ ] 外网访问：http://8.152.101.166:9999/health 正常
- [ ] 外网访问：http://8.152.101.166:9998 正常
- [ ] 外网访问：http://8.152.101.166:5400 正常（PgAdmin）
- [ ] 外网访问：http://8.152.101.166:9001 正常（MinIO）

### 17.5 数据库验证

- [ ] PostgreSQL可以连接
- [ ] PostgreSQL健康检查通过
- [ ] Redis可以连接并响应PING
- [ ] 数据卷正确挂载
- [ ] 数据持久化正常

### 17.6 日志验证

- [ ] 容器日志无严重错误
- [ ] appflowy_cloud日志正常
- [ ] gotrue日志正常
- [ ] postgres日志正常
- [ ] nginx日志正常

### 17.7 安全验证

- [ ] 防火墙规则配置正确
- [ ] 仅必要端口对外开放
- [ ] 默认密码已修改（生产环境）
- [ ] SSL证书配置（如需要）

---

## 十八、FAQ常见问题

### Q1: 为什么选择离线镜像迁移而不是直接在线拉取？

**A**: 离线镜像迁移适用于以下场景：
- 服务器无法访问外网或网络受限
- 需要保证镜像版本一致性
- 避免镜像拉取失败或速度慢
- 需要快速批量部署多台服务器

### Q2: 镜像导出后占用多少空间？

**A**: 
- 未压缩：约2.3GB
- 压缩后：约1.5GB
- 导入后占用：约2.4GB（包括镜像层）

### Q3: 传输大文件时中断了怎么办？

**A**: 使用rsync支持断点续传：
```bash
rsync -avz --progress --partial \
  appflowy-cloud-all-images.tar.gz \
  root@8.152.101.166:/root/docker-images/
```

### Q4: AI服务一直重启是否影响使用？

**A**: AI服务是可选组件，重启不影响核心功能（文档编辑、协作等），可以忽略或停止该服务。

### Q5: 如何更新镜像？

**A**: 
1. 在本地拉取或构建新镜像
2. 重新导出镜像
3. 传输到服务器
4. 导入并重启服务：
```bash
docker compose --file docker-compose-dev.yml up -d --force-recreate
```

### Q6: 数据会丢失吗？

**A**: 不会。数据存储在Docker数据卷中，容器重启不影响数据。但建议定期备份。

### Q7: 如何迁移到另一台服务器？

**A**: 
1. 导出镜像（使用本文档方法）
2. 备份数据卷（参考第十一章）
3. 在新服务器导入镜像和数据
4. 启动服务

### Q8: 忘记管理员密码怎么办？

**A**: 
```bash
# 修改.env文件中的密码
vi /root/docker-compose/.env

# 重启相关服务
docker compose --file docker-compose-dev.yml restart gotrue
```

### Q9: 磁盘空间不足怎么办？

**A**: 
```bash
# 清理未使用的镜像和容器
docker system prune -a --volumes

# 清理备份文件
find /root/backups -mtime +7 -delete

# 清理日志
truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

### Q10: 如何查看资源使用情况？

**A**: 
```bash
# 查看容器资源占用
docker compose --file docker-compose-dev.yml stats

# 查看系统资源
htop  # 或 top

# 查看磁盘使用
df -h
du -sh /var/lib/docker
```

---

## 十九、总结

### 19.1 部署流程回顾

整个部署流程分为6个主要步骤：

1. **本地导出镜像** → 约5-10分钟
2. **传输文件到服务器** → 约10-30分钟（取决于网络）
3. **服务器导入镜像** → 约5分钟
4. **传输配置文件** → 约1分钟
5. **启动服务集群** → 约2-3分钟
6. **验证服务状态** → 约5分钟

**总计耗时**: 约30-60分钟

### 19.2 关键文件清单

**本地文件**:
```
/Users/kuncao/github.com/PonyNotes-IO/AppFlowy-Cloud/
├── .env                              # 环境变量配置
├── docker-compose-dev.yml            # Docker Compose配置
├── deploy/nginx/nginx.conf           # Nginx配置
└── docker-images-export/
    └── appflowy-cloud-all-images.tar.gz  # 镜像文件
```

**服务器文件**:
```
/root/
├── docker-images/
│   └── appflowy-cloud-all-images.tar     # 导入的镜像
├── docker-compose/
│   ├── .env                              # 环境变量
│   ├── docker-compose-dev.yml            # Compose配置
│   └── nginx/
│       └── nginx.conf                    # Nginx配置
├── scripts/                              # 运维脚本
│   ├── backup_postgres.sh
│   ├── full_backup.sh
│   ├── monitor.sh
│   └── health_check.sh
└── backups/                              # 备份目录
```

### 19.3 核心命令汇总

```bash
# 导出镜像
docker save -o images.tar [镜像列表]

# 传输文件
scp file root@8.152.101.166:/path/

# 导入镜像
docker load -i images.tar

# 启动服务
docker compose --file docker-compose-dev.yml up -d

# 查看状态
docker compose --file docker-compose-dev.yml ps

# 查看日志
docker compose --file docker-compose-dev.yml logs -f

# 重启服务
docker compose --file docker-compose-dev.yml restart

# 停止服务
docker compose --file docker-compose-dev.yml down
```

### 19.4 后续运维重点

1. **定期备份** - 每天自动备份数据库
2. **监控日志** - 及时发现并处理异常
3. **安全更新** - 定期更新系统和镜像
4. **性能优化** - 根据实际使用情况调整配置
5. **容量规划** - 监控磁盘和资源使用

### 19.5 联系方式

- **技术支持邮箱**: support@xiaomabiji.com
- **部署负责人**: kun cao
- **服务器IP**: 8.152.101.166
- **部署日期**: 2025年10月9日

---

## 附录：配置文件模板

### A.1 .env文件完整模板

```env
# =============================================
# AppFlowy Cloud 环境配置文件
# =============================================

# === GoTrue 认证服务配置 ===
GOTRUE_ADMIN_EMAIL=support@xiaomabiji.com
GOTRUE_ADMIN_PASSWORD=Xiaomabiji@123
GOTRUE_JWT_SECRET=hello456
GOTRUE_JWT_EXP=7200
GOTRUE_SITE_URL=http://localhost:9999
GOTRUE_DISABLE_SIGNUP=false

# === 数据库配置 ===
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_PORT=5432

# === Redis 配置 ===
REDIS_URI=redis://redis:6379

# === MinIO 对象存储配置 ===
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_URL=http://minio:9000

# === AppFlowy Cloud 配置 ===
APPFLOWY_ENVIRONMENT=local
APPFLOWY_DATABASE_URL=postgres://postgres:password@postgres:5432/postgres
APPFLOWY_REDIS_URI=redis://redis:6379
APPFLOWY_GOTRUE_BASE_URL=http://gotrue:9999
APPFLOWY_GOTRUE_JWT_SECRET=hello456
APPFLOWY_GOTRUE_JWT_EXP=7200

# === AI 服务配置 ===
APPFLOWY_AI_SERVER_PORT=5001
APPFLOWY_AI_DATABASE_URL=postgresql://postgres:password@postgres:5432/postgres
APPFLOWY_AI_REDIS_URL=redis://redis:6379

# API Keys
DEEPSEEK_API_KEY=e0bba609-e1c1-4197-8add-913ec83a8868
DEEPSEEK_MODEL_NAME=deepseek-v3-250324
DOUBAO_API_KEY=e0bba609-e1c1-4197-8add-913ec83a8868
DOUBAO_MODEL_NAME=deepseek-v3
OPENAI_API_KEY=sk-0gvkpkZOoWs8ZUo206D8E8Be02D646De8e19A8E5996a4cB2

# === PgAdmin 配置 ===
PGADMIN_DEFAULT_EMAIL=admin@example.com
PGADMIN_DEFAULT_PASSWORD=admin

# === 日志配置 ===
RUST_LOG=info
```

---

**文档版本**: v2.0 (离线镜像迁移版)  
**文档作者**: kun cao  
**最后更新**: 2025年10月9日  
**部署状态**: ✅ 成功验证  
**部署方式**: 离线Docker镜像迁移

---

**备注**: 
- 本文档记录了完整的离线Docker镜像迁移部署流程
- 所有命令均已在实际环境中验证
- 适用于网络受限或需要快速批量部署的场景
- 建议妥善保管此文档和镜像文件以备后续使用


