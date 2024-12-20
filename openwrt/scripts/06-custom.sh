#!/bin/bash -e

### Add new packages or patches below
### For example, download alist from a third-party repository to package/new/alist
### Then, add CONFIG_PACKAGE_luci-app-alist=y to the end of openwrt/23-config-common-custom

# alist - add new package
git clone https://$github/sbwml/openwrt-alist package/new/alist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

rm -rf feeds/packages/net/smartdns feeds/luci/applications/luci-app-smartdns
rm -rf feeds/packages/net/adguardhome package/new/extd/luci-app-adguardhome
git clone https://$github/lonecale/openwrt-custom-packages package/new/custom-packages

dirs=(smartdns luci-app-smartdns adguardhome luci-app-adguardhome luci-app-wechatpush luci-app-chatgpt-web luci-theme-kucat luci-app-advancedplus lucky luci-app-lucky luci-app-syscontrol)

for dir in "${dirs[@]}"; do
  mv "package/new/custom-packages/$dir" "package/new/"
done

rm -rf package/new/custom-packages

# init
# 检查文件是否存在，并输出其内容
if [ -f "package/new/default-settings/default/zzz-default-settings" ]; then
    echo -e "\n${GREEN_COLOR}Starting output of zzz-default-settings:${RES}"
    cat package/new/default-settings/default/zzz-default-settings
    echo -e "${GREEN_COLOR}End of zzz-default-settings output.${RES}\n"
else
    echo -e "${RED_COLOR}File zzz-default-settings not found.${RES}"
fi

DEFAULT_SETTINGS="package/new/default-settings/default/zzz-default-settings"

# ●●●●●●●●●●●●●●●●●●●●●●●●旁路由模式●●●●●●●●●●●●●●●●●●●●●●●● #

cat >> $DEFAULT_SETTINGS <<-EOF
# 设置主机名映射 解决安卓原生TV首次连不上网的问题
uci add dhcp domain
uci set dhcp.@domain[-1].name='time.android.com'
uci set dhcp.@domain[-1].ip='203.107.6.88'
# 旁路由关闭DHCP功能
uci set dhcp.lan.ignore=1
# IPv6 路由通告服务-禁用
uci set dhcp.lan.ra=''
# DHCPv6 服务-禁用
uci set dhcp.lan.dhcpv6=''
# DHCPv6 模式-禁用
# uci set dhcp.lan.ra_management=''
# NDP代理-禁用
uci set dhcp.lan.ndp=''

uci commit dhcp

# 旁路由设置 IPv4 网关
uci set network.lan.gateway='10.0.0.2' 
# 旁路由设置 DNS(多个DNS要用空格分开)
uci set network.lan.dns='8.8.8.8'

# LAN口 委托IPv6前缀-关闭 (若用IPV6请把'0'改'1')
uci set network.lan.delegate='0'
# IPV6分配长度-禁用
uci set network.lan.ip6assign=''
# LAN口 IPv6 后缀-eui64
uci set network.lan.ip6ifaceid='eui64'

# 如果旁路由不需要IPV6的话,以下命令前面加#，默认创建一个dhcpv6接口获取主路由下发ipv6
uci set network.lan6=interface
uci set network.lan6.proto='dhcpv6'
uci set network.lan6.ifname='@lan'
uci set network.lan6.reqaddress='try'
uci set network.lan6.reqprefix='auto'
uci set network.lan6.ip6ifaceid='eui64'

# 删除默认的WAN口配置
uci delete network.wan
uci delete network.wan6

uci commit network

uci set firewall.@zone[0].network='lan lan6'
uci commit firewall

# 修复luckyarch权限
[ -e "/usr/bin/luckyarch" ] && chmod 755 /usr/bin/luckyarch
# 处理AdGuardHome核心
[ -e "/usr/bin/AdGuardHome" ] && mv /usr/bin/AdGuardHome /usr/bin/AdGuardHome_temp && mkdir /usr/bin/AdGuardHome && mv /usr/bin/AdGuardHome_temp /usr/bin/AdGuardHome/AdGuardHome && chmod 755 /usr/bin/AdGuardHome/AdGuardHome
EOF

# 修改退出命令到最后
sed -i '/exit 0/d' $DEFAULT_SETTINGS && echo "exit 0" >> $DEFAULT_SETTINGS

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

# 如果只有一个lan口 判断
# if [ $(ifconfig | grep -E "(eth|ens)" | wc -l) -eq 1 ] ; then
# fi

: <<'COMMENT'
sed -i '/# packet steering/i \
# 设置主机名映射 解决安卓原生TV首次连不上网的问题\
uci add dhcp domain\
uci set dhcp.@domain[-1].name='\''time.android.com'\''\
uci set dhcp.@domain[-1].ip='\''203.107.6.88'\''\
# 设置关闭DHCP\
uci set dhcp.lan.ignore=1\
uci commit dhcp\n\
# 设置lan 网关地址\
uci set network.lan.gateway='\''10.0.0.2'\''\
# 设置lan DNS\
uci add_list network.lan.dns='\''101.101.101.101'\''\
# 设置lan 子网掩码\
uci set network.lan.netmask='\''255.255.255.0'\''\
uci commit network\
' package/new/default-settings/default/zzz-default-settings
COMMENT

echo -e "\n${GREEN_COLOR}Starting output of modified zzz-default-settings:${RES}"
cat package/new/default-settings/default/zzz-default-settings
echo -e "${GREEN_COLOR}End of modified zzz-default-settings output.${RES}\n"

# 更改菜单位置
sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
echo -e "\n${GREEN_COLOR}Starting output of modified menu:${RES}"
cat package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
cat package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
echo -e "${GREEN_COLOR}End of modified menu.${RES}\n"

# 处理snmpd
rm -rf feeds/packages/net/net-snmp
cp -a ../master/packages/net/net-snmp feeds/packages/net/net-snmp

#!/bin/bash

# 检查目录是否存在
if [ -d "../master/packages/net/net-snmp" ]; then
    # 目录存在时，执行复制命令
    cp -a ../master/packages/utils/rrdtool1 feeds/packages/utils/rrdtool1
else
    # 目录不存在时，打印当前目录的上一级目录下的所有子目录
    echo "当前目录的上一级目录下有以下目录："
    ls -d $(dirname "$(pwd)")/*/

    # 打印 /master 下的所有目录
    echo "/master 目录下有以下目录："
    ls -d $(dirname "$(pwd)")/master/*/
    exit 1
    
fi


处理luci-app-statistics
rm -rf feeds/packages/utils/rrdtool1
cp -a ../master/packages/utils/rrdtool1 feeds/packages/utils/rrdtool1

rm -rf feeds/packages/utils/collectd
cp -a ../master/packages/utils/collectd feeds/packages/utils/collectd

rm -rf feeds/luci/applications/luci-app-statistics
cp -a ../master/luci/applications/luci-app-statistics feeds/luci/applications/luci-app-statistics
