#!/bin/bash
# =============================================================================
# Dify 插件重新打包脚本
# 功能：从 Dify 市场、GitHub 或本地文件下载/获取插件，并重新打包为离线安装包
# 作者：Junjie.M
# =============================================================================

# =============================================================================
# 默认配置变量
# =============================================================================

# 默认 GitHub API 地址
DEFAULT_GITHUB_API_URL=https://github.com

# 默认 Dify 市场 API 地址
DEFAULT_MARKETPLACE_API_URL=https://marketplace.dify.ai

# 默认 pip 镜像源地址（阿里云镜像）
DEFAULT_PIP_MIRROR_URL=https://mirrors.aliyun.com/pypi/simple

# =============================================================================
# 环境变量配置（可通过环境变量覆盖默认值）
# =============================================================================

# GitHub API 地址（可通过 GITHUB_API_URL 环境变量覆盖）
GITHUB_API_URL="${GITHUB_API_URL:-$DEFAULT_GITHUB_API_URL}"

# Dify 市场 API 地址（可通过 MARKETPLACE_API_URL 环境变量覆盖）
MARKETPLACE_API_URL="${MARKETPLACE_API_URL:-$DEFAULT_MARKETPLACE_API_URL}"

# pip 镜像源地址（可通过 PIP_MIRROR_URL 环境变量覆盖）
PIP_MIRROR_URL="${PIP_MIRROR_URL:-$DEFAULT_PIP_MIRROR_URL}"

# =============================================================================
# 系统信息检测
# =============================================================================

# 获取脚本所在目录的绝对路径
CURR_DIR=`dirname $0`
cd $CURR_DIR
CURR_DIR=`pwd`

# 获取当前用户名
USER=`whoami`

# 获取系统架构（如 x86_64, aarch64, arm64）
ARCH_NAME=`uname -m`

# 获取操作系统类型（Linux, Darwin 等），并转换为小写
OS_TYPE=$(uname)
OS_TYPE=$(echo "$OS_TYPE" | tr '[:upper:]' '[:lower:]')

# =============================================================================
# 根据系统架构和操作系统确定使用的 dify-plugin 工具文件名
# =============================================================================

# 默认为 amd64 架构
CMD_NAME="dify-plugin-${OS_TYPE}-amd64"

# 如果是 ARM 架构（arm64 或 aarch64），则使用对应的工具
if [[ "arm64" == "$ARCH_NAME" || "aarch64" == "$ARCH_NAME" ]]; then
	CMD_NAME="dify-plugin-${OS_TYPE}-arm64"
fi

# =============================================================================
# 全局变量
# =============================================================================

# pip 平台参数（用于跨平台打包，通过 -p 选项设置）
PIP_PLATFORM=""

# 输出包的后缀名（默认为 "offline"，可通过 -s 选项自定义）
PACKAGE_SUFFIX="offline"

# =============================================================================
# 函数：从 Dify 市场下载插件
# 参数：
#   $2: 插件作者
#   $3: 插件名称
#   $4: 插件版本
# =============================================================================
market(){
	# 检查参数是否完整
	if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
		echo ""
		echo "Usage: "$0" market [plugin author] [plugin name] [plugin version]"
		echo "Example:"
		echo "	"$0" market junjiem mcp_sse 0.0.1"
		echo "	"$0" market langgenius agent 0.0.9"
		echo ""
		exit 1
	fi
	
	echo "From the Dify Marketplace downloading ..."
	
	# 获取插件信息
	PLUGIN_AUTHOR=$2      # 插件作者
	PLUGIN_NAME=$3        # 插件名称
	PLUGIN_VERSION=$4     # 插件版本
	
	# 构建下载后的本地文件路径
	PLUGIN_PACKAGE_PATH=${CURR_DIR}/${PLUGIN_AUTHOR}-${PLUGIN_NAME}_${PLUGIN_VERSION}.difypkg
	
	# 构建 Dify 市场下载 URL
	PLUGIN_DOWNLOAD_URL=${MARKETPLACE_API_URL}/api/v1/plugins/${PLUGIN_AUTHOR}/${PLUGIN_NAME}/${PLUGIN_VERSION}/download
	
	echo "Downloading ${PLUGIN_DOWNLOAD_URL} ..."
	
	# 使用 curl 下载插件包（-L 表示跟随重定向）
	curl -L -o ${PLUGIN_PACKAGE_PATH} ${PLUGIN_DOWNLOAD_URL}
	
	# 检查下载是否成功
	if [[ $? -ne 0 ]]; then
		echo "Download failed, please check the plugin author, name and version."
		exit 1
	fi
	
	echo "Download success."
	
	# 调用重新打包函数
	repackage ${PLUGIN_PACKAGE_PATH}
}

