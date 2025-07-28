#!/bin/bash
echo "################################################"
echo " Script Task: K3S Service IP Updater            "
echo " File Loc: /etc/systemd/system/k3s.service      "
echo "################################################"
echo " "

if [ -f /etc/systemd/system/k3s.service ]; then
	echo "Stopping k3s service..."
	systemctl daemon-reload
	systemctl stop k3s.service

	echo "Detecting External IP..."
	#Where "ens33" is the network interface name. Modify it accordingly if you have different network interface.
	sudo nmcli dev disconnect ens33
	systemctl restart NetworkManager
	sudo nmcli dev connect ens33
	export EXTERNAL_IP=$(ifconfig |grep -A 1 "ens33" |tail -n 1 | grep -o -E "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"| grep -o -E "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")
	while [ -z "${EXTERNAL_IP}" ]; do
	 sleep 3
	 echo "Detecting external IP has been failed. Please enable network connectivity..."
	 export EXTERNAL_IP=$(ifconfig |grep -A 1 "ens33" |tail -n 1 | grep -o -E "inet [0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"| grep -o -E "[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")
	done
	export CLUSTER_CIDR=192.168.10.0/24
	export SERVICE_CIDR=192.168.20.0/24
	export K3S_KUBECONFIG_MODE="644"
	echo -e "External IP \033[32m $EXTERNAL_IP\033[0m Detected..."


	echo "Locating the node-external-ip line in k3s.service file..."
	node_ip_lineNum=$(grep -n "node-external-ip" /etc/systemd/system/k3s.service| cut -d: -f1)

	echo "Updating..."
	sed_delete_directive=d
	sed_append_directive=a
	sed -i $((node_ip_lineNum + 1))$sed_delete_directive /etc/systemd/system/k3s.service
	sed -i "$node_ip_lineNum $sed_append_directive\        '$EXTERNAL_IP' \\\\" /etc/systemd/system/k3s.service | cat -e

	echo "Validating changes..."
	validation_res=$(grep -n $EXTERNAL_IP /etc/systemd/system/k3s.service| cut -d: -f1)
	if [ $validation_res -gt 0 ]; then
	 echo -e "Assigning new IP\033[32m $EXTERNAL_IP\033[0m validated."
	else
	 echo "Opps! Updating new IP failed.Please try again!"
	fi
	
	echo "Starting k3s service..."
	systemctl daemon-reload
	systemctl start k3s.service

	sleep 3
	strStatus=$(systemctl is-active k3s.service)
	while [ $(systemctl show -p ActiveState --value k3s.service) != "active" ]; do
		sleep 3
		strStatus=$(systemctl is-active k3s.service)
		echo -e "k3s Service $strStatus. Please check network connectivity or wait for a while..."
	done
	kubectl get nodes -o wide
	echo " "
	echo -e "You may execute these commands individually to check Service, Nodes and Pods status."
	echo -e "K3s Service        	  : \033[41;37m systemctl status k3s.service \033[0m"
	echo -e "All Nodes          	  : \033[41;37m kubectl get nodes -o wide \033[0m"
	echo -e "All Pods           	  : \033[41;37m kubectl get pods -A -o wide  \033[0m"
	echo -e "Store Pods Only         : \033[41;37m kubectl get pods -n store  \033[0m"
	echo -e "Terminal01 Pods Only    : \033[41;37m kubectl get pods -n terminal01  \033[0m"
else
	echo "Sorry, K3S application not found. Please install first and try again!"
fi

#EndOfScript-RB185114
