#!/bin/bash -e

### Add new packages or patches below
### For example, download alist from a third-party repository to package/new/alist
### Then, add CONFIG_PACKAGE_luci-app-alist=y to the end of openwrt/23-config-common-custom

# alist - add new package
git clone https://$github/sbwml/openwrt-alist package/new/alist

# lrzsz - add patched package
rm -rf feeds/packages/utils/lrzsz
git clone https://$github/sbwml/packages_utils_lrzsz package/new/lrzsz

# clean up feeds
rm -rf feeds/luci/applications/{luci-app-smartdns}
rm -rf feeds/packages/net/{adguardhome,smartdns}
rm -rf package/new/extd/{adguardhome,luci-app-adguardhome,smartdns,luci-app-smartdns,netdata,luci-app-netdata,luci-app-argon-config,oaf,open-app-filter,luci-app-oaf}

git clone https://$github/lonecale/openwrt-custom-packages package/new/custom-packages

dirs=(openwrt smartdns adguardhome luci-app-adguardhome luci-app-smartdns luci-app-wechatpush luci-app-chatgpt-web luci-theme-kucat luci-app-advancedplus luci-app-netwizard lucky luci-app-lucky luci-app-syscontrol netdata-ssl luci-app-netdata luci-app-oaf)

for dir in "${dirs[@]}"; do
  mv "package/new/custom-packages/$dir" "package/new/"
done

rm -rf package/new/custom-packages


# 显示当前工作目录
echo -e "${GREEN_COLOR}当前工作目录是：$(pwd)${RES}"

# 显示当前目录的上一级目录下的所有目录
echo -e "${GREEN_COLOR}当前目录的上一级目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/*; do
    echo -e "${GREEN_COLOR}$(basename "$dir")${RES}"
done

# 显示 /master 目录下的所有目录
echo -e "${GREEN_COLOR}/master 目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/master/*; do
    echo -e "${GREEN_COLOR}$(basename "$dir")${RES}"
done

