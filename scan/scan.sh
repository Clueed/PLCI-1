#!/bin/bash
RUN=0
COUNT="$(cat ./count)"

scan-now () {
	echo -n "Enter your scanning resolution {100|150|200|300|400|600|1200|2400|4800|9600dpi} and press [ENTER]: "
		read res
	sudo scanimage --buffer-size=1024 --resolution $res --progress --format=jpeg > ./scan.jpg
#	touch ./scan.jpg
	mv ./scan.jpg ./img/$(date +%d-%m-%y)_$COUNT.jpg
	echo "Scanned File: $(date +%d-%m-%y)_$COUNT.jpg"
	COUNT=$((COUNT + 1))
	echo $COUNT > ./count
	RUN=$(($RUN + 1))
}


cd /home/mark/scan/

echo "INITIALIZING USB-IP KERNEL MODULES"
#sudo modprobe usbip-core
#sudo modprobe usbip-host
sudo modprobe vhci-hcd
sudo usbipd -D

echo 'BINDING USB-IP "Brother Printer DCP-7030" AT 192.168.1.59 1-1.3'

sshpass -p "1[+iL5BDsF/6)R$>Wz" ssh -o StrictHostKeyChecking=no pi@192.168.1.59 'sudo modprobe usbip-core && sudo modprobe usbip-host && sudo usbipd -D && sudo usbip bind -b 1-1.3'

echo 'ATTACHING USB-IP "Brother Printer DCP-7030" FROM 192.168.1.59 1-1.3'

sudo usbip attach -r 192.168.1.59 -b 1-1.3

for (( ; ; ))
do
if [ $RUN = 0 ]; then
	scan-now
else
	echo -n "Scan Document now? (y/n)? "
	old_stty_cfg=$(stty -g)
	stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg # Care playing with stty
	if echo "$answer" | grep -iq "^y" ;then
		echo Yes
		scan-now
	else
		echo No
		break
	fi
fi
done
echo 'UNBINDING USB-IP "Brother Printer DCP-7030" AT 192.168.1.59 1-1.3'

sudo usbip detach -p 0

sshpass -p "1[+iL5BDsF/6)R$>Wz" ssh -o StrictHostKeyChecking=no pi@192.168.1.59 'sudo usbip unbind -b 1-1.3'