# =============================================================================
# 函数：从 GitHub Releases 下载插件
# 参数：
#   $2: GitHub 仓库路径（如 junjiem/repo-name 或完整 URL）
#   $3: Release 标签（版本号，如 0.0.1 或 v0.0.1）
#   $4: Assets 文件名（需包含 .difypkg 后缀）
# =============================================================================
github(){
	# 检查参数是否完整
	if [[ -z "$2" || -z "$3" || -z "$4" ]]; then
		echo ""
		echo "Usage: "$0" github [Github repo] [Release title] [Assets name (include .difypkg suffix)]"
		echo "Example:"
		echo "	"$0" github junjiem/dify-plugin-tools-dbquery v0.0.2 db_query.difypkg"
		echo "	"$0" github https://github.com/junjiem/dify-plugin-agent-mcp_sse 0.0.1 agent-mcp_see.difypkg"
		echo ""
		exit 1
	fi
	
	echo "From the Github downloading ..."
	
	# 获取 GitHub 仓库路径
	GITHUB_REPO=$2
	
	# 如果提供的不是完整 URL，则拼接默认的 GitHub API 地址
	if [[ "${GITHUB_REPO}" != "${GITHUB_API_URL}"* ]]; then
		GITHUB_REPO="${GITHUB_API_URL}/${GITHUB_REPO}"
	fi
	
	# 获取 Release 标签和 Assets 文件名
	RELEASE_TITLE=$3
	ASSETS_NAME=$4
	
	# 从 Assets 文件名中提取插件名称（去掉 .difypkg 后缀）
	PLUGIN_NAME="${ASSETS_NAME%.difypkg}"
	
	# 构建下载后的本地文件路径
	PLUGIN_PACKAGE_PATH=${CURR_DIR}/${PLUGIN_NAME}-${RELEASE_TITLE}.difypkg
	
	# 构建 GitHub Releases 下载 URL
	PLUGIN_DOWNLOAD_URL=${GITHUB_REPO}/releases/download/${RELEASE_TITLE}/${ASSETS_NAME}
	
	echo "Downloading ${PLUGIN_DOWNLOAD_URL} ..."
	
	# 使用 curl 下载插件包
	curl -L -o ${PLUGIN_PACKAGE_PATH} ${PLUGIN_DOWNLOAD_URL}
	
	# 检查下载是否成功
	if [[ $? -ne 0 ]]; then
		echo "Download failed, please check the github repo, release title and assets name."
		exit 1
	fi
	
	echo "Download success."
	
	# 调用重新打包函数
	repackage ${PLUGIN_PACKAGE_PATH}
}

# =============================================================================
# 函数：从本地文件重新打包插件
# 参数：
#   $2: 本地 .difypkg 文件路径（相对路径或绝对路径）
# =============================================================================
_local(){
	echo $2
	
	# 检查参数是否提供
	if [[ -z "$2" ]]; then
		echo ""
		echo "Usage: "$0" local [difypkg path]"
		echo "Example:"
		echo "	"$0" local ./db_query.difypkg"
		echo "	"$0" local /root/dify-plugin/db_query.difypkg"
		echo ""
		exit 1
	fi
	
	# 将相对路径转换为绝对路径
	PLUGIN_PACKAGE_PATH=`realpath $2`
	
	# 调用重新打包函数
	repackage ${PLUGIN_PACKAGE_PATH}
}

