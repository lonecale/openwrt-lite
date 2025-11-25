#!/bin/bash -e

### Add new packages or patches below
### For example, download openlist from a third-party repository to package/new/openlist
### Then, add CONFIG_PACKAGE_luci-app-openlist2=y to the end of openwrt/23-config-common-custom

# openlist - add new package
git clone https://$github/sbwml/luci-app-openlist2 package/new/openlist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# clean up feeds
# rm -rf feeds/luci/applications/{luci-app-smartdns}
# rm -rf feeds/packages/net/{adguardhome,smartdns}
rm -rf package/new/extd/{adguardhome,luci-app-adguardhome,smartdns,luci-app-smartdns,netdata,luci-app-netdata,luci-app-argon-config,oaf,open-app-filter,luci-app-oaf}
rm -rf package/new/lite/{naiveproxy}

git clone https://$github/lonecale/openwrt-custom-packages package/new/custom-packages

dirs=(smartdns adguardhome luci-app-adguardhome luci-app-smartdns luci-app-wechatpush luci-app-chatgpt-web luci-theme-kucat luci-app-kucat-config luci-app-advancedplus luci-app-netwizard luci-app-timecontrol luci-app-taskplan luci-app-watchdog lucky luci-app-lucky luci-app-syscontrol netdata-ssl luci-app-netdata luci-app-oaf naiveproxy)

for dir in "${dirs[@]}"; do
  mv "package/new/custom-packages/$dir" "package/new/"
done

rm -rf package/new/custom-packages


# 显示当前工作目录
echo -e "${GREEN_COLOR}当前工作目录是：$(pwd)${RES}"

# 显示当前目录的上一级目录下的所有目录
echo -n -e "${GREEN_COLOR}当前目录的上一级目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/*; do
    echo -n -e "${GREEN_COLOR}$(basename "$dir")${RES} "
done
echo ""  # 输出换行

# 显示 /master 目录下的所有目录
echo -n -e "${GREEN_COLOR}/master 目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/master/*; do
    echo -n -e "${GREEN_COLOR}$(basename "$dir")${RES} "
done
echo ""

# 显示 /openwrt 目录下的所有目录
echo -n -e "${GREEN_COLOR}/openwrt 目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/openwrt/*; do
    echo -n -e "${GREEN_COLOR}$(basename "$dir")${RES} "
done
echo ""

: <<'Fix_CGG14'
# ●●●●●●●●●●●●●●●●●●●●●●●●CGG14修复●●●●●●●●●●●●●●●●●●●●●●●● #
git clone https://$github/lonecale/openwrt-custom-packages package/fix_gcc14 -b gcc14 --depth 1

# base_dir="package/fix_gcc14/openwrt/packages"
base_dir="../master/packages"
target_base_dir="feeds/packages"

# 读取目录列表文件
while IFS= read -r line; do
  if [[ -n "$line" ]]; then  # 检查行是否为空
    if [[ "$line" == "net/nginx" ]]; then
      echo -e "\033[0;33mSkipping sync for $line\033[0m"
      continue  # 跳过此循环迭代
    fi
    src_dir="$base_dir/$line"
    dest_dir="$target_base_dir/$line"

    # 检查源目录是否存在
    if [[ -d "$src_dir" ]]; then
      echo -e "\033[0;32m开始同步：$src_dir 到 $dest_dir\033[0m"
      mkdir -p "$dest_dir"
      rsync -av --delete "$src_dir/" "$dest_dir/" || {
        echo -e "\033[0;31m同步失败：$src_dir 到 $dest_dir\033[0m" >&2
        continue  # 发生错误时跳过当前循环
      }
      echo -e "\033[0;32m完成同步：$src_dir 到 $dest_dir\033[0m"
    else
      echo -e "\033[0;31m源目录不存在：$src_dir\033[0m" >&2
    fi
  fi
# done < "$base_dir/directory_list.txt"
done < "package/fix_gcc14/openwrt/packages/directory_list.txt"

[ -e "../master/packages/libs/libimobiledevice-glue" ] && rm -rf package/feeds/packages/libimobiledevice-glue && cp -a ../master/packages/libs/libimobiledevice-glue package/feeds/packages/libimobiledevice-glue
[ -e "../master/packages/libs/libtatsu" ] && rm -rf package/feeds/packages/libtatsu && cp -a ../master/packages/libs/libtatsu package/feeds/packages/libtatsu
# [ -e "../master/packages/lang/luajit2" ] && rm -rf package/feeds/packages/luajit2 && cp -a ../master/packages/lang/luajit2 package/feeds/packages/luajit2

rm -rf package/fix_gcc14
# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #
Fix_CGG14

