#!/bin/zsh


this_dir_abs_path=$(cd "$(dirname "$0")"; pwd)
. $this_dir_abs_path/config.sh

echo start nc
while read line; do
    echo "$line"
    zsh $this_dir_abs_path/remote_open.sh $line
done < <(nc -lk $port)
echo end nc
