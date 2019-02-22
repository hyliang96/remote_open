#!/bin/zsh

sever_port=8304 # 【远程nc端口】

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
        (echo "sub; $USER; `hostname`; $dirs" | nc localhost $sever_port  & )   > /dev/null
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
        (echo "open; $USER; `hostname`; $dirs" | nc localhost $sever_port & )   > /dev/null
    fi
}
