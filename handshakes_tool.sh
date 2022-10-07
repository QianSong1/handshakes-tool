#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    1725099638
#Date:                  2022-10-03
#FileName：             handshakes_tool.sh
#URL:                   https://github.com/QianSong1
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
#==================                                 an zhuang yi lai ruan jian function                          ===========================
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
for i in mdk3 mdk4 airmon-ng airodump-ng xterm dos2unix cowpatty aireplay-ng
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
			*)
				echo -e "\033[31mUknown error..\033[0m"
				exit 4
				;;
		esac
	fi
	sleep 0.1
done

#===========================================================================================================================================
#====================                                           xuan zhe gon ji tool                                 =======================
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
