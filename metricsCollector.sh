#!/bin/bash  
export INFLUX_SERVER=$1  
while [ 1 -eq 1 ];  
do

### From https://www.rittmanmead.com/blog/2016/07/system-metrics-collectors/

#######CREATE DATABASE ########
curl -G http://$INFLUX_SERVER:8086/query  -s --data-urlencode "q=CREATE DATABASE OSStat" > /dev/null

####### CPU  #########
sar 1 1 -u | tail -n 1 | awk -v MYHOST=$(hostname)   '{  print "cpu,host="MYHOST"  %usr="$2",%nice="$3",%sys="$4",%idle="$5}' | curl -i -XPOST "http://${INFLUX_SERVER}:8086/write?db=OSStat"  -s --data-binary @- > /dev/null

####### Memory ##########
FREE_BLOCKS=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')  
INACTIVE_BLOCKS=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')  
SPECULATIVE_BLOCKS=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')  
WIRED_BLOCKS=$(vm_stat | grep wired | awk '{ print $4 }' | sed 's/\.//')

FREE=$((($FREE_BLOCKS+SPECULATIVE_BLOCKS)*4096/1048576))  
INACTIVE=$(($INACTIVE_BLOCKS*4096/1048576))  
TOTALFREE=$((($FREE+$INACTIVE)))  
WIRED=$(($WIRED_BLOCKS*4096/1048576))  
ACTIVE=$(((4096-($TOTALFREE+$WIRED))))  
TOTAL=$((($INACTIVE+$WIRED+$ACTIVE)))

curl -i -XPOST "http://${INFLUX_SERVER}:8086/write?db=OSStat"  -s --data-binary  "memory,host="$(hostname)" Free="$FREE",Inactive="$INACTIVE",Total-free="$TOTALFREE",Wired="$WIRED",Active="$ACTIVE",total-used="$TOTAL > /dev/null

####### Disk IO ##########
iotop -t 1 1 -P | head -n 2  | grep 201 | awk -v MYHOST=$(hostname)  
  '{ print "diskio,host="MYHOST" io_time="$6"read_bytes="$8*1024",write_bytes="$11*1024}'  | curl -i -XPOST "http://${INFLUX_SERVER}:8086/write?db=OSStat"  -s --data-binary @- > /dev/null

###### NETWORK ##########
sar -n DEV 1  |grep -v IFACE|grep -v Average|grep -v -E ^$ | awk -v MYHOST="$(hostname)" '{print "net,host="MYHOST",iface="$2" pktin_s="$3",bytesin_s="$4",pktout_s="$4",bytesout_s="$5}'|curl -i -XPOST "http://${INFLUX_SERVER}:8086/write?db=OSStat"  -s --data-binary @- > /dev/null

sleep 10;  
done