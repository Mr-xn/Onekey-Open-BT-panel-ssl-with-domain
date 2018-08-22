#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


echo "#================================================================="
echo "# System Required: CentOS 6+/Debian 6+/Ubuntu 14.04+"
echo "# Description: 一键开启宝塔面板自定义域名SSL登录(浏览器信任的小绿锁)"
echo "# Author:Mrxn"
echo "# 注意：此脚本仅适合宝塔面板，且没有自己修改过宝塔的系统文件！"
echo "# Date:08/20/2018"
echo "# Blog:https://mrxn.net"
echo "#================================================================="

#颜色设置
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"


#检查系统
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    #bit=$(uname -m)
}

#文件定义
panel_data="/www/server/panel/data/"
domain_file="/www/server/panel/data/domain.conf"
sslpl_file="/www/server/panel/data/ssl.pl"
limitip_file="/www/server/panel/data/limitip.conf"
port_file="/www/server/panel/data/port.pl"
port=`cat ${port_file}`
ssl_path="/www/server/panel/ssl"
ssl_old_prikey=${ssl_path}"/privateKey.pem"
ssl_old_fullchain=${ssl_path}"/certificate.pem"
domain=`cat ${domain_file}`
new_panel_adr="https://"${domain}":"${port}"/login"
domain_ssl="/etc/letsencrypt/live/"${domain}
lets_privkey="/etc/letsencrypt/live/"${domain}"/privkey.pem"
lets_fullchain="/etc/letsencrypt/live/"${domain}"/fullchain.pem"

