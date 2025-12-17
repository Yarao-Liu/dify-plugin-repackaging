# Dify 1.0 Plugin Downloading and Repackaging

一个用于下载和重新打包 Dify 插件的工具，支持从 Dify 市场、GitHub 或本地文件重新打包插件为离线安装包。

A tool for downloading and repackaging Dify plugins, supporting repackaging plugins from Dify Marketplace, GitHub, or local files into offline installation packages.

## 目录 / Table of Contents

- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
  - [Docker 方式](#docker-方式)
  - [命令行方式](#命令行方式)
- [使用说明](#使用说明)
  - [从 Dify 市场下载并重新打包](#从-dify-市场下载并重新打包)
  - [从 GitHub 下载并重新打包](#从-github-下载并重新打包)
  - [本地插件包重新打包](#本地插件包重新打包)
  - [平台交叉打包](#平台交叉打包)
- [Dify 平台配置](#dify-平台配置)
- [安装插件](#安装插件)
- [常见问题](#常见问题)

## 功能特性

- ✅ 支持从 Dify 官方市场下载插件
- ✅ 支持从 GitHub Releases 下载插件
- ✅ 支持本地插件包重新打包
- ✅ 自动下载并内嵌 Python 依赖包（离线安装）
- ✅ 支持跨平台打包（Linux/macOS, amd64/arm64）
- ✅ Docker 容器化支持

## 系统要求

### 操作系统

- Linux amd64/aarch64
- macOS x86_64/arm64

### Python 版本

Python 版本应与 `dify-plugin-daemon` 中的版本一致，当前为 **3.12.x**

### 依赖工具

**注意：** 脚本使用 `yum` 安装 `unzip` 命令，这只适用于基于 RPM 的 Linux 系统（如 Red Hat Enterprise Linux、CentOS、Fedora、Oracle Linux）。在较新的分发版中，`yum` 已被 `dnf` 替代。

**Note:** The script uses `yum` to install `unzip`, which is only available on RPM-based Linux systems (such as Red Hat Enterprise Linux, CentOS, Fedora, and Oracle Linux), and is now replaced by `dnf` in latest versions.

如果您的系统不支持 `yum` 或 `dnf`，请提前安装 `unzip` 命令：

```bash
# Ubuntu/Debian
sudo apt-get install unzip

# Alpine
apk add unzip

# macOS (使用 Homebrew)
brew install unzip
```

## 关于 dify-plugin 工具

### 工具来源

项目中的 `dify-plugin-xxxx` 二进制文件（如 `dify-plugin-linux-amd64`、`dify-plugin-darwin-arm64` 等）是 **Dify 官方提供的 CLI 工具**，用于打包 Dify 插件。

这些工具是 `dify-plugin-daemon` 项目的一部分，由 Dify 官方团队开发和维护。

### 源码位置

`dify-plugin` CLI 工具的源码通常位于以下位置：

1. **Dify 官方 GitHub 组织**：https://github.com/langgenius
   - 查找 `dify-plugin-daemon` 或相关的插件开发工具仓库

2. **Dify 官方文档**：https://docs.dify.ai
   - 在插件开发文档中可能包含工具源码的链接

3. **Dify 官方发布页面**：
   - 工具的二进制文件可能通过 GitHub Releases 或其他官方渠道发布

### 工具说明

- **用途**：用于将插件源码打包成 `.difypkg` 格式的插件包
- **版本要求**：Python 版本应与 `dify-plugin-daemon` 中的版本一致（当前为 3.12.x）
- **平台支持**：提供 Linux (amd64/arm64) 和 macOS (amd64/arm64) 四个平台的二进制文件

### 如何获取最新版本

如果需要获取最新版本的 `dify-plugin` 工具，建议：

1. 访问 Dify 官方 GitHub 组织页面
2. 查找 `dify-plugin-daemon` 或相关仓库
3. 查看 Releases 页面下载对应平台的二进制文件
4. 替换项目中的旧版本文件

**注意**：本项目中已包含这些工具的二进制文件，可直接使用。如需更新或了解最新信息，请参考 Dify 官方文档和仓库。

## 快速开始

### Docker 方式

#### 1. 修改 Dockerfile 中的参数

编辑 `Dockerfile`，修改默认命令参数：

```dockerfile
CMD ["./plugin_repackaging.sh", "-p", "manylinux_2_17_x86_64", "market", "antv", "visualization", "0.1.7"]
```

参数说明：
- `-p manylinux_2_17_x86_64`: 指定目标平台（可选）
- `market`: 来源类型（market/github/local）
- `antv visualization 0.1.7`: 插件信息（作者、名称、版本）

#### 2. 构建镜像

```bash
docker build -t dify-plugin-repackaging .
```

#### 3. 运行容器

**Linux/macOS:**

```bash
docker run -v $(pwd):/app dify-plugin-repackaging
```

**Windows:**

```cmd
docker run -v %cd%:/app dify-plugin-repackaging
```

#### 4. 覆盖默认命令（可选）

如果需要使用不同的参数，可以在运行时覆盖：

**Linux/macOS:**

```bash
docker run -v $(pwd):/app dify-plugin-repackaging ./plugin_repackaging.sh -p manylinux_2_17_x86_64 market antv visualization 0.1.7
```

**Windows:**

```cmd
docker run -v %cd%:/app dify-plugin-repackaging ./plugin_repackaging.sh -p manylinux_2_17_x86_64 market antv visualization 0.1.7
```

### 命令行方式

#### Windows 用户注意

**推荐使用 Git Bash：**

在 Windows 系统上，推荐使用 **Git Bash** 来运行此脚本。Git Bash 提供了完整的 bash 环境，可以正常运行脚本。

1. **安装 Git for Windows**（如果尚未安装）：
   - 下载地址：https://git-scm.com/download/win
   - 安装时会自动包含 Git Bash

2. **使用 Git Bash 运行脚本：**
   - 右键点击项目文件夹，选择 "Git Bash Here"
   - 或在 Git Bash 中切换到项目目录
   - 然后按照下面的步骤操作

**或者使用 WSL（Windows Subsystem for Linux）：**

如果您使用 WSL，可以按照 Linux 的方式运行脚本。

#### 1. 克隆仓库

```bash
git clone https://github.com/junjiem/dify-plugin-repackaging.git
cd dify-plugin-repackaging
```

#### 2. 添加执行权限

**Linux/macOS/Git Bash/WSL：**

```bash
chmod +x plugin_repackaging.sh
chmod +x dify-plugin-*
```

**注意：** 在 Windows 的 Git Bash 中，`chmod` 命令主要用于设置脚本的执行权限，但 Windows 文件系统可能不完全支持 Unix 权限。如果遇到权限问题，可以直接运行脚本：

```bash
bash plugin_repackaging.sh
```

#### 3. 运行脚本

**交互模式（推荐新手）：**

```bash
# 直接运行脚本，进入交互模式
./plugin_repackaging.sh

# 或使用 bash 命令
bash plugin_repackaging.sh
```

**命令行模式：**

根据不同的来源类型，使用相应的命令（详见下方使用说明）。

## 使用说明

### 从 Dify 市场下载并重新打包

从 Dify 官方市场下载插件并重新打包为离线安装包。

![market](images/market.png)

#### 使用示例

![market-example](images/market-example.png)

```bash
./plugin_repackaging.sh market langgenius agent 0.0.9
```

**命令格式：**

```bash
./plugin_repackaging.sh market [插件作者] [插件名称] [插件版本]
```

**参数说明：**
- `market`: 来源类型
- `[插件作者]`: 插件作者名称（如 `langgenius`）
- `[插件名称]`: 插件名称（如 `agent`）
- `[插件版本]`: 插件版本号（如 `0.0.9`）

**输出文件：**

生成的文件名为：`[作者]-[插件名]_[版本]-offline.difypkg`

例如：`langgenius-agent_0.0.9-offline.difypkg`

![langgenius-agent](images/langgenius-agent.png)

### 从 GitHub 下载并重新打包

从 GitHub Releases 下载插件并重新打包。

![github](images/github.png)

#### 使用示例

![github-example](images/github-example.png)

```bash
./plugin_repackaging.sh github junjiem/dify-plugin-agent-mcp_sse 0.0.1 agent-mcp_see.difypkg
```

**命令格式：**

```bash
./plugin_repackaging.sh github [GitHub仓库] [Release标签] [Assets文件名]
```

**参数说明：**
- `github`: 来源类型
- `[GitHub仓库]`: GitHub 仓库路径（如 `junjiem/dify-plugin-agent-mcp_sse`）或完整 URL
- `[Release标签]`: Release 版本标签（如 `0.0.1` 或 `v0.0.1`）
- `[Assets文件名]`: Release 中的资产文件名，需包含 `.difypkg` 后缀（如 `agent-mcp_see.difypkg`）

**输出文件：**

生成的文件名为：`[Assets文件名（不含后缀）]-[Release标签].difypkg`

例如：`agent-mcp_see-0.0.1.difypkg`

![junjiem-mcp_sse](images/junjiem-mcp_sse.png)

### 本地插件包重新打包

对本地已有的 `.difypkg` 文件进行重新打包，添加离线依赖。

![local](images/local.png)

#### 使用示例

```bash
./plugin_repackaging.sh local ./db_query.difypkg
```

**命令格式：**

```bash
./plugin_repackaging.sh local [插件包路径]
```

**参数说明：**
- `local`: 来源类型
- `[插件包路径]`: 本地 `.difypkg` 文件的路径（相对路径或绝对路径）

**输出文件：**

生成的文件名为：`[原文件名（不含后缀）]-offline.difypkg`

例如：`db_query-offline.difypkg`

![db_query](images/db_query.png)

### 平台交叉打包

当运行环境和目标环境平台不同时，可以使用 `-p` 选项指定目标平台。

**命令格式：**

```bash
./plugin_repackaging.sh -p [平台标识] [来源类型] [其他参数...]
```

**平台标识：**

- `manylinux2014_x86_64` 或 `manylinux_2_17_x86_64`: 用于 x86_64/amd64 架构的 Linux 系统
- `manylinux2014_aarch64` 或 `manylinux_2_17_aarch64`: 用于 aarch64/arm64 架构的 Linux 系统
- `macosx_10_9_x86_64`: 用于 Intel 架构的 macOS 系统
- `macosx_11_0_arm64`: 用于 Apple Silicon 架构的 macOS 系统

**使用示例：**

在 Linux 系统上为 macOS ARM64 打包：

```bash
./plugin_repackaging.sh -p macosx_11_0_arm64 market langgenius agent 0.0.9
```

在 macOS 上为 Linux x86_64 打包：

```bash
./plugin_repackaging.sh -p manylinux_2_17_x86_64 market antv visualization 0.1.7
```

**自定义输出文件名后缀：**

使用 `-s` 选项可以自定义输出文件的后缀：

```bash
./plugin_repackaging.sh -p manylinux_2_17_x86_64 -s linux-amd64 market antv visualization 0.1.7
```

输出文件：`antv-visualization_0.1.7-linux-amd64.difypkg`

## Dify 平台配置

为了安装重新打包的插件，需要在 Dify 平台的 `.env` 配置文件中进行以下设置：

### 1. 禁用签名验证

允许安装未在 Dify Marketplace 上架的插件：

```env
FORCE_VERIFYING_SIGNATURE=false
```

**English:** Change `FORCE_VERIFYING_SIGNATURE` to `false` to allow installation of all plugins that are not listed in the Dify Marketplace.

### 2. 增加插件包大小限制

允许安装更大的插件包（最大 500MB）：

```env
PLUGIN_MAX_PACKAGE_SIZE=524288000
```

**English:** Change `PLUGIN_MAX_PACKAGE_SIZE` to `524288000` (500MB) to allow installation of plugins within 500M.

### 3. 增加 Nginx 上传大小限制

允许上传更大的文件（最大 500MB）：

```env
NGINX_CLIENT_MAX_BODY_SIZE=500M
```

**English:** Change `NGINX_CLIENT_MAX_BODY_SIZE` to `500M` to allow uploading content up to 500M in size.

**注意：** 修改配置后需要重启 Dify 服务才能生效。

## 安装插件

### 通过本地文件安装

1. 访问 Dify 平台的插件管理页面
2. 选择 "Local Package File"（本地插件包文件）
3. 上传重新打包后的 `.difypkg` 文件
4. 完成安装

![install_plugin_via_local](./images/install_plugin_via_local.png)

## 常见问题

### Q: 下载失败怎么办？

**A:** 请检查：
- 网络连接是否正常
- 插件作者、名称和版本是否正确
- GitHub 仓库和 Release 信息是否正确

### Q: 打包失败怎么办？

**A:** 请检查：
- Python 版本是否为 3.12.x
- 是否已安装 `unzip` 命令
- 磁盘空间是否充足
- 插件包的 `requirements.txt` 是否有效

### Q: 如何查看脚本的详细使用说明？

**A:** 运行脚本时不带参数或使用错误的参数：

```bash
./plugin_repackaging.sh
```

### Q: 支持哪些 Python 包平台？

**A:** 支持所有 pip 支持的平台标识，常用平台包括：
- `manylinux2014_x86_64` / `manylinux_2_17_x86_64` (Linux x86_64)
- `manylinux2014_aarch64` / `manylinux_2_17_aarch64` (Linux ARM64)
- `macosx_10_9_x86_64` (macOS Intel)
- `macosx_11_0_arm64` (macOS Apple Silicon)

### Q: 可以自定义 pip 镜像源吗？

**A:** 可以通过环境变量设置：

```bash
export PIP_MIRROR_URL=https://pypi.tuna.tsinghua.edu.cn/simple
./plugin_repackaging.sh market langgenius agent 0.0.9
```

### Q: 可以自定义 GitHub 或市场 API 地址吗？

**A:** 可以通过环境变量设置：

```bash
export GITHUB_API_URL=https://github.com
export MARKETPLACE_API_URL=https://marketplace.dify.ai
./plugin_repackaging.sh market langgenius agent 0.0.9
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=junjiem/dify-plugin-repackaging&type=Date)](https://star-history.com/#junjiem/dify-plugin-repackaging&Date)
