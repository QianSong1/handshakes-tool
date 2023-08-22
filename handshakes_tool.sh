#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    xxxxxxxx
#Date:                  2022-10-03
#FileName：             handshakes_tool.sh
#URL:                   https://github.com
#Description：          The handshakes tools select script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi source dir var
source_dir=$(dirname $(realpath $0))/handshakes-tool-scripts

#pan duan shi fou root yon hu yun xing
if [ "${UID}" != "0" ]; then
	echo -e "\033[31mPermission denied, please run this script as root.\033[0m"
	exit 1
fi

#===========================================================================================================================================
#=====================                                            print app info                                 ===========================
#===========================================================================================================================================
function logo() {

# print fuo zhu png
cat <<EOF

                                  _oo0oo_
                                 088888880
                                 88" . "88
                                 (| -_- |)
                                  0\ = /0
                               ___/'---'\___
                             .' \\\\|     |// '.
                            / \\\\|||  :  |||// \\
                           /_ ||||| -:- |||||- \\
                          |   | \\\\\\  -  /// |   |
                          | \_|  ''\---/''  |_/ |
                          \  .-\__  '-'  __/-.  /
                        ___'. .'  /--.--\  '. .'___
                     ."" '<  '.___\_<|>_/___.' >'  "".
                    | | : '-  \'.;'\ _ /';.'/ - ' : | |
                    \  \ '_.   \_ __\ /__ _/   .-' /  /
                ====='-.____'.___ \_____/___.-'____.-'=====
                                  '=---='

              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        佛祖保佑    iii    永不BUG

EOF
}

function print_app_info() {

# ding yi color vars
local color_1='\033[1;30m'
local color_2='\033[1;31m'
local color_3='\033[1;32m'
local color_4='\033[1;34m'
local color_5='\033[1;35m'
local color_6='\033[1;36m'
local color_7='\033[1;33m'
local color_8='\033[1;37m'
local RST='\033[0m'

# print first jpg
clear
# zifu hua shen cheng  fang fa: toilet -f smblock -t 'ATTACKER_Q               ATTACKER_Q'
# an zhuang zi fu hua  tool: apt install toilet
echo -e """
${color_2}▞▀▖▀▛▘▀▛▘▞▀▖▞▀▖▌ ▌▛▀▘▛▀▖   ▞▀▖               ▞▀▖▀▛▘▀▛▘▞▀▖▞▀▖▌ ▌▛▀▘▛▀▖   ▞▀▖
▙▄▌ ▌  ▌ ▙▄▌▌  ▙▞ ▙▄ ▙▄▘   ▌ ▌               ▙▄▌ ▌  ▌ ▙▄▌▌  ▙▞ ▙▄ ▙▄▘   ▌ ▌
▌ ▌ ▌  ▌ ▌ ▌▌ ▖▌▝▖▌  ▌▚    ▌▚▘               ▌ ▌ ▌  ▌ ▌ ▌▌ ▖▌▝▖▌  ▌▚    ▌▚▘
▘ ▘ ▘  ▘ ▘ ▘▝▀ ▘ ▘▀▀▘▘ ▘▀▀▀▝▘▘               ▘ ▘ ▘  ▘ ▘ ▘▝▀ ▘ ▘▀▀▘▘ ▘▀▀▀▝▘▘${RST}
                            ${color_3}~=:by QianSong1:=~${RST}
                     > ${color_4}\033[4mhttps://github.com/QianSong1${RST} <

"""

# loop print fuo zhu png
IFS=$'\n'
for i in $(logo)
do
	r_num=$(awk -v random=${RANDOM} 'BEGIN{print random % 8 +1}')
	r_char="\$color_${r_num}"
	r_color=$(eval "echo -e \"${r_char}\"")
	echo -e "${r_color}${i}${RST}"
	sleep 0.1
done

# print process info
i=1
while [ ${i} -lt 5 ]; do
	for char in '/' '.' '\'
	do
		echo -n "                                    [${char}]                                      "
		echo -ne "\r\r"
		sleep 0.2
	done
	let i++
done
echo -e "\n"
sleep 0.3
}
print_app_info

#===========================================================================================================================================
#=====================                              an zhuang yi lai ruan jian function                          ===========================
#===========================================================================================================================================
install_dependent_software() {
apt update
if [ $? -ne 0 ]; then
	echo -e "\033[31mnetwork error\033[0m"
	exit 2
fi
apt install $1 -y
if [ $? -ne 0 ]; then
	echo -e "\033[31mnetwork error\033[0m"
	exit 3
fi
}

#pan  duan  shi  fou  an zhuang  le  yi  lai  ruan  jian
for i in mdk3 mdk4 airmon-ng airodump-ng xterm dos2unix cowpatty aireplay-ng macchanger
do
	type ${i} >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "${i}.....................\033[32mOK\033[0m"
	else
		echo -e "${i}.....................\033[33mInstalling\033[0m"
		case ${i} in
			mdk3)
				install_dependent_software mdk3
				;;
			mdk4)
				install_dependent_software mdk4
				;;
			airmon-ng)
				install_dependent_software aircrack-ng
				;;
			airodump-ng)
				install_dependent_software aircrack-ng
				;;
			aireplay-ng)
				install_dependent_software aircrack-ng
				;;
			xterm)
				install_dependent_software xterm
				;;
			dos2unix)
				install_dependent_software dos2unix
				;;
			cowpatty)
				install_dependent_software cowpatty
				;;
			macchanger)
				install_dependent_software macchanger
				;;
			*)
				echo -e "\033[31mUknown error..\033[0m"
				exit 4
				;;
		esac
	fi
	sleep 0.1
done

#===========================================================================================================================================
#=====================                               check and kill wlan card busy pid                           ===========================
#===========================================================================================================================================
airmon-ng check kill >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "\033[31mError for check kill Disturbed process, quit !\033[0m"
	exit 1
fi

#===========================================================================================================================================
#=====================                                        print notice info                                  ===========================
#===========================================================================================================================================
echo -e "\n"
echo -e "\033[33m加载完毕！正在为您启动，请稍等鸡儿几秒钟.......\033[0m"
sleep 5
clear

#===========================================================================================================================================
#==========================                                       xuan zhe gon ji tool                             =========================
#===========================================================================================================================================
handshake_tool_menu() {
echo -e "\033[33mSelect one tool what you want to use\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[32m1.        mdk-tool(推荐)\033[0m           \033[36m*\033[0m"
echo -e "\033[32m2.        aireplay-tool(备选)\033[0m      \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
read -p "Please select: " handshake_tool
case ${handshake_tool} in
	1)
		clear
		source ${source_dir}/handshakes_by_mdk.sh
		;;
	2)
		clear
		source ${source_dir}/handshakes_by_aireplay.sh
		;;
	*)
		clear
		handshake_tool_menu
		;;
esac
}

#yun  xing  function ru  kou
handshake_tool_menu
