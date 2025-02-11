#!/bin/sh
upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
[ -z "$upanPath" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
size=$(df -m | grep "% /etc" | awk 'NR==1' | awk -F' ' '{print $4}'| tr -d 'M' | tr -d '')
config_path="/etc/storage/tailscale"
taiapp="/tmp/tailscaled" 
tailscale="/tmp/tailscaled/tailscale"
tailscaled="/tmp/tailscaled/tailscaled"
if [ "$size" -gt 8 ] ; then 
taiapp="/etc/storage/tailscale"
tailscale="/etc/storage/tailscale/tailscale"
tailscaled="/etc/storage/tailscale/tailscaled"
fi
if [ ! -z "$upanPath" ] ; then
taiapp="$upanPath/tailscaled"
tailscale="$upanPath/tailscaled/tailscale"
tailscaled="$upanPath/tailscaled/tailscaled"
fi
[ -f "/etc/storage/bin/tailscale" ] && tailscale="/etc/storage/bin/tailscale"
[ -f "/etc/storage/bin/tailscaled" ] && tailscaled="/etc/storage/bin/tailscaled"
tag=$(curl -k --silent "https://api.github.com/repos/lmq8267/tailscale/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
[ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/tailscale/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/tailscale/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
[ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/lmq8267/tailscale/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
[ ! -s "$(which curl)" ] && tag="$( wget -T 5 -t 3 --no-check-certificate --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
[ ! -s "$(which curl)" ] && [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f96 )"
D="/etc/storage/cron/crontabs"
F="$D/`nvram get http_username`"
tailscale_dl () {
if [ -z "$upanPath" ] ; then
Available_A=$(df -m | grep "% /tmp" | awk 'NR==1' | awk -F' ' '{print $4}'| tr -d 'M' | tr -d '' | cut -f1 -d".")
Available_B=$(df -m | grep "% /tmp" | awk 'NR==1' | awk -F' ' '{print $2}'| tr -d 'M' | tr -d '' | cut -f1 -d".")
Available_B=`expr $Available_B + 20`
if [ "$size" -gt 9 ] ; then  
logger -t "【Tailscale】" "未挂载储存设备,内部/etc/storage容量剩余$size M，程序约9M将安装在$taiapp"   
else
[ "$Available_A" -lt 8 ] && logger -t "【Tailscale】" "未挂载储存设备,内存/tmp容量剩余$Available_A M，内部/etc/storage容量剩余$size M，不足9M，临时增加内存/tmp容量为$Available_B M" && mount -t tmpfs -o remount,rw,size="$Available_B"M tmpfs /tmp && Available_A=$(df -m | grep "% /tmp" | awk 'NR==1' | awk -F' ' '{print $4}'| tr -d 'M' | tr -d '')
logger -t "【Tailscale】" "未挂载储存设备,内存/tmp容量剩余$Available_A M，程序约9M将安装在$taiapp"
fi
fi
logger -t "【Tailscale】" "文件较大，若是反复下载失败，手动从 https://github.com/lmq8267/tailscale/releases 下载程序上传至$tailscale和$tailscaled"
[ ! -d "$taiapp" ] && mkdir -p "$taiapp"
[ ! -f "$tailscaled" ] && rm -rf $tailscale
[ ! -f "$tailscale" ] && rm -rf $tailscaled
down=1
  while [ ! -s "$tailscaled" ] || [ ! -s "$tailscale" ] ; do
    down=`expr $down + 1`
    rm -rf $tailscaled $tailscale
    if [ ! -z "$tag" ]; then
     logger -t "【Tailscale】" "获取到最新版本tailscale_v$tag,开始下载..."
     rm -rf /tmp/var/tailscale.txt
     rm -rf /tmp/var/tailscaled.txt
     curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscale.txt" ||  curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscale.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscale.txt https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscale.txt || wget --no-check-certificate -O /tmp/var/tailscale.txt https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscale.txt ) 
     curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscale" || curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscale"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscale" "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscale" || wget --no-check-certificate -O "$tailscale" "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscale" )
     curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscaled.txt" || curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscaled.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscaled.txt https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscaled.txt || wget --no-check-certificate -O /tmp/var/tailscaled.txt https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscaled.txt )
     curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscaled" || curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscaled" 
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscaled" "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/$tag/tailscaled" || wget --no-check-certificate -O "$tailscaled" "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/$tag/tailscaled" )
   else
     logger -t "【Tailscale】" "无法从GitHub获取到最新版本,开始下载备用版本tailscale_v1.46.1"
     rm -rf /tmp/var/tailscale.txt
     rm -rf /tmp/var/tailscaled.txt
     curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscale.txt" ||  curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscale.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscale.txt https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscale.txt || wget --no-check-certificate -O /tmp/var/tailscale.txt https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscale.txt ) 
     curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscale" || curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscale"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscale" "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscale" || wget --no-check-certificate -O "$tailscale" "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscale" )
     curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscaled.txt" || curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscaled.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscaled.txt https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscaled.txt || wget --no-check-certificate -O /tmp/var/tailscaled.txt https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscaled.txt )
     curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscaled" || curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscaled" 
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscaled" "https://fastly.jsdelivr.net/gh/lmq8267/tailscale@master/install/1.46.1/tailscaled" || wget --no-check-certificate -O "$tailscaled" "https://hub.gitmirror.com/https://raw.githubusercontent.com/lmq8267/tailscale/main/install/1.46.1/tailscaled" )
    fi
    [ -s /tmp/var/tailscale.txt ]&& tailscaleMD5="$(cat /tmp/var/tailscale.txt)"
    [ -s /tmp/var/tailscaled.txt ] && tailscaledMD5="$(cat /tmp/var/tailscaled.txt)"
    [ -s "$tailscale" ] && eval $(md5sum "$tailscale" | awk '{print "MD5_down="$1;}') && echo "$MD5_down"
    [ -s "$tailscaled" ] && eval $(md5sum "$tailscaled" | awk '{print "dMD5_down="$1;}') && echo "$dMD5_down"
    if [ -n "$MD5_down" ] && [ -n "$dMD5_down" ] && [ -n "$tailscaleMD5" ] && [ -n "$tailscaledMD5" ] ; then
        if [ "$MD5_down"x = "$tailscaleMD5"x ] && [ "$dMD5_down"x = "$tailscaledMD5"x ] ; then
           logger -t "【Tailscale】" "程序下载完成，MD5匹配，开始安装..."
        else
           logger -t "【Tailscale】" "程序下载不完整，MD5不匹配，删除重新下载..." 
           rm -rf /tmp/var/tailscale.txt
           rm -rf /tmp/var/tailscaled.txt
           rm -rf $tailscaled $tailscale
        fi
     fi
   if [ ! -s "$tailscaled" ] || [ ! -s "$tailscale" ] ; then
      logger -t "【Tailscale】" "开始从备用地址下载"
      if [ ! -z "$tag" ]; then
     rm -rf /tmp/var/tailscale.txt
     rm -rf /tmp/var/tailscaled.txt
     curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale.txt" || curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscale.txt https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale.txt || wget --no-check-certificate -O /tmp/var/tailscale.txt https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale.txt )
     curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale" || curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscale" "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale" || wget --no-check-certificate -O "$tailscale" "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscale" )
     curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled.txt" || curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscaled.txt https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled.txt || wget --no-check-certificate -O /tmp/var/tailscaled.txt https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled.txt )
     curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled" || curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled" 
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscaled" "https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled" || wget --no-check-certificate -O "$tailscaled" "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/$tag/tailscaled" )
   else
     rm -rf /tmp/var/tailscale.txt
     rm -rf /tmp/var/tailscaled.txt
     curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale.txt" || curl -L -k -S -o "/tmp/var/tailscale.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscale.txt https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale.txt || wget --no-check-certificate -O /tmp/var/tailscale.txt https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale.txt )
     curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale" || curl -L -k -S -o "$tailscale" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscale" "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale" || wget --no-check-certificate -O "$tailscale" "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscale" )
     curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled.txt" || curl -L -k -S -o "/tmp/var/tailscaled.txt" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled.txt"
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O /tmp/var/tailscaled.txt https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled.txt || wget --no-check-certificate -O /tmp/var/tailscaled.txt https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled.txt )
     curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled" || curl -L -k -S -o "$tailscaled" --connect-timeout 10 --retry 3 "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled" 
     [ ! -s "$(which curl)" ] && ( wget --no-check-certificate -O "$tailscaled" "https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled" || wget --no-check-certificate -O "$tailscaled" "https://hub.gitmirror.com/https://github.com/lmq8267/tailscale/releases/download/1.46.1/tailscaled" )
    fi
    [ -s /tmp/var/tailscale.txt ]&& tailscaleMD51="$(cat /tmp/var/tailscale.txt)"
    [ -s /tmp/var/tailscaled.txt ] && tailscaledMD52="$(cat /tmp/var/tailscaled.txt)"
    [ -s "$tailscale" ] && eval $(md5sum "$tailscale" | awk '{print "MD5_down1="$1;}') && echo "$MD5_down1"
    [ -s "$tailscaled" ] && eval $(md5sum "$tailscaled" | awk '{print "dMD5_down2="$1;}') && echo "$dMD5_down2"
    if [ -n "$MD5_down1" ] && [ -n "$dMD5_down2" ] && [ -n "$tailscaleMD51" ] && [ -n "$tailscaledMD52" ] ; then
        if [ "$MD5_down1"x = "$tailscaleMD51"x ] && [ "$dMD5_down2"x = "$tailscaledMD52"x ] ; then
           logger -t "【Tailscale】" "备用程序下载完成，MD5匹配，开始安装..."
        else
           logger -t "【Tailscale】" "备用程序下载不完整，MD5不匹配，删除重新下载..." 
           rm -rf /tmp/var/tailscale.txt
           rm -rf /tmp/var/tailscaled.txt
           rm -rf $tailscaled $tailscale
        fi
     fi
    fi
    [ "$down" -gt "5" ] && logger -t "【Tailscale】" "程序多次下载失败，将于5分钟后再次尝试下载..." && sleep 300 && down=1
    done
    [ ! -f "$tailscale" ] && logger -t "【Tailscale】" "tailscale安装失败，重新下载..." && tailscale_start 
    [ ! -f "$tailscaled" ] && logger -t "【Tailscale】" "tailscaled安装失败，重新下载..." && tailscale_start
    [ -f "$tailscale" ] && chmod 777 "$tailscale"
    [ -f "$tailscaled" ] && chmod 777 "$tailscaled"    
    
}

