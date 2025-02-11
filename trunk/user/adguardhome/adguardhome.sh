#!/bin/sh

change_dns() {
if [ "$(nvram get adg_redirect)" = 1 ]; then
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#5335
EOF
/sbin/restart_dhcpd
logger -t "AdGuardHome" "添加DNS转发到5335端口"
fi
}

del_dns() {
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1#5335/d' /etc/storage/dnsmasq/dnsmasq.conf
/sbin/restart_dhcpd
}

set_iptable() {
    if [ "$(nvram get adg_redirect)" = 2 ]; then
  IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
  for IP in $IPS
  do
    iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
  done

  IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
  for IP in $IPS
  do
    ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
  done
    logger -t "AdGuardHome" "重定向53端口"
    fi
}

clear_iptable() {
  OLD_PORT="5335"
  IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
  for IP in $IPS
  do
    iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
    iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
  done

  IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
  for IP in $IPS
  do
    ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
    ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
  done

}

getconfig() {
adg_file="/etc/storage/adg.yml"
if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
  cat > "$adg_file" <<-\EEE
bind_host: 0.0.0.0
bind_port: 3030
auth_name: admin
auth_pass: admin
language: zh-cn
rlimit_nofile: 0
dns:
  bind_host: 0.0.0.0
  port: 5335
  protection_enabled: true
  filtering_enabled: true
  blocking_mode: nxdomain
  blocked_response_ttl: 10
  querylog_enabled: true
  ratelimit: 20
  ratelimit_whitelist: []
  refuse_any: true
  bootstrap_dns:
  - 119.29.29.29
  - 119.28.28.28
  - 223.5.5.5
  - 223.6.6.6
  all_servers: true
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts: []
  parental_sensitivity: 0
  parental_enabled: false
  safesearch_enabled: false
  safebrowsing_enabled: false
  cache_ttl_min: 600
  cache_ttl_max: 3600
  resolveraddress: ""
  upstream_dns:
  - tls://dns.pub
  - https://dns.pub/dns-query
  - tls://dns.alidns.com
  - https://dns.alidns.com/dns-query
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  certificate_chain: ""
  private_key: ""
filters:
- enabled: true
  url: https://anti-ad.net/easylist.txt
  name: anti-AD
  id: 1
- enabled: true
  url: https://gitlab.com/cats-team/adrules/-/raw/main/adblock_plus.txt
  name: AdRules AdBlock List Plus
  id: 2
- enabled: true
  url: https://gcore.jsdelivr.net/gh/TG-Twilight/AWAvenue-Ads-Rule@main/AWAvenue-Ads-Rule.txt
  name: AWAvenue-Ads-Rule
  id: 3
user_rules: []
dhcp:
  enabled: false
  interface_name: ""
  gateway_ip: ""
  subnet_mask: ""
  range_start: ""
  range_end: ""
  lease_duration: 86400
  icmp_timeout_msec: 1000
clients: []
log_file: ""
verbose: false
schema_version: 3

EEE
  chmod 755 "$adg_file"
fi
}

dl_adg() {
logger -t "AdGuardHome" "下载AdGuardHome"
curl -k -s -o /tmp/AdGuardHome/AdGuardHome --connect-timeout 10 --retry 3 https://ghproxy.net/https://raw.githubusercontent.com/fightroad/Padavan-KVR/main/trunk/user/adguardhome/AdGuardHome
# curl -k -s -o /tmp/AdGuardHome_linux_mipsle_softfloat.tar.gz --connect-timeout 10 --retry 3 https://gh.con.sh/https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.106.3/AdGuardHome_linux_mipsle_softfloat.tar.gz
if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ]; then
logger -t "AdGuardHome" "AdGuardHome下载失败！准备使用https://github.moeyy.xyz/从源项目加速下载。"
# curl -k -s -o /tmp/AdGuardHome/AdGuardHome --connect-timeout 10 --retry 3 https://github.moeyy.xyz/https://raw.githubusercontent.com/vb1980/Padavan-KVR/main/trunk/user/adguardhome/AdGuardHome
curl -k -s -o /tmp/AdGuardHome_linux_mipsle_softfloat.tar.gz --connect-timeout 10 --retry 3 https://github.moeyy.xyz/https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.106.3/AdGuardHome_linux_mipsle_softfloat.tar.gz
fi
if [ "/tmp/AdGuardHome_linux_mipsle_softfloat.tar.gz" ]; then
tar -zxf /tmp/AdGuardHome_linux_mipsle_softfloat.tar.gz -C /tmp/
rm -f /tmp/AdGuardHome_linux_mipsle_softfloat.tar.gz
fi
if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ]; then
logger -t "AdGuardHome" "AdGuardHome下载失败，请检查是否能正常访问github!程序将退出。"
nvram set adg_enable=0
exit 0
else
logger -t "AdGuardHome" "AdGuardHome下载成功。"
chmod +x /tmp/AdGuardHome/AdGuardHome
fi
}

start_adg() {
  mkdir -p /tmp/AdGuardHome
  mkdir -p /etc/storage/AdGuardHome
  if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ]; then
  dl_adg
  fi
  getconfig
  change_dns
  set_iptable
  logger -t "AdGuardHome" "运行AdGuardHome"
  eval "/tmp/AdGuardHome/AdGuardHome -c $adg_file -w /tmp/AdGuardHome -v" &
}

stop_adg() {
# rm -rf /tmp/AdGuardHome
killall -9 AdGuardHome
del_dns
clear_iptable
}

case $1 in
start)
  start_adg
  ;;
stop)
  stop_adg
  ;;
*)
  echo "check"
  ;;
esac