# 处理snmpd
## 检查并复制 net-snmp
# [ -e "../master/packages/net/net-snmp" ] && rm -rf feeds/packages/net/net-snmp && cp -a ../master/packages/net/net-snmp feeds/packages/net/net-snmp
# 处理luci-app-statistics
## 检查并复制 rrdtool1
# [ -e "../master/packages/utils/rrdtool1" ] && rm -rf feeds/packages/utils/rrdtool1 && cp -a ../master/packages/utils/rrdtool1 feeds/packages/utils/rrdtool1
## 检查并复制 collectd
# [ -e "../master/packages/utils/collectd" ] && rm -rf feeds/packages/utils/collectd && cp -a ../master/packages/utils/collectd feeds/packages/utils/collectd
## 检查并复制 luci-app-statistics
[ -e "../master/luci/applications/luci-app-statistics" ] && rm -rf feeds/luci/applications/luci-app-statistics && cp -a ../master/luci/applications/luci-app-statistics feeds/luci/applications/luci-app-statistics

# smartdns_WebUI处理
cfg_url="https://$mirror/openwrt/23-config-common-$cfg_ver"
echo -e "\n${BLUE_COLOR}检查 smartdns WebUI 开关，配置地址：${cfg_url}${RES}"
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-smartdns_INCLUDE_WebUI=y"; then

    echo -e "${GREEN_COLOR}检测到 CONFIG_PACKAGE_luci-app-smartdns_INCLUDE_WebUI=y，进入 rust/rust-bindgen 处理逻辑...${RES}"

	git clone https://$github/openwrt/packages package/packages-24.10 -b openwrt-24.10 --depth=1

    [ -e "package/packages-24.10/lang/node" ] && echo -e "\n${GREEN_COLOR}存在 package/packages-24.10/lang/node${RES}" ||  echo -e "\n${RED_COLOR}不存在 package/packages-24.10/lang/node${RES}"
    [ -e "package/packages-24.10/lang/node" ] && rm -rf feeds/packages/lang/node && cp -a package/packages-24.10/lang/node feeds/packages/lang/node

    [ -e "package/packages-24.10/lang/rust" ] && echo -e "\n${GREEN_COLOR}存在 package/packages-24.10/lang/rust${RES}" ||  echo -e "\n${RED_COLOR}不存在 package/packages-24.10/lang/rust${RES}"
    [ -e "package/packages-24.10/lang/rust" ] && rm -rf feeds/packages/lang/rust && cp -a package/packages-24.10/lang/rust feeds/packages/lang/rust
    [ -e "feeds/packages/lang/rust" ] && sed -i 's|TOOLCHAIN_ROOT_DIR|TOOLCHAIN_DIR|' feeds/packages/lang/rust/Makefile && sed -i '/llvm.download-ci-llvm=true/d' feeds/packages/lang/rust/Makefile
	[ -e "feeds/packages/lang/rust" ] && echo -e "${GREEN_COLOR}End of rust/Makefile output.${RES}\n" && cat feeds/packages/lang/rust/Makefile
    
    git clone https://$github/immortalwrt/packages package/immortalwrt-packages --depth 1
    
    [ -e "feeds/packages/devel/rust-bindgen" ] && echo -e "\n${GREEN_COLOR}存在 feeds/packages/devel/rust-bindgen${RES}" ||  echo -e "\n${RED_COLOR}不存在 feeds/packages/devel/rust-bindgen${RES}"
    [ -e "package/immortalwrt-packages/devel/rust-bindgen" ] && rm -rf feeds/packages/devel/rust-bindgen && cp -a package/immortalwrt-packages/devel/rust-bindgen package/new
    [ -e "package/new/rust-bindgen" ] &&  sed -i 's|include ../../lang/rust/rust-host-build.mk|include $(TOPDIR)/feeds/packages/lang/rust/rust-host-build.mk|' package/new/rust-bindgen/Makefile
    
    [ -e "feeds/packages/lang/node" ] && echo -e "\n${GREEN_COLOR}存在 feeds/packages/lang/node${RES}" ||  echo -e "\n${RED_COLOR}不存在 feeds/packages/lang/node${RES}"
    [ -e "feeds/packages/lang/rust" ] && echo -e "\n${GREEN_COLOR}存在 feeds/packages/lang/rust${RES}" ||  echo -e "\n${RED_COLOR}不存在 feeds/packages/lang/rust${RES}"
    [ -e "package/new/rust-bindgen" ] && echo -e "\n${GREEN_COLOR}存在 package/new/rust-bindgen${RES}" || echo -e "\n${RED_COLOR}不存在 package/new/rust-bindgen${RES}"

    rm -rf package/immortalwrt-packages
	rm -rf package/packages-24.10
else
    echo -e "${YELLOW_COLOR}未检测到 CONFIG_PACKAGE_luci-app-smartdns_INCLUDE_WebUI=y，跳过 rust/rust-bindgen 处理。${RES}"