# 显示 /openwrt 目录下的所有目录
echo -e "${GREEN_COLOR}/openwrt 目录下有以下目录：${RES}"
for dir in $(dirname "$(pwd)")/openwrt/*; do
    echo -e "${GREEN_COLOR}$(basename "$dir")${RES}"
done

# ●●●●●●●●●●●●●●●●●●●●●●●●CGG14修复●●●●●●●●●●●●●●●●●●●●●●●● #
# 源目录和目标目录
src_dir="package/new/openwrt/packages"
dest_dir="feeds/packages"

############### 调试用
# 打印源目录 package/new/openwrt/packages/lang/perl/patches 中的文件和目录
echo "第一次查看源目录 $src_dir/lang/perl/patches 内容："
ls -l "$src_dir/lang/perl/patches"

# 打印目标目录 feeds/packages/lang/perl/patches 中的文件和目录
echo "第一次查看目标目录 $dest_dir/lang/perl/patches 内容："
ls -l "$dest_dir/lang/perl/patches"
############### 调试用

# 从源目录复制文件到目标目录
echo "复制文件从 $src_dir 到 $dest_dir"
cp -r "$src_dir/"* "$dest_dir/"

############### 调试用
# 打印目标目录 feeds/packages/lang/perl/patches 中的文件和目录
echo "第二次查看目标目录 $dest_dir/lang/perl/patches 内容："
ls -l "$dest_dir/lang/perl/patches"
############### 调试用
echo "查看目标目录 $dest_dir/lang 内容："
ls -l "$dest_dir/lang"

# 检查某个目录在源路径中是否存在
check_dir_exists() {
    local dir_path="$1"
    if [ -d "$dir_path" ]; then
        return 0  # 目录存在
    else
        return 1  # 目录不存在
    fi
}

# 遍历源目录中的所有文件和目录
find "$src_dir" -type d | while read src_subdir; do
    # 跳过源目录本身
    if [[ "$src_subdir" == "$src_dir" ]]; then
        continue
    fi
    
    # 去掉路径中的 $src_dir 部分，得到相对路径
    src_subdir_rel=$(echo "$src_subdir" | sed "s|^$src_dir/||")
    dest_subdir="$dest_dir/$src_subdir_rel"  # 构造目标目录对应的路径
    echo "检查源子目录: $src_subdir_rel 对应目标子目录: $dest_subdir"

    # 如果目标子目录是 .git 目录，跳过
    if [[ "$dest_subdir" == *".git"* ]]; then
        echo "跳过 .git 目录或文件: $dest_subdir"
        continue
    fi

    # 如果目标子目录存在
    if [ -d "$dest_subdir" ]; then
        echo "目标子目录存在: $dest_subdir"

        # 判断目标路径中的文件夹是否在源路径中存在
        if check_dir_exists "$src_dir/$src_subdir_rel"; then
            echo "源路径存在: $src_dir/$src_subdir_rel"

            # 遍历目标目录下的每一个文件/目录
            find "$dest_subdir" -mindepth 1 | while read dest_item; do
                # 去掉目标路径的前缀部分，得到相对路径
                dest_item_rel=$(echo "$dest_item" | sed "s|^$dest_subdir/||")
                src_item="$src_dir/$dest_item_rel"  # 直接使用源目录和目标的相对路径

                echo "源路径: $src_item, 目标路径: $dest_item"
                
                # 判断源路径中的文件是否存在
                if [ -e "$src_item" ]; then
                    echo "源路径存在: $src_item"
                else
                    echo "源路径不存在: $src_item"
                fi
                
                # 目标路径中的文件/目录如果不在源路径中，则删除
                if [ ! -e "$src_item" ]; then
                    echo "删除目标路径中的文件/目录: $dest_item"
                    rm -rf "$dest_item"
                fi
            done
        else
            echo "源路径不存在: $src_dir/$src_subdir_rel"
            # 如果目标子目录存在而源路径中没有相应的目录，则不做删除
        fi
    else
        echo "目标子目录不存在: $dest_subdir"
    fi
done
############### 调试用
# 打印目标目录 feeds/packages/lang/perl/patches 中的文件和目录
echo "第三次查看目标目录 $dest_dir/lang/perl/patches 内容："
ls -l "$dest_dir/lang/perl/patches"
############### 调试用


[ -e "../master/packages/libs/libimobiledevice-glue" ] && rm -rf package/feeds/packages/libimobiledevice-glue && cp -a ../master/packages/libs/libimobiledevice-glue package/feeds/packages/libimobiledevice-glue
[ -e "../master/packages/libs/libtatsu" ] && rm -rf package/feeds/packages/libtatsu && cp -a ../master/packages/libs/libtatsu package/feeds/packages/libtatsu
[ -e "../master/packages/lang/luajit2" ] && rm -rf package/feeds/packages/luajit2 && cp -a ../master/packages/lang/luajit2 package/feeds/packages/luajit2


# find package/new/openwrt/packages -type d | while read dir; do
  # 如果当前目录没有子目录（即为低级目录），则进行同步
  #if [ $(find "$dir" -mindepth 1 -type d | wc -l) -eq 0 ]; then
    # 使用 sed 替换源路径为目标路径
    #target_dir=$(echo "$dir" | sed 's|^package/new/openwrt/packages|feeds/packages|')
    #echo -e "\n${GREEN_COLOR}dir:${RES}"
    #echo "$dir/" 
    #echo -e "\n${GREEN_COLOR}target_dir:${RES}"
    #echo "$target_dir/" 
    # 执行 rsync 同步
    #rsync -av --delete "$dir/" "$target_dir/"
  #fi
#done

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

# 处理snmpd
## 检查并复制 net-snmp
# [ -e "../master/packages/net/net-snmp" ] && rm -rf feeds/packages/net/net-snmp && cp -a ../master/packages/net/net-snmp feeds/packages/net/net-snmp

# 处理luci-app-statistics
## 检查并复制 rrdtool1
# [ -e "../master/packages/utils/rrdtool1" ] && rm -rf feeds/packages/utils/rrdtool1 && cp -a ../master/packages/utils/rrdtool1 feeds/packages/utils/rrdtool1
## 检查并复制 collectd
# [ -e "../master/packages/utils/collectd" ] && rm -rf feeds/packages/utils/collectd && cp -a ../master/packages/utils/collectd feeds/packages/utils/collectd
## 检查并复制 luci-app-statistics
# [ -e "../master/luci/applications/luci-app-statistics" ] && rm -rf feeds/luci/applications/luci-app-statistics && cp -a ../master/luci/applications/luci-app-statistics feeds/luci/applications/luci-app-statistics

# 处理openssh
## 检查并复制 openssh
# [ -e "../master/packages/net/openssh" ] && rm -rf feeds/packages/net/openssh && cp -a ../master/packages/net/openssh feeds/packages/net/openssh


# init
# 修改Lan IP
# sed -i "s/$LAN/10.0.0.1/g" package/base-files/files/bin/config_generate

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
[ -e "/usr/bin/AdGuardHome" ] && mv /usr/bin/AdGuardHome /usr/bin/AdGuardHome_temp && mkdir /usr/bin/AdGuardHome && mv /usr/bin/AdGuardHome_temp /usr/bin/AdGuardHome/AdGuardHome && chmod 755 /usr/bin/AdGuardHome/AdGuardHome
[ -e "/usr/share/AdGuardHome/addhost.sh" ] && chmod 755 /usr/share/AdGuardHome/addhost.sh

EOF

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

# 更改默认主题
echo -e "${GREEN_COLOR}\ncat feeds/luci/collections/luci/Makefile:${RES}"
cat feeds/luci/collections/luci/Makefile
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 更改菜单位置
echo -e "\n${GREEN_COLOR}Starting output of menu:${RES}"
cat feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json
curl -sfL https://github.com/immortalwrt/luci/raw/master/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json > feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json

[ -e "package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json" ] && sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
[ -e "package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json" ] && sed -i 's/admin\/services\//admin\/vpn\//g' package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
echo -e "\n${GREEN_COLOR}Starting output of modified menu:${RES}"
# cat feeds/luci/modules/luci-base/root/usr/share/luci/menu.d/luci-base.json
[ -e "package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json" ] && cat package/new/extd/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
[ -e "package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json" ] && cat package/new/extd/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json
echo -e "${GREEN_COLOR}End of modified menu.${RES}\n"

# luci-app-wechatpush处理
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-wechatpush=y"; then
    curl -sfL -o package/new/luci-app-wechatpush/root/usr/share/wechatpush/api/logo.jpg https://raw.githubusercontent.com/lonecale/Groceries/main/Logo/logo.jpg
fi

# 汉化
# curl -sfL -o package/convert_translation.sh https://github.com/kenzok8/small-package/raw/main/.github/diy/convert_translation.sh
# echo -e "${GREEN_COLOR}\ncat convert_translation.sh:${RES}"
# cat package/convert_translation.sh
# chmod +x package/convert_translation.sh && bash package/convert_translation.sh

# 更新passwall gfw规则
# if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-passwall=y"; then
    # curl -sfL -o package/new/lite/luci-app-passwall/root/usr/share/passwall/rules/gfwlist https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt
# fi

# OpenClash 核心
if curl -s "https://$mirror/openwrt/23-config-common-$cfg_ver" | grep -q "^CONFIG_PACKAGE_luci-app-openclash=y"; then
    # 保存当前目录并切换到指定目录
    pushd package/new/lite/luci-app-openclash/root/etc/openclash
    CORE_MATE=https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz
    curl -sfL -o ./Country.mmdb https://github.com/xream/geoip/releases/latest/download/ipinfo.country.mmdb
    curl -sfL -o ./GeoSite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat
    curl -sfL -o ./GeoIP.dat https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat
    mkdir ./core && cd ./core
    curl -sfL -o ./meta.tar.gz "$CORE_MATE" && tar -zxf ./meta.tar.gz && mv ./clash ./clash_meta
    chmod +x ./clash* ; rm -rf ./*.gz
    cd .. && find . -print
    sed -i 's|option geo_custom_url.*|option geo_custom_url '\''https://github.com/xream/geoip/releases/latest/download/ipinfo.country.mmdb'\''|' ../config/openclash
    sed -i 's|option geosite_custom_url.*|option geosite_custom_url '\''https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat'\''|' ../config/openclash
    sed -i 's|option geoip_custom_url.*|option geoip_custom_url '\''https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat'\''|' ../config/openclash
    sed -i 's|option chnr_custom_url.*|option chnr_custom_url '\''https://raw.githubusercontent.com/DH-Teams/DH-Geo_AS_IP_CN/main/Geo_AS_IP_CN.txt'\''|' ../config/openclash
    sed -i 's|option chnr6_custom_url.*|option chnr6_custom_url '\''https://raw.githubusercontent.com/DH-Teams/DH-Geo_AS_IP_CN/main/Geo_AS_IP_CN_6.txt'\''|' ../config/openclash
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
