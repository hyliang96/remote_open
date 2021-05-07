#!/bin/bash


code-remote() {
    local hostname=$(echo $1 | awk -F : '{print $1}')
    local abspath=$(echo $1 | awk -F : '{print $2}')
    local has_file=$(ssh $hostname "[ -f '$abspath' ] && echo true")
    local has_dir=$(ssh $hostname "[ -d '$abspath' ] && echo true")
    if [ "$has_file" = true ]; then
        code --file-uri vscode-remote://ssh-remote+${hostname}${abspath}
    elif [ "$has_dir" = true ]; then
        code --folder-uri vscode-remote://ssh-remote+${hostname}${abspath}
    else
        echo "# $hostname:$abspath not exists"
    fi
}
