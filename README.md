# remote_open

## 动机

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

### 文件夹构成与工作原理
* `remote_open_server.sh`: 远程将 [ 【hostname】、【username】、<file_path(s) or dir_path(s)>之绝对路径]，由`nc`发送到本地

* `easy_sshfs.sh`: 封装sshfs，使之更加方便使用
* `remote_open.sh`: 根据远程`nc`所发，自动sshfs挂载远程文件，并用本地`open`打开
* `remote_open_listen.sh`: 侦听远程`nc`所发，调用`remote_open.sh`
* `remote_open.app`：将`remote_open_listen.sh`封装成OSX上的app，以供开机后台自启

## 配置

### 变量

【本地nc端口】 ：选个冷门端口

【本地nc端口】  ：选个冷门端口

【本地挂载路径】：自己键一个文件夹，其下是各台服务器，由sshfs挂载过来的目录们

### 远程

将`remote_open_server.sh`复制到服务器`~/`下

在~/.bashrc，添加以下代码

```bash
[ -f ~/remote_open_server.sh ] && . ~/remote_open_server.sh
```

在`remote_open_server.sh`中修改

```bash
sever_port=【远程nc端口】# 建议选个冷门端口
```

### 本地

####  修改配置

在`config.sh`中设置

```bash
mount_dir=【本地挂载路径】 # 自己键一个文件夹，其下是各台服务器，由sshfs挂载过来的目录们
port=【本地nc端口】 # 建议选个冷门端口
```

#### 设置.ssh/config，进行端口转发

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

#### 设端口监听脚本为开机自启
将端口监听脚本`remote_open/remote_open_listen.sh`设置为开机自启、后台运行

##### mac用户
* 用mac自带程序 “自动操作.app”打开 `remote_open.app`，修改下述路径
~~~zsh
( ( 
zsh 【remote_open repo的绝对路径】/remote_open_listen.sh
) &) > /dev/null 2>&1
~~~
* 在`系统偏好设置/用户与群组/登录项`，将`remote_open/remote_open.app`选中，并勾选`隐藏`，设为开机启动项目。

[操作图文教程详见](https://www.jianshu.com/p/799e3769fb92)

* 然后重启电脑试试，看看是否开机自启

  ```
  lsof -i:【本地nc端口】
  ```

  若显示如下，则自启成功

  ```
  COMMAND  PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
  nc      4240  mac    3u  IPv4 0xa8a6a45ca35153d5      0t0  TCP *:8304 (LISTEN)
  ```

##### windows用户

请自行查找windows设置开机自动运行脚本的方法