# =============================================================================
# 函数：重新打包插件为离线安装包
# 功能：
#   1. 解压插件包
#   2. 下载 Python 依赖到 wheels 目录
#   3. 修改 requirements.txt 指向本地 wheels
#   4. 更新 .difyignore 或 .gitignore 文件
#   5. 使用 dify-plugin 工具重新打包
# 参数：
#   $1: 插件包文件路径
# =============================================================================
repackage(){
	local PACKAGE_PATH=$1
	
	# 获取插件包文件名（含扩展名）
	PACKAGE_NAME_WITH_EXTENSION=`basename ${PACKAGE_PATH}`
	
	# 获取插件包名称（不含扩展名）
	PACKAGE_NAME="${PACKAGE_NAME_WITH_EXTENSION%.*}"
	
	echo "Unziping ..."
	
	# 确保 unzip 命令已安装
	install_unzip
	
	# 解压插件包到指定目录（-o 表示覆盖已存在的文件）
	unzip -o ${PACKAGE_PATH} -d ${CURR_DIR}/${PACKAGE_NAME}
	
	# 检查解压是否成功
	if [[ $? -ne 0 ]]; then
		echo "Unzip failed."
		exit 1
	fi
	
	echo "Unzip success."
	echo "Repackaging ..."
	
	# 进入解压后的插件目录
	cd ${CURR_DIR}/${PACKAGE_NAME}
	
	# 下载 Python 依赖包到 wheels 目录
	# ${PIP_PLATFORM}: 平台参数（如果指定了 -p 选项）
	# -r requirements.txt: 从 requirements.txt 读取依赖列表
	# -d ./wheels: 下载到 wheels 目录
	# --index-url: 指定 pip 镜像源
	# --trusted-host: 信任的镜像源主机（避免 SSL 验证问题）
	pip download ${PIP_PLATFORM} -r requirements.txt -d ./wheels --index-url ${PIP_MIRROR_URL} --trusted-host mirrors.aliyun.com
	
	# 检查下载是否成功
	if [[ $? -ne 0 ]]; then
		echo "Pip download failed."
		exit 1
	fi
	
	# 修改 requirements.txt，在文件开头添加离线安装配置
	# --no-index: 不使用 PyPI 索引
	# --find-links=./wheels/: 从本地 wheels 目录查找包
	if [[ "linux" == "$OS_TYPE" ]]; then
		# Linux 系统使用 sed -i（直接修改文件）
		sed -i '1i\--no-index --find-links=./wheels/' requirements.txt
	elif [[ "darwin" == "$OS_TYPE" ]]; then
		# macOS 系统使用 sed -i ".bak"（需要备份文件）
		sed -i ".bak" '1i\
--no-index --find-links=./wheels/
	  ' requirements.txt
		# 删除备份文件
		rm -f requirements.txt.bak
	fi
	
	# 处理忽略文件（.difyignore 或 .gitignore）
	# 确保 wheels 目录不会被忽略，以便打包时包含依赖
	IGNORE_PATH=.difyignore
	
	# 如果 .difyignore 不存在，则使用 .gitignore
	if [ ! -f "$IGNORE_PATH" ]; then
		IGNORE_PATH=.gitignore
	fi
	
	# 如果忽略文件存在，则删除其中对 wheels/ 目录的忽略规则
	if [ -f "$IGNORE_PATH" ]; then
		if [[ "linux" == "$OS_TYPE" ]]; then
			# Linux 系统：删除以 wheels/ 开头的行
			sed -i '/^wheels\//d' "${IGNORE_PATH}"
		elif [[ "darwin" == "$OS_TYPE" ]]; then
			# macOS 系统：删除以 wheels/ 开头的行（需要备份）
			sed -i ".bak" '/^wheels\//d' "${IGNORE_PATH}"
			# 删除备份文件
			rm -f "${IGNORE_PATH}.bak"
		fi
	fi
	
	# 返回脚本目录
	cd ${CURR_DIR}
	
	# 确保 dify-plugin 工具具有执行权限
	chmod 755 ${CURR_DIR}/${CMD_NAME}
	
	# 使用 dify-plugin 工具重新打包插件
	# plugin package: 打包命令
	# ${CURR_DIR}/${PACKAGE_NAME}: 插件源码目录
	# -o: 指定输出文件路径
	# --max-size 5120: 最大包大小为 5120MB（5GB）
	${CURR_DIR}/${CMD_NAME} plugin package ${CURR_DIR}/${PACKAGE_NAME} -o ${CURR_DIR}/${PACKAGE_NAME}-${PACKAGE_SUFFIX}.difypkg --max-size 5120
	
	# 检查打包是否成功
	if [ $? -ne 0 ]; then
		echo "Repackage failed."
		exit 1
	fi
	
	echo "Repackage success."
}