tailscale_start () {
     sed -Ei '/tailscale守护进程|^$/d' "$F"
     [ ! -d $config_path ] && mkdir -p $config_path
     [ ! -d $taiapp ] && mkdir -p $taiapp
     [ -f "/etc/storage/tailscale/tailscale" ] && tailscale="/etc/storage/tailscale/tailscale"
     [ -f "/etc/storage/tailscale/tailscaled" ] && tailscaled="/etc/storage/tailscale/tailscaled"
     [ -f "$upanPath/tailscaled/tailscale" ] && tailscale="$upanPath/tailscaled/tailscale"
     [ -f "$upanPath/tailscaled/tailscaled" ] && tailscaled="$upanPath/tailscaled/tailscaled"
     [ ! -f $tailscaled ] && tailscale_dl
     [ ! -f $tailscale ] && tailscale_dl
     [ -f $tailscale ] && chmod 777 $tailscale
     [ -f $tailscaled ] && chmod 777 $tailscaled
     taiver=$($tailscaled -version | sed -n '1p')
     echo "$tag"
     echo "$taiver"
     [ -z "$taiver" ] && logger -t "【Tailscale】" "程序不完整，重新下载..." && rm -rf $tailscaled $tailscale && tailscale_dl
     if [ ! -z "$tag" ] && [ ! -z "$taiver" ] ; then
        if [ "$tag"x != "$taiver"x ] ; then
           logger -t "【Tailscale】" "已发布最新版本tailscale_v$tag,当前安装版本tailscale_v$taiver,开始更新，删除tailscaled"
	   rm -rf "$tailscaled" "$tailscale"
           tailscale_dl
	   else
           logger -t "【Tailscale】" "当前安装版本tailscale_v$taiver,准备启动"
	fi
     fi
     [ -L /etc/storage/tailscale/tailscale ] && rm -rf /etc/storage/tailscale/tailscale
     rm -rf /var/lib/tailscale
     rm -rf /home/root/.ssh/tailscale
     [ ! -e "/tmp/var/cmd.log1.txt" ] && touch /tmp/var/cmd.log1.txt
     [ ! -e "/tmp/var/cmd.log2.txt" ] && touch /tmp/var/cmd.log2.txt
     rm -rf /etc/storage/tailscale/lib/cmd.log2.txt && ln -sf /tmp/var/cmd.log1.txt /etc/storage/tailscale/lib/cmd.log1.txt && chmod 600 /tmp/var/cmd.log1.txt
     rm -rf /etc/storage/tailscale/lib/cmd.log2.txt && ln -sf /tmp/var/cmd.log2.txt /etc/storage/tailscale/lib/cmd.log2.txt && chmod 600 /tmp/var/cmd.log2.txt
     ln -sf $config_path /var/lib/tailscale
     ln -sf $config_path /home/root/.ssh/tailscale
     $tailscaled --cleanup
     killall tailscaled tailscale
     killall -9 tailscaled tailscale
     su_cmd2="$tailscaled --state=/etc/storage/tailscale/lib/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock"
     eval "$su_cmd2" &
     sleep 5
     [ ! -z "`pidof tailscaled`" ] && logger -t "【Tailscale】" "tailscaled主程序启动成功" 
     [ -z "`pidof tailscaled`" ] && logger -t "【Tailscale】" "tailscaled主程序启动失败,注意检查tailscale是否下载完整, 20 秒后自动尝试重新启动" && sleep 20 && tailscale_restart
     iptables -C INPUT -i tailscale0 -j ACCEPT
     if [ "$?" != 0 ] ; then
       iptables -I INPUT -i tailscale0 -j ACCEPT
     fi
     taiarp=$(ifconfig tailscale0 | grep NOARP | awk '{print }')
     [ -n "$taiarp" ] && ifconfig tailscale0 arp && logger -t "【Tailscale】" "检测到接口已禁用arp地址解析协议,正在开启arp!"
     subnet=`nvram get lan_ipaddr`
     subnet1=`echo $subnet |cut -d. -f1`
     subnet2=`echo $subnet |cut -d. -f2`
     subnet3=`echo $subnet |cut -d. -f3`
     subnet="${subnet1}.${subnet2}.${subnet3}.0/24"
     su_cmd="$tailscale up --accept-dns=false --accept-routes --advertise-routes=${subnet} --advertise-exit-node --reset"
     logger -t "【Tailscale】" "启用子网路由$su_cmd"
     eval "$su_cmd" &
     sleep 5
     $tailscale web --listen `nvram get lan_ipaddr`:8989 &
     logger -t "【Tailscale】" "启用WEB管理页面 $tailscale web --listen `nvram get lan_ipaddr`:8989 "
     [ ! -z "`pidof tailscale`" ] && logger -t "【Tailscale】" "tailscale_WEB管理页面:`nvram get lan_ipaddr`:8989"
     [ -z "`pidof tailscale`" ] && logger -t "【Tailscale】" "tailscale_WEB管理页面启动失败, 注意检查tailscale是否下载完整,20 秒后自动尝试重新启动" && sleep 20 && tailscale_restart
     taip=`$tailscale ip`
     [ -n "$taip" ] && logger -t "【Tailscale】" "tailscale_IP:$taip"
     tailscale_keep
     exit 0
}  