fi

# 处理openssh
## 检查并复制 openssh
# [ -e "../master/packages/net/openssh" ] && rm -rf feeds/packages/net/openssh && cp -a ../master/packages/net/openssh feeds/packages/net/openssh


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
# 旁路由关闭动态 DHCP
uci set dhcp.lan.dynamicdhcp='0'
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
uci set network.lan.dns='10.0.0.2'

# LAN口 委托IPv6前缀-关闭 (若用IPV6请把'0'改'1')
uci set network.lan.delegate='0'
# IPV6分配长度-禁用
uci set network.lan.ip6assign=''
# LAN口 IPv6 后缀-eui64
uci set network.lan.ip6ifaceid='eui64'

# 如果旁路由需要IPV6的话,以下命令取消#注释，会创建一个dhcpv6接口获取主路由下发ipv6
# uci set network.lan6=interface
# uci set network.lan6.proto='dhcpv6'
# uci set network.lan6.ifname='@lan'
# uci set network.lan6.reqaddress='try'
# uci set network.lan6.reqprefix='auto'
# uci set network.lan6.ip6ifaceid='eui64'

# 删除默认的WAN口配置
uci delete network.wan
uci delete network.wan6

uci commit network

# uci set firewall.@zone[0].network='lan lan6'
# uci commit firewall

# 修复luckyarch权限
[ -e "/usr/bin/luckyarch" ] && chmod 755 /usr/bin/luckyarch
# 处理AdGuardHome核心
# [ -e "/usr/bin/AdGuardHome" ] && mv /usr/bin/AdGuardHome /usr/bin/AdGuardHome_temp && mkdir /usr/bin/AdGuardHome && mv /usr/bin/AdGuardHome_temp /usr/bin/AdGuardHome/AdGuardHome && chmod 755 /usr/bin/AdGuardHome/AdGuardHome
[ -e "/usr/bin/AdGuardHome" ] && chmod 755 /usr/bin/AdGuardHome
[ -d "/usr/share/AdGuardHome" ] && chmod -R 755 /usr/share/AdGuardHome
# 处理路由安全看门狗
[ -e "/etc/init.d/watchdog" ] && chmod 755 /etc/init.d/watchdog
[ -d "/usr/share/watchdog" ] && chmod -R 755 /usr/share/watchdog


EOF

# 更改默认主题
# echo "uci set luci.main.mediaurlbase=/luci-static/kucat" >> $DEFAULT_SETTINGS
sed -i "s|set luci.main.mediaurlbase='.*'|set luci.main.mediaurlbase='/luci-static/kucat'|" $DEFAULT_SETTINGS

# 修改退出命令到最后
sed -i '/exit 0/d' $DEFAULT_SETTINGS && echo "exit 0" >> $DEFAULT_SETTINGS

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

: <<'COMMENT'
# 如果只有一个lan口 判断
# if [ $(ifconfig | grep -E "(eth|ens)" | wc -l) -eq 1 ] ; then
# fi
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

# 修改Lan IP(不需要)
# sed -i "s/$LAN/10.0.0.1/g" package/base-files/files/bin/config_generate

# 修改默认名称为 EZwrt
sed -i "/set system.@system\[-1\].hostname=/s#OpenWrt#EZwrt#g" package/base-files/files/bin/config_generate

# 停止uhttpd监听443端口
sed -i "s@list listen_https@# list listen_https@g" package/network/services/uhttpd/files/uhttpd.config

# 强制显示2500M和全双工（默认PVE下VirtIO不识别） ImmortalWrt固件内不显示端口状态，可以关闭
sed -i '/exit 0/i\ethtool -s eth0 speed 2500 duplex full' package/base-files/files/etc/rc.local

# 更改菜单位置
echo -e "\n${GREEN_COLOR}Starting output of menu:${RES}"
cat feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json
curl -sfL https://github.com/immortalwrt/luci/raw/master/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json > feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json

[ -e "package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json" ] && sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
[ -e "package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json" ] && sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
# [ -e "package/new/extd/luci-app-eqosplus/luasrc/controller/eqosplus.lua" ] && sed -i 's/admin", "network"/admin", "control"/g' package/new/extd/luci-app-eqosplus/luasrc/controller/eqosplus.lua
[ -e "package/new/extd/luci-app-wolplus/luasrc/controller/wolplus.lua" ] && sed -i 's/admin", "services"/admin", "control"/g' package/new/extd/luci-app-wolplus/luasrc/controller/wolplus.lua
echo -e "\n${GREEN_COLOR}Starting output of modified menu:${RES}"
# cat feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json
[ -e "package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json" ] && cat package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
[ -e "package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json" ] && cat package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
# [ -e "package/new/extd/luci-app-eqosplus/luasrc/controller/eqosplus.lua" ] && cat package/new/extd/luci-app-eqosplus/luasrc/controller/eqosplus.lua
[ -e "package/new/extd/luci-app-wolplus/luasrc/controller/wolplus.lua" ] && cat package/new/extd/luci-app-wolplus/luasrc/controller/wolplus.lua
echo -e "${GREEN_COLOR}End of modified menu.${RES}\n"

