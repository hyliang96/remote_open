# remote_open

## 引子

使用ssh连接服务器，不可避免会有用本地的软件开远程文件的需求，比如查看远程图片，或用本地文本编辑器打开远程文件。

显然，此时得将远程文件传达本地，手段不一而足，scp、sftp、rsycn、sshfs等等。然而，不论哪一种，都需要开着两个窗口，一个是ssh连接服务器的终端，一个是用来敲传文件命令的终端。更麻烦的是，得对着前者的服务器ip、用户名、文件路径，来敲后者的命令。要知道，在本地，我们只需要输入`open <file_path(s) or dir_path(s)>`就能一键打开文件（夹）。

为了免去上述体力劳动，我实现了`remote open`工具，可以像在本地用`open`命令一样，一键打开远程文件(夹)。

## 介绍

### 功能
ssh连到服务器后，对着远程的终端:

* 输入`opennc <file_path(s) or dir_path(s)>`，根据文件后缀本，自动选用地软件，打开远程的文件（夹）
* 输入 `subnc <file_path(s) or dir_path(s)>`，用本地sublime，自动打开远程的文件（夹）。（你也可以修改代码，换成你喜欢的文本编辑器）

本脚本自动用sshfs挂载远程目录，无需手动同步文件

### 依赖
  * 服务器：nc
  * 本地：nc、ssh、sshfs、zsh

### 原理
* `ssh`连接服务器，并用`-R`参数进行端口转发，以供`nc`使用
* 在远程输入`opennc <file_path(s) or dir_path(s)>`
* 远程将 [ 【hostname】、【username】、<file_path(s) or dir_path(s)>之绝对路径]，由`nc`发送到本地
* 本地侦听到收到远程`nc`所发，按照其要求将`<username>@< hostname>:/`用`sshfs`挂载到本地
* 用本地的`open`打开所目标文件（夹）

## 实现

### 远程

目的：远程将 [ 【hostname】、【username】、<file_path(s) or dir_path(s)>之绝对路径]，由`nc`发送到本地

在~/.bashrc （或~/.bashrc 会加载的.bash_aliases、.bash_function）中，添加以下代码。

~~~bash
subnc(){
    dirs=""
    for arg in $@; do
        if [ -e $arg ]; then
            path_arg=$(abspath $arg)
            dirs="$dirs; $path_arg"
        else
            echo not exist: $arg
        fi
    done
    if [ "${dirs:0:2}" = "; " ]; then
        dirs=${dirs:2}
    fi
    if [ "$dirs" != "" ]; then
        (echo "sub; $USER; `hostname`; $dirs" | nc localhost 【远程nc端口】  & )   > /dev/null
    fi
}

opennc(){
    dirs=""
    for arg in $@; do
        if [ -e $arg ]; then
            path_arg=$(abspath $arg)
            dirs="$dirs; $path_arg"
        else
            echo not exist: $arg
        fi
    done
    if [ "${dirs:0:2}" = "; " ]; then
        dirs=${dirs:2}
    fi
    if [ "$dirs" != "" ]; then
        (echo "open; $USER; `hostname`; $dirs" | nc localhost 【远程nc端口】  & )   > /dev/null
    fi
}
~~~

### 本地

####  对sshfs的封装 -- easy_sshfs

创建 `~/remote_open/easy_sshfs.sh`
~~~bash
#!/bin/bash

mount_dir=【自己设置一个文件夹，其下专门用来sshfs挂载远程目录】
# --------------------- sshfs --------------------------
# 挂载一个磁盘
fs() # fs host别名 [远端路径, 默认为"."]
{
    if [ "$#" -lt "1" ]; then
        echo "Usage: fs host别名 [远端路径, 默认为'.']"
        return
    fi
    host=$1
    if [ "$#" -gt "1" ]; then
        remotepath="$2"
    else
        remotepath="."
    fi
    localpath="$mountdir/${host}"

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
ufs()  # ufs [[用户名@]host别名 | 用户名@网址 ] （一个或多个）
{
    if [ "$#" -lt "1" ]; then
        echo "Usage: fs [[用户名@]host别名 | 用户名@网址 ] （一个或多个）"
        return
    fi

    for host in $@; do
        # host=$1
        localpath="$mountdir/${host}"

        umount $localpath
        if [ "`ls -A $localpath`" = "" ]; then
            rm $localpath -rf # 若挂载目录是空文件夹，则删除之
        else
            echo original dir $localpath is now recovered
        fi
    done
}
# 列出目前mount的所有磁盘
fsls()
{
    answer=`pgrep -lf sshfs | awk '{print $1 "  " $3}'`
    if [ "$answer" != "" ]; then echo "pid   host_alias:remote_path"; echo $answer; fi
}
# 列出挂载路径
mtls()
{
    ls $mountdir -la
}
~~~

#### 自动挂载远程目录并打开文件
创建 `~/remote_open/remote_open.sh`
~~~bash
#!/bin/bash
. ~/remote_open/easy_sshfs.sh
debug=0     # 需要debug输出设为1

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

mount_dir=$mountdir
[ $debug -ne 0 ] && echo mount_dir: $mount_dir

mount_folder=$user@$host_alias

if ! [[ ${mounts} =~ $mount_folder:/ ]] || ! [ -d $mount_dir/$host_alias/home ]; then
    [ $debug -ne 0 ] && echo hasnt mounted $mount_folder:/, start mounting
    [ $debug -ne 0 ] && echo fs $mount_folder /
    fs $mount_folder /
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
~~~

#### 端口监听

编辑 `~/remote_open/remote_open_listen.sh`

~~~bash
port=【本地nc端口】

this_dir_abs_path=$(cd "$(dirname "$0")"; pwd)

echo start nc
while read line; do
    echo "$line"
    zsh $this_dir_abs_path/remote_open.sh $line
done < <(nc -lk $port)
echo end nc
~~~

### 设置.ssh/config，进行端口转发

为使服务器上nc发送消息到本地被监听到，ssh需将【远程nc端口】同【本地nc端口】转发

~~~ssh
Host 【hostname】
    HostName 【服务器的外网ip 或 url】
    User 【username】
    # 私钥
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey
    # 用于remote open 的端口转发
    RemoteForward 【远程nc端口】 localhost:【本地nc端口】
   # 其他设置...
~~~
其中 
* 【hostname】=服务器上执行`hostname`的输出
* 【username】=服务器上执行`echo $USER`的输出
* 【服务器的外网ip 或 url】=服务器上执行`curl ifconfig.me`的输出

### 设端口监听脚本为开机自启
将端口监听脚本`~/remote_open/remote_open_listen.sh`设置为开机自启、后台运行

#### mac用户
[操作教程详见](https://www.jianshu.com/p/799e3769fb92)

* 在 “自动操作.app”中新建“应用程序”，
* 在其中选中运行shell脚本，
* 选择使用zsh
* 自动操作脚本内容写
~~~zsh
( ( 
zsh ~/remote_open/remote_open_listen.sh
) &) > /dev/null 2>&1
~~~
* 保存到 `~/remote_open/remote_open.app`

* 在`系统偏好设置/用户与群组/登录项`，将`~/remote_open/remote_open.app`选中，并勾选`隐藏`，设为开机启动项目。

#### windows用户
请自行查找windows设置开机自动运行脚本的方法
