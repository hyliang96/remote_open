#!/bin/bash

this_dir_abs_path=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)

. $this_dir_abs_path/easy_sshfs.sh
. $this_dir_abs_path/config.sh
. $this_dir_abs_path/code-remote.sh


debug=0    # 需要debug输出设为1

string="$1"

args=("${(@s/; /)string}")
[ $debug -ne 0 ] && declare -p args

app=${args[1]}
user=${args[2]}
host_alias=${args[3]}
remote_paths=(${args[@]:3:${#args[@]}})

[ $debug -ne 0 ] && echo app: $app
[ $debug -ne 0 ] && echo user: $user
[ $debug -ne 0 ] && echo host_alias: $host_alias
[ $debug -ne 0 ] && declare -p remote_paths


if [ "$app" = "code" ]; then
    # open_with="/Applications/Visual Studio Code.app"
    for remote_path in "${remote_paths[@]}"; do
        code-remote $host_alias:$remote_path
    done
else
    # 需要sshfs挂载远端目录

    mounts="$(ps -o pid,args -p $(pgrep sshfs) 2>/dev/null | tail -n +2 | awk '{print $3}')"
    mounts=("${(@s/\\n/)mounts}")  # 按换行符分割成数组
    [ $debug -ne 0 ] && echo mounts: $mounts
    [ $debug -ne 0 ] && echo mount_dir: $mount_dir

    mount_folder=$host_alias # $user@$host_alias
    [ $debug -ne 0 ] && echo mount_folder: $mount_folder

    if ! [[ ${mounts} =~ $mount_folder:/ ]] || ! [ -d $mount_dir/$mount_folder/home ]; then
        [ $debug -ne 0 ] && echo hasn\'t mounted $mount_folder:/, start mounting
        [ $debug -ne 0 ] && echo fs \"$mount_folder:/\"
        fs "$mount_folder:/"
        [ $debug -ne 0 ] && echo finished mounting
    else
        [ $debug -ne 0 ] && echo has mounted $mount_folder:/
    fi

    sleep 1 # 需要等一下，本地文件系统才能监测到$local_path存在
    folders=()
    files=()

    for remote_path in ${remote_paths}; do
        [ $debug -ne 0 ] && echo remote_path: $remote_path
        local_path="$mount_dir/$mount_folder$remote_path"
        [ $debug -ne 0 ] && echo local_path: $local_path
        # ls -d $local_path # &>/dev/null
        # ls -d $local_path # &>/dev/null

        if [ -d $local_path ]; then
            [ $debug -ne 0 ] && echo local_path is dir
            folders+="$local_path"
        elif [ -f $local_path ]; then
            [ $debug -ne 0 ] && echo local_path is file
            files+="$local_path"
        else
            echo "no such file or directory: $local_path"
        fi
    done

    [ $debug -ne 0 ] && declare -p folders
    [ $debug -ne 0 ] && declare -p files


    # 用本地软件打开，适用于mac，windows用户需修改下面代码
    if [ "$app" = "sub" ]; then
        # 你也可以修改代码，换成你喜欢的文本编辑器
        open_with="/Applications/Sublime Text.app"
    elif [ "$app" = "open" ]; then
        open_with=""
    fi

    if [ "$open_with" = "" ]; then
        for folder in $folders; do
            # folder=${folder/ /\\ }
            [ $debug -ne 0 ] && echo opening $folder
            open  $folder
        done
        if [ $#files -ne 0 ]; then
            [ $debug -ne 0 ] && echo opening $files
            open $files
        fi
    else
        for folder in $folders; do
            # folder=${folder/ /\\ }
            [ $debug -ne 0 ] && echo opening $folder with $open_with
            open -a $open_with $folder
        done
        if [ $#files -ne 0 ]; then
            [ $debug -ne 0 ] && echo opening $files with $open_with
            open -a $open_with $files
        fi
    fi
fi