#root权限判断
check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${Error} 请用root权限执行此脚本！" && exit 1
}
#检查面板SSL状态
check_panelssl_status(){
    panel_status
	if [[ ! -e ${domain_file} && ! -e ${sslpl_file} ]]; then
        echo
		echo -e "${Info} 没有检测到面板域名&SSL相关配置文件..."
	elif [[ -e ${domain_file} ]]; then
        echo
		echo -e "${Info} 检测到面板域名相关配置文件，检测绑定域名..."
        echo -e "${Info} 检测到绑定的域名: ${Green_font_prefix}${domain}${Font_color_suffix}"
		echo -e "${Info} 正在检测是否已经开启了面板SSL..."
    fi
	if [[ -e ${sslpl_file} ]]; then
        echo
        echo -e "${Info} 你已经开启了面板SSL!退出程序..." && exit 1
    else
        echo "${Info} 其他未知错误" 
    fi
}
#备份系统自带的面板SSL证书和密钥
backup_old_sys_key(){
    echo
    echo -e "${Info} 备份系统的面板SSL证书和密钥..."
    if [[ -e ${ssl_old_prikey} && ${ssl_old_fullchain} ]]; then
        mv "${ssl_old_prikey}" "${ssl_old_prikey}.bak" && mv "${ssl_old_fullchain}" "${ssl_old_fullchain}.bak"
        echo -e "${Info} 备份成功!"
    else
        echo -e "${Info} 备份失败,请检查系统ssl目录是否存在证书和密钥文件"
    fi
}
#检查openssl状态
openssl_check(){
    openssl version
    if [ $? -eq 0 ]; then
        version=`openssl version | awk '{print $2 }'`
        echo -e "${Info} 已经安装openssl版本:${version}" && exit 1
    elif [[ ${release} = "centos" ]]; then
        echo -e "${Info} 安装openssl中..."
        yum install openssl -y
    elif [[ ${release} = "debian" || ${release} = "ubuntu" ]]; then
        echo -e "${Info} 安装openssl中..."
        apt install openssl -y
    else
        echo -e "${Info} 安装openssl失败,请手动安装!"
    fi
}
#安装面板SSL证书和密钥
check_domain_install_ssl(){
    check_panelssl_status
    if [[ ! -d ${domain_ssl} ]]; then
        echo
        echo -e "${Info} 没有找到面板绑定的域名Lets-SSL证书,请检查域名证书!"
    elif [[ -d ${domain_ssl} ]]; then
        echo -e "${Info} 发现面板绑定的域名Lets-SSL证书：${Green_font_prefix}${domain_ssl}${Font_color_suffix}"
        stty erase '^H' && read -p "域名证书路径是否正确？[Y/N]" yn
        [[ -z "${yn}" ]] && yn="y"
        if [[ $yn == [Yy] || $yn == "" ]]; then
            backup_old_sys_key
            cd ${ssl_path} && ln -s lets_privkey privateKey.pem && ln -s lets_fullchain certificate.pem
            /etc/init.d/bt restart
            if [ $? -eq 0 ]; then
                echo -e "${Info} 宝塔面板重启成功！"
            else    
                echo -e "${Info} 宝塔面板启动失败,请手动重启:/etc/init.d/bt restart！"
            fi
            installed_check
            panel_status
        else
            exit 1
        fi
    else
        echo
        echo -e "${Info} 使用自定义SSL证书?"
        echo -e "${Tip} 注意：自定义的证书格式有可能不是.pem结尾的,比如.crt和.key结尾的"
        echo -e "${Tip} shell会调用系统openssl转换格式.系统一般都有安装openssl,如果没有shell会自动安装"
        openssl_check
        stty erase '^H' && read -p "请输入自定义证书的key文件完整路径[比如：/home/www/ssl/mysite.com.key(.crt)]:" own_key
        if ( ${own_key} ! == "" && -e ${own_key} ) && ( "${own_key##*.}" = "key" ); then
            echo -e "${Info} 检测到证书格式:${Green_font_prefix}${own_key##*.}${Font_color_suffix}"
            echo -e "${Info} 你的key文件路径:${Green_font_prefix}${own_key}${Font_color_suffix}"
            echo -e "${Info} 格式转换中..."
            ownkey_path=${own_key%/*}
            openssl rsa -in own_key -out ${ownkey_path}/privateKey.pem
            changed_keypath=${ownkey_path}/privateKey.pem
            if [[ -e ${changed_path} ]]; then
                echo -e "${Info} key转换完成pem后的地址:${Green_font_prefix}${changed_keypath}${Font_color_suffix}"
            else
                echo -e "${Info} 转换失败，请手动转换后再运行此shell" && exit 1
             fi
        elif ( ${own_key} !== "" && -e ${own_key} ) && ( "${own_key##*.}" = "crt" ); then
            echo -e "${Info} 检测到证书格式:${Green_font_prefix}${own_key##*.}${Font_color_suffix}"
            echo -e "${Info} 你的crt文件路径:${Green_font_prefix}${own_key}${Font_color_suffix}"
            echo -e "${Info} 格式转换中..."
            owncrt_path=${own_key&/*}
            openssl x509 -in own_key -out ${owncrt_path}/certificate.pem
            changed_crtpath=${owncrt_path}/certificate
            if [[ -e ${changed_path} ]]; then
                echo -e "${Info} crt转换完成pem后的地址:${Green_font_prefix}${changed_crtpath}${Font_color_suffix}"
            else
                echo -e "${Info} 转换失败，请手动转换后再运行此shell" && exit 1
             fi
        cd ${ssl_path} && ln -s changed_keypath privateKey.pem && ln -s changed_crtpath certificate.pem
        /etc/init.d/bt restart
            if [ $? -eq 0 ]; then
                echo -e "${Info} 宝塔面板重启成功！"
            else    
                echo -e "${Info} 宝塔面板启动失败,请手动重启:/etc/init.d/bt restart！"
            fi
        installed_check
        panel_status
        fi
    fi
}
#面板启动状态检查
panel_status(){
    /etc/init.d/bt status | awk '{print $5}' > panel_status.log
    if [[ `grep -ci "running" panel_status.log` -eq '2' ]]; then
        /etc/init.d/bt status
        echo
        echo -e "${Info} 宝塔面板正常运行"
    else
        echo -e "${Info} 面板状态异常,尝试重启面板..."
        /etc/init.d/bt restart
    fi
}
#安装检查
installed_check(){
    if [[ -e ${ssl_old_prikey} && ${ssl_old_fullchain} ]]; then
        echo
        echo -e "${Info} 安装成功!"
        panel_status
        echo -e "%{Info} 请使用${Green_font_prefix}${new_panel_adr}${Font_color_suffix}访问面板"
        echo -e "${Info} 登录前，建议使用【ctr+shift+delete】组合键情况浏览器缓存" && exit 0
    else
        echo -e "${Info} 安装失败!" && exit 1
    fi
}
#删除域名绑定,关闭SSL登录和清除限制IP列表
reset_panel(){
    echo
    echo -e "${Info} 进行此操作将会:删除域名绑定,关闭SSL登录和清除限制IP列表"
    echo
    echo -e "${Info} 当你不能登录面板的时候或者想重新安装面板SSL，请执行此操作(PS：反正玩不坏@_@"
    echo
    stty erase '^H' && read -p "确定恢复面板初始设置?(不会改变已经设置的面板端口)[Y/n]：" yn
    [ -z "${yn}" ] && yn="y"
    if [[ ${yn} == [Yy] ]]; then
            echo -e "${Info} 关闭宝塔面板..."
            /etc/init.d/bt stop
            cd ${panel_data} && rm ${domain_file} ${sslpl_file} ${limitip_file}
            echo -e "${Info} 开启宝塔面板..."
            /etc/init.d/bt restart
            if [ $? -eq 0 ]; then
                echo -e "${Info} 宝塔面板重启成功！"
            else    
                echo -e "${Info} 宝塔面板启动失败,请手动重启:/etc/init.d/bt restart！"
            fi
        fi
}
check_root
echo && echo -e "请输入一个数字来选择选项
—————————————————————————————
 ${Green_font_prefix}1.${Font_color_suffix} 检查面板SSL状态
 ${Green_font_prefix}2.${Font_color_suffix} 安装面板SSL证书和密钥
 ${Green_font_prefix}3.${Font_color_suffix} 面板状态检查
 ${Green_font_prefix}4.${Font_color_suffix} 恢复面板初始状态
—————————————————————————————" && echo
echo
echo -e "${Red_font_prefix}注意：此shell需要你在面板上绑定了域名,开启绑定域名的Lets-SSL的HTTPS.${Font_color_suffix}"
echo
echo -e "${Green_font_prefix}ToDo：未来全部一键自动化，不需要去面板手动添加域名和HTTPS.${Font_color_suffix}"
echo

stty erase '^H' && read -p "请输入数字 [1-4]:" num
case "$num" in
    1)
    check_panelssl_status
    ;;
    2)
    check_domain_install_ssl
    ;;
    3)
    panel_status
    ;;
    4)
    reset_panel
    ;;
    *)
    echo "请输入正确数字 [1-4]";;
esac
exit