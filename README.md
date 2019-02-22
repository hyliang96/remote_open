# remote_open

中文readme请`git checkout chinse_version`

## Motivation

When ssh a remote server, it's oftnen necessary to open remote files or folders with local softwares, e.g. to edit codes with local editor, and show images.

To do this, we usually synchronizes files with tools like scp, sftp, rsycn, sshfs, etc. However, everytime opening a remote files, you need fetch its path from terminal, and synchronize it to your local computer, and then open the files  with s local software. This workflow is time comsuming.

With this tool, you only need type one command on remote terminal, thus the remote files or folders will be opened locally, just like use `open` command on local terminal.

## Introduction

### Uasge

ssh a remote serevr, type in terminal:

* `ropen <file_path(s) or dir_path(s)>`: open with local softwares according to suffixes
* `rsubl <file_path(s) or dir_path(s)>`: open with local sublime
* you can edit the code to enable more local softwares

This tool mount remote path with sshfs, so you don't need to sysynchronize manually

### Dependence

* remote: nc
* local: nc, ssh, sshfs, zsh

### How it works
* `remote_open_server.sh`: send remote  [ <hostname>, <username>, absoltue paths of file(s) or folder(s)>] to local by `nc` through ssh port forwarding

* `easy_sshfs.sh`: make sshfs easier to use
* `remote_open.sh`: according to the remote message, sshfs <username>@<hostname>:/, open the files or folders with local `open`
* `remote_open_listen.sh`: listen remote messages, and call `remote_open.sh`
* `remote_open.app`: a OSX app, call `remote_open_listen.sh`, can be set as a startup item, 

## Installation

### Arguements

<local nc port>  <remote nc port> : sugguest you to choose the which are not often used 

<local mount dir>: a local dir, under which are all sshfs mounting points

### Remote

```bash
git clone https://github.com/hyliang96/remote_open.git
cp remote_open/remote_open_server.sh ~ 
# or copy to anywhere you like
echo "[ -f ~/remote_open_server.sh ] && . ~/remote_open_server.sh" >> ~/.bashrc
# or add to .zshrc if you use it
```

edit `remote_open_server.sh`, to set <local nc port>

```bash
sever_port=<remote nc port>
```

### Local

####  Configuration

edit  `config.sh` 

```bash
mount_dir=<local mount dir>
port=<local nc port>
```

#### Edit .ssh/config

To connect remote nc and local nc, use ssh to forward the port:

~~~ssh
Host <hostname>
    HostName <remote ip or url>
    User <username>
    IdentityFile ~/.ssh/id_rsa
    PreferredAuthentications publickey
    # port forwarding for remote open
    RemoteForward <remote nc port> localhost:<local nc port>
    # other configs ...
~~~
* <hostname>=the output of `hostname` on remote
* <username>=the output of `echo $USER` on remote
* <remote ip or url>==the output of `curl ifconfig.me` on remote

#### Set as startup iterm
to run  `remote_open_listen.sh` on background when startuping local computer

##### Mac
* open  `remote_open.app` with `Automator.app`, and change the path below
~~~zsh
( ( 
zsh <absolute path to remote_open repo>/remote_open_listen.sh
) &) > /dev/null 2>&1
~~~
* `system preferences/user and group/startup items`，add `remote_open/remote_open.app`

  [for more instruction](https://www.jianshu.com/p/799e3769fb92)

* restart the computer to test if the  `remote_open_listen.sh`  is runing

  ```
  lsof -i:<local nc port>
  ```

  if it returns below,   `remote_open_listen.sh`  is runing

  ```
  COMMAND  PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
  nc      4240  mac    3u  IPv4 0xa8a6a45ca35153d5      0t0  TCP *:8304 (LISTEN)
  ```

##### Windows

set  `remote_open_listen.sh`  as startup item on your own :)