# =============================================================================
# 函数：安装 unzip 工具
# 功能：检查系统是否已安装 unzip，如果没有则尝试安装
# 注意：此函数使用 yum 安装，仅适用于基于 RPM 的 Linux 系统
# =============================================================================
install_unzip(){
	# 检查 unzip 命令是否存在
	if ! command -v unzip &> /dev/null; then
		echo "Installing unzip ..."
		
		# 使用 yum 安装 unzip（-y 表示自动确认）
		yum -y install unzip
		
		# 检查安装是否成功
		if [ $? -ne 0 ]; then
			echo "Install unzip failed."
			exit 1
		fi
	fi
}

# =============================================================================
# 函数：打印使用说明
# =============================================================================
print_usage() {
	echo "usage: $0 [-p platform] [-s package_suffix] {market|github|local}"
	echo "-p platform: python packages' platform. Using for crossing repacking."
	echo "        For example: -p manylinux2014_x86_64 or -p manylinux2014_aarch64"
	echo "-s package_suffix: The suffix name of the output offline package."
	echo "        For example: -s linux-amd64 or -s linux-arm64"
	exit 1
}

# =============================================================================
# 主程序：解析命令行参数
# =============================================================================

# 使用 getopts 解析选项参数
# -p: 指定 Python 包平台（用于跨平台打包）
# -s: 指定输出包的后缀名
while getopts "p:s:" opt; do
	case "$opt" in
		# -p 选项：设置 pip 平台参数
		# --platform: 指定目标平台
		# --only-binary=:all:: 只下载二进制包（wheel），不下载源码包
		p) PIP_PLATFORM="--platform ${OPTARG} --only-binary=:all:" ;;
		
		# -s 选项：设置输出包的后缀名
		s) PACKAGE_SUFFIX="${OPTARG}" ;;
		
		# 其他选项：打印使用说明并退出
		*) print_usage; exit 1 ;;
	esac
done

# 移除已解析的选项参数，保留位置参数
# OPTIND 是 getopts 的内部变量，表示下一个要处理的参数索引
shift $((OPTIND - 1))

# 调试输出：打印第一个位置参数（来源类型）
echo "$1"

# 根据第一个位置参数（来源类型）调用相应的函数
case "$1" in
	'market')
		# 从 Dify 市场下载
		market $@
		;;
	'github')
		# 从 GitHub 下载
		github $@
		;;
	'local')
		# 从本地文件重新打包
		_local $@
		;;
	*)
		# 未知来源类型，打印使用说明并退出
		print_usage
		exit 1
esac

# 正常退出
exit 0
