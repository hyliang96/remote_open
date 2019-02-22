#!/bin/bash

this_dir_abs_path=$(cd "$(dirname "$0")"; pwd)
. $this_dir_abs_path/config.sh

# --------------------- sshfs --------------------------
# 挂载一个磁盘
easy_sshfs() # easy_sshfs host别名 [远端路径, 默认为"."]
{
    echo $mount_dir

    if [ "$#" -lt "1" ]; then
        echo "Usage: easy_sshfs host别名 [远端路径, 默认为'.']"
        return
    fi
    host=$1
    if [ "$#" -gt "1" ]; then
        remotepath="$2"
    else
        remotepath="."
    fi
    localpath="$mount_dir/${host}"

    echo $localpath

    if [ "`pgrep -lf sshfs | grep \"$localpath \"`" != "" ]; then
        echo $localpath is already mounted, now remount
        umount $localpath # 若在mount此localpath，则关闭之
    else
        umount $localpath >/dev/null 2>&1 # 不输出，但任然验证一遍
    fi



    if [ ! -d $localpath ]; then mkdir $localpath; fi # 若无挂载目录文件夹，则创建之

    sshfs $host:$remotepath $localpath -o volname=$host -o reconnect -o transform_symlinks -o follow_symlinks
    #  -o local
}
# 卸挂载一个磁盘
easy_usshfs()  # easy_usshfs [[用户名@]host别名 | 用户名@网址 ] （一个或多个）
{
    if [ "$#" -lt "1" ]; then
        echo "Usage: easy_usshfs [[用户名@]host别名 | 用户名@网址 ] （一个或多个）"
        return
    fi

    for host in $@; do
        # host=$1
        localpath="$mount_dir/${host}"

        umount $localpath
        if [ "`ls -A $localpath`" = "" ]; then
            rm $localpath -rf # 若挂载目录是空文件夹，则删除之
        else
            echo original dir $localpath is now recovered
        fi
    done
}
# 列出目前mount的所有磁盘
easy_fsls()
{
    answer=`pgrep -lf sshfs | awk '{print $1 "  " $3}'`
    if [ "$answer" != "" ]; then echo "pid   host_alias:remote_path"; echo $answer; fi
}
# 列出挂载路径
easy_mtls()
{
    ls $mount_dir -la
}
