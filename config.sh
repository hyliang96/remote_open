#!/bin/zsh

# this_dir_abs_path=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)


# 【自己设置一个文件夹，其下专门用来sshfs挂载远程目录】
mount_dir="${HOME}/Desktop/mount"
# 【本地nc端口】
port=8304
