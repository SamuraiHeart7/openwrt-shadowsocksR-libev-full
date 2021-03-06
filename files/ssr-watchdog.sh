#!/bin/sh

LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

CURRENT=$(ls -l /etc/shadowsocksr.json | awk -F "." '{print $4}')

if [ "$CURRENT" == "backup" ]; then
	echo "[$LOGTIME] Backup server is running."
	MAIN=$(cat /etc/shadowsocksr.json.main | awk -F '\"' '/\"server\"/ {print $4}')
	PM=$(ping -c 3 $MAIN | grep 'loss' | awk -F ',' '{ print $3 }' | awk -F "%" '{ print $1 }')
	if [ "$PM" -lt "50" ]; then
		echo "[$LOGTIME] Main server up,$PM% packet loss, switch back."
		ln -sf /etc/shadowsocksr.json.main /etc/shadowsocksr.json
		CURRENT=$(ls -l /etc/shadowsocksr.json | awk -F "." '{print $4}')
		/etc/init.d/shadowsocksr restart
		sleep 3
	else
		echo "[$LOGTIME] Main server down,$PM% packet loss."
	fi
fi

wget -s -q -T3 ssl.gstatic.com/generate_204
if [ "$?" == "0" ]; then
	echo "[$LOGTIME] No problem."
	exit 0
else
	wget -s -q -T3 t.cn
	if [ "$?" == "0" ]; then
		echo "[$LOGTIME] Problem decteted, restart ShadowsocksR."
		/etc/init.d/shadowsocksr restart
		if [ "$CURRENT" == "main" ]; then
			sleep 3
			wget -s -q -T3 ssl.gstatic.com/generate_204
			if [ "$?" == "0" ]; then
				echo "[$LOGTIME] ShadowsocksR recovered."
				exit 0
			else
				echo "[$LOGTIME] Main server down, switch to backup server."
				ln -sf /etc/shadowsocksr.json.backup /etc/shadowsocksr.json
				/etc/init.d/shadowsocksr restart
				exit 0
			fi
		fi
	else
		echo "[$LOGTIME] Network problem. Do nothing."
	fi
fi
