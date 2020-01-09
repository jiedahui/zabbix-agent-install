#!/bin/bash

yum -y install wget


agent_rpm='zabbix-agent-4.4.0-1.el7.x86_64.rpm'
sender_rpm='zabbix-sender-4.4.0-1.el7.x86_64.rpm'

qjpath=`pwd`

if [ ! -e $agent_rpm ]
then
	wget https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-agent-4.4.0-1.el7.x86_64.rpm
fi

if [ ! -e $sender_rpm ]
then
	wget https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-sender-4.4.0-1.el7.x86_64.rpm
fi

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -r 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
iptables -F
iptables -Z

yum -y localinstall $agent_rpm $sender_rpm

#获取当前Ip
host_ip=`/sbin/ifconfig | grep 'inet'|awk 'NR==1{print $2}'`
#active_ip=`echo $host_ip|sed 's/[0-9]\{1,3\}$/9/'`

#zabbix-server的ip
active_ip="192.168.192.193"

#获取当前的主机名当做zabbix-agent的主机名
host_name=`cat /etc/hostname`

#替换agent的配置文件
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak
cp zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf

#修改某些配置项
sed -i '/^SourceIP=/s/^.*$/\#SourceIP='$host_ip'/g' /etc/zabbix/zabbix_agentd.conf
#sed -i '/^Hostname=/s/^.*$/Hostname='$host_ip'/g' /etc/zabbix/zabbix_agentd.conf
sed -i '/^Hostname=/s/^.*$/Hostname='$host_name'/g' /etc/zabbix/zabbix_agentd.conf
sed -i '/^ServerActive=/s/^.*$/\ServerActive='$active_ip'/g' /etc/zabbix/zabbix_agentd.conf
echo "zabbix    ALL=(ALL)    NOPASSWD:ALL"  >> /etc/sudoers

#如果有需要配置自定义参数，则上传对应的conf文件和sh脚本到当前目录下，开启以下配置
#cp ****.conf /etc/zabbix/zabbix_agentd.d/
#cp ****.sh /usr/lib/zabbix/alertscripts/

echo 'UserParameter=host_name_get, cat /etc/hostname' > /etc/zabbix/zabbix_agentd.d/host_name_get.conf


#配置开机启动
/bin/echo "/bin/systemctl start zabbix-agent" >> /etc/rc.d/rc.local

#restart zabbix-agent
systemctl restart zabbix-agent

