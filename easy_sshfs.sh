#!/bin/bash


this_dir_abs_path=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $this_dir_abs_path/config.sh


# --------------------- sshfs --------------------------
# 挂载一个磁盘
fs() # fs [用户名@]host别名:[远端路径, 默认为"."]
{

    if [ "$#" -lt "1" ]; then
        echo "Usage: fs [用户名@]host别名:[远端路径, 默认为'.']"
        return
    fi
    local host_remotepath="${1}"
    if [[ "$host_remotepath" =~ : ]]; then
        local host="${host_remotepath%%:*}"
        local remotepath="${host_remotepath#*:}"
    else
        local host="$host_remotepath"
        local remotepath="."
    fi
    local localpath="$mount_dir/${host}"

    if [ "`ps -o pid,args -p $(pgrep sshfs) 2>/dev/null | tail -n +2 | grep \"$localpath \"`" != "" ]; then
        echo $localpath is already mounted, now remount
        umount $localpath # 若在mount此localpath，则关闭之
    else
        umount $localpath >/dev/null 2>&1 # 不输出，但任然验证一遍
    fi

    if [ ! -d $localpath ]; then mkdir $localpath; fi # 若无挂载目录文件夹，则创建之

    command sshfs $host:$remotepath $localpath -o volname=$host -o reconnect -o transform_symlinks -o follow_symlinks
    #  -o local
}


# 卸挂载一个磁盘
ufs()  # ufs [[用户名@]host别名 | 用户名@网址 ] （一个或多个）
{
    if [ "$#" -lt 1 ]; then
        echo "Usage: ufs 本地挂载点 [[本地挂载点] ...] "
        echo "执行fsls，会列出所有$mount_dir下的子文件夹，本地挂载点要写子文件夹"
        echo
        echo "现在执行fsls，"
        fsls
        return
    fi

    for host in $@; do
        # host=$1
        local localpath="$mount_dir/${host}"
        if [ ! -d "$localpath" ]; then
            echo no directory: $localpath
            continue
        fi

        umount $localpath
        if [ "`ls -A $localpath`" = "" ]; then
            rm $localpath -rf # 若挂载目录是空文件夹，则删除之
        else
            echo original dir $localpath is now recovered
        fi
    done
}

# 自动补全
current_shell=$(ps -p $$ -o comm=)
if [[ "$current_shell" == "-zsh" ]]; then
    # -zsh 表示交互式zsh
    _ufs_zsh_completion() {
        # 列出$mount_dir目录下的所有子文件夹
        local dirs=($(find $mount_dir -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
        _describe 'directory' dirs
    }
    compdef _ufs_zsh_completion ufs
elif [[ "$current_shell" == "bash" ]]; then
    # 不论交互还是非交互式bash
    _ufs_bash_completion() {
        local cur prev opts
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD - 1]}"

        opts=($(find $mount_dir -mindepth 1 -maxdepth 1 -type d | xargs -n1 basename ))
        # 在bash中，若子文件夹名为 user@host，则因@符号的干扰，无法显示自动补全
        COMPREPLY=($(compgen -W "${opts[*]}"  -- "${cur}"))

    }
    # 将补全功能绑定到函数 ufs
    complete -F _ufs_bash_completion ufs
fi

# 列出目前mount的所有磁盘的进程
fsjch()
{
    local hadopt=false
    [ -n "$ZSH_VERSION" ] && [ "$(setopt | grep shwordsplit)" != '' ] && \
        hadopt=true && setopt sh_word_split # 若为 zsh则开sh_word_split选项
    local OLD_IFS="$IFS" ; IFS=$'\n' # "【分割字符】"  # 必需是单个字符，但可以是汉字
    # 如果是转义字符需加 $'\某'，如换行，需要写成  $'\n'
    local tmp=($(ps -o pid,args -p $(pgrep sshfs) 2>/dev/null | tail -n +2))
    IFS="$OLD_IFS"
    [ -n "$ZSH_VERSION" ] && [ "$hadopt" = false ] && unsetopt sh_word_split # 若原先没开此选项则关之

    answer=()
    for line in "${tmp[@]}"; do
        local pid="$(echo $line | awk '{print $1}')"
        local remotehost="$(echo $line | awk -F : '{print $1}' | awk '{print $NF}')"
        local remotedir="$(echo $line | awk -F : '{print $2}' | awk '{print $1}')"
        local localdir="$(echo $line | awk '{print $4}')"
        answer+=("$pid\t$remotehost:$remotedir\t$localdir")
    done
    {
    if [ ${#answer} -ne 0 ]; then
        echo "pid\thost_alias:remote_path\tlocal_dir"
        for line in "${answer[@]}"; do
            echo "$line"
        done
    fi } | column -t
    # if [ "$answer" != "" ]; then echo "pid   host_alias:remote_path"; echo $answer; fi
}

# 列出挂载路径
fsls()
{
    echo "$mount_dir/:"
    ls -l --color=always $mount_dir | tail -n +2
}
