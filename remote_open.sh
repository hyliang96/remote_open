#!/bin/bash

this_dir_abs_path=$(cd "$(dirname "$0")"; pwd)
. $this_dir_abs_path/easy_sshfs.sh
. $this_dir_abs_path/config.sh

debug=1     # 需要debug输出设为1

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


mounts="$(pgrep -lf sshfs | awk '{print $3}')"
mounts=("${(@s/\\n/)mounts}")
[ $debug -ne 0 ] && echo mounts: $mounts


[ $debug -ne 0 ] && echo mount_dir: $mount_dir

mount_folder=$user@$host_alias

if ! [[ ${mounts} =~ $mount_folder:/ ]] || ! [ -d $mount_dir/$mount_folder/home ]; then
    [ $debug -ne 0 ] && echo hasnt mounted $mount_folder:/, start mounting
    [ $debug -ne 0 ] && echo easy_sshfs $mount_folder /
    easy_sshfs $mount_folder /
    [ $debug -ne 0 ] && echo finished mounting
else
    [ $debug -ne 0 ] && echo has mounted $mount_folder:/
fi


folders=()
files=()

for remote_path in ${remote_paths}; do
    [ $debug -ne 0 ] && echo remote_path: $remote_path
    local_path=$mount_dir/$mount_folder/$remote_path
    [ $debug -ne 0 ] && echo local_path: $local_path

    if [ -d $local_path ]; then
        [ $debug -ne 0 ] && echo local_path is dir
        folders+="$local_path"
    elif [ -f $local_path ]; then
        [ $debug -ne 0 ] && echo local_path is file
        files+="$local_path"
    else
        echo no such file or directory: $local_path
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
        [ $debug -ne 0 ] && echo $folder
        open  $folder
    done
    if [ $#files -ne 0 ]; then
        open $files
    fi
else
    for folder in $folders; do
        # folder=${folder/ /\\ }
        [ $debug -ne 0 ] && echo $folder
        open -a $open_with $folder
    done
    if [ $#files -ne 0 ]; then
        open -a $open_with $files
    fi
fi