# luci-app-wechatpush处理
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-wechatpush=y"; then
    curl -sfL -o package/new/luci-app-wechatpush/root/usr/share/wechatpush/api/logo.jpg https://raw.githubusercontent.com/lonecale/Groceries/main/Logo/logo.jpg
fi

# 汉化(不需要)
# curl -sfL -o package/convert_translation.sh https://github.com/kenzok8/small-package/raw/main/.github/diy/convert_translation.sh
# echo -e "${GREEN_COLOR}\ncat convert_translation.sh:${RES}"
# cat package/convert_translation.sh
# chmod +x package/convert_translation.sh && bash package/convert_translation.sh

# 更新passwall gfw规则
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-passwall=y"; then
    curl -sfL -o package/new/lite/luci-app-passwall/root/usr/share/passwall/rules/gfwlist https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt
fi

# OpenClash 核心
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-openclash=y"; then
    # 保存当前目录并切换到指定目录
    pushd package/new/lite/luci-app-openclash/root/etc/openclash
    CORE_MATE=https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v2.tar.gz
    CORE_Smart=https://raw.githubusercontent.com/vernesong/OpenClash/core/master/smart/clash-linux-amd64-v2.tar.gz
    curl -sfL -o ./Country.mmdb https://github.com/xream/geoip/releases/latest/download/ipinfo.country.mmdb
    curl -sfL -o ./GeoSite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat
    curl -sfL -o ./GeoIP.dat https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat
    mkdir ./core && cd ./core
    curl -sfL -o ./meta.tar.gz "$CORE_MATE" && tar -zxf ./meta.tar.gz && mv ./clash ./clash_meta
    chmod +x ./clash* ; rm -rf ./*.gz
    # cd .. && find . -print
    cd .. 
    sed -i 's|option geo_custom_url.*|option geo_custom_url '\''https://github.com/xream/geoip/releases/latest/download/ipinfo.country.mmdb'\''|' ../config/openclash
    sed -i 's|option geosite_custom_url.*|option geosite_custom_url '\''https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'\''|' ../config/openclash
    sed -i 's|option geoip_custom_url.*|option geoip_custom_url '\''https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'\''|' ../config/openclash
    sed -i 's|option geoasn_custom_url.*|option geoasn_custom_url '\''https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb'\''|' ../config/openclash
    sed -i 's|option chnr_custom_url.*|option chnr_custom_url '\''https://us.cooluc.com/cidr/cn_ipv4.cidr'\''|' ../config/openclash
    sed -i 's|option chnr6_custom_url.*|option chnr6_custom_url '\''https://us.cooluc.com/cidr/cn_ipv6.cidr'\''|' ../config/openclash
    # sed -i 's|option chnr_custom_url.*|option chnr_custom_url '\''https://raw.githubusercontent.com/DH-Teams/DH-Geo_AS_IP_CN/main/Geo_AS_IP_CN.txt'\''|' ../config/openclash
    # sed -i 's|option chnr6_custom_url.*|option chnr6_custom_url '\''https://raw.githubusercontent.com/DH-Teams/DH-Geo_AS_IP_CN/main/Geo_AS_IP_CN_6.txt'\''|' ../config/openclash
    # echo -e "${GREEN_COLOR}\ncat openclash:${RES}"
    # cat ../config/openclash
    # 返回原始目录
    popd
fi

# 预安装ipk
# mkdir -p files/etc/uci-defaults
# curl -sfL -o files/etc/uci-defaults/99-pre_install https://$mirror/openwrt/files/etc/uci-defaults/99-pre_install
# 创建预安装ipk存储文件夹
# mkdir -p files/etc/pre_install
# 下载安装ipk
# curl -sfL -o files/etc/pre_install/luci-app-commands_git-24.272.29284-d386ad6_all.ipk https://mirror.nju.edu.cn/immortalwrt/releases/23.05.4/packages/x86_64/luci/luci-app-commands_git-24.272.29284-d386ad6_all.ipk
# curl -sfL -o files/etc/pre_install/luci-i18n-commands-zh-cn_git-24.321.37380-2756dc1_all.ipk https://mirror.nju.edu.cn/immortalwrt/releases/23.05.4/packages/x86_64/luci/luci-i18n-commands-zh-cn_git-24.321.37380-2756dc1_all.ipk