tailscale_keep () {
logger -t "【Tailscale】" "守护进程启动"
sed -Ei '/tailscale守护进程|^$/d' "$F"
cat >> "$F" <<-OSC
*/1 * * * * test -z "\`pidof tailscaled\`"  && /etc/storage/tailscale.sh restart #tailscale守护进程
OSC
offweb=1
     while [ ! -z "`pidof tailscaled`" ] || [ ! -z "`pidof tailscale`" ] ; do
     iptables -C INPUT -i tailscale0 -j ACCEPT
     if [ "$?" != 0 ] ; then
	iptables -I INPUT -i tailscale0 -j ACCEPT
     fi
     sleep 100
     if [ ! -z "`pidof tailscale`" ] ; then
        if [ "$offweb" -gt "3" ] ; then
           offweb=1
           killall tailscale
	   sleep 5
           [ -z "`pidof tailscale`" ] && logger -t "【Tailscale】" "tailscale_WEB管理页面 (自动关闭)"
        fi
     offweb=`expr $offweb + 1`
     fi
     done
}

tailscale_restart () {
  logger -t "【Tailscale】" "重新启动"
  tailscale_start
  
}

tailscale_check () {
  tailscale_start

}

tailscale_close () {
  iptables -D INPUT -i tailscale0 -j ACCEPT
  sed -Ei '/tailscale守护进程|^$/d' "$F"
  $tailscaled --cleanup
  killall tailscaled tailscale
  killall -9 tailscaled tailscale
  [ -L /etc/storage/tailscale/tailscale ] && rm -rf /etc/storage/tailscale/tailscale
  rm -rf /etc/storage/tailscale/lib/cmd.log1.txt
  rm -rf /etc/storage/tailscale/lib/cmd.log2.txt
  sleep 8
  [ -z "`pidof tailscaled`" ] && [ -z "`pidof tailscale`" ] && logger -t "【Tailscale】" "tailscale已关闭!"
}

case $1 in
start)
	tailscale_start
	;;
restart)
	tailscale_restart
	;;
stop)
	tailscale_close
	;;
*)
	tailscale_check
	;;
esac

