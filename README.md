# 一、zabbix 自动发现并监控redis多实例

## 1.1 编写脚本

### 1.1.1 redis_low_discovery.sh

用于发现redis多实例
```bash
[root@node02 zabbix]# cat /usr/local/zabbix/redis_low_discovery.sh
#!/bin/bash
# line:           V1.0
# mail:           gczheng@139.com
# data:           2018-08-06
# script_name:    redis_low_discovery.sh
# Fucation:       redis low-level discovery

redis() {
            port=($(sudo netstat -tpln | awk -F "[ :]+" '/redis-serv*/ && /0.0.0.0/ {print $5}'))
            printf '{\n'
            printf '\t"data":[\n'
               for key in ${!port[@]}
                   do
                       if [[ "${#port[@]}" -gt 1 && "${key}" -ne "$((${#port[@]}-1))" ]];then
              socket=`ps aux|grep ${port[${key}]}|grep -v grep|awk -F '=' '{print $10}'|cut -d ' ' -f 1`
                          printf '\t {\n'
                          printf "\t\t\t\"{#REDISPORT}\":\"${port[${key}]}\"},\n"
                     else [[ "${key}" -eq "((${#port[@]}-1))" ]]
              socket=`ps aux|grep ${port[${key}]}|grep -v grep|awk -F '=' '{print $10}'|cut -d ' ' -f 1`
                          printf '\t {\n'
                          printf "\t\t\t\"{#REDISPORT}\":\"${port[${key}]}\"}\n"
                       fi
               done
                          printf '\t ]\n'
                          printf '}\n'
}

sentinel() {
            port=($(sudo netstat -tpln | awk -F "[ :]+" '/redis-sent*/ && /0.0.0.0/ {print $5}'))
            printf '{\n'
            printf '\t"data":[\n'
               for key in ${!port[@]}
                   do
                       if [[ "${#port[@]}" -gt 1 && "${key}" -ne "$((${#port[@]}-1))" ]];then
              socket=`ps aux|grep ${port[${key}]}|grep -v grep|awk -F '=' '{print $10}'|cut -d ' ' -f 1`
                          printf '\t {\n'
                          printf "\t\t\t\"{#REDISPORT}\":\"${port[${key}]}\"},\n"
                     else [[ "${key}" -eq "((${#port[@]}-1))" ]]
              socket=`ps aux|grep ${port[${key}]}|grep -v grep|awk -F '=' '{print $10}'|cut -d ' ' -f 1`
                          printf '\t {\n'
                          printf "\t\t\t\"{#REDISPORT}\":\"${port[${key}]}\"}\n"
                       fi
               done
                          printf '\t ]\n'
                          printf '}\n'
}

$1
[root@node01 zabbix]#
```

### 1.1.2 redis_get_values.sh

用于获取redis值

```bash
[root@node02 zabbix]# cat /usr/local/zabbix/redis_get_values.sh
#!/bin/sh
# line:           V1.0
# mail:           gczheng@139.com
# data:           2018-08-06
# script_name:    redis_get_values.sh

REDIS_CLI=/homed/redis/bin/redis-cli.exe

while getopts "p:k:P:" opt
do
        case $opt in
                p ) redis_port=$OPTARG;;
                k ) redis_info_key=$OPTARG;;
                P ) redis_passwd=$OPTARG;;
                ? )
                echo '参数错误!'
                exit 1;;
        esac
done

#判断redis端口和info健值是否存在
if [ ! "${redis_port}" ] || [ ! "${redis_info_key}" ];then
        echo "参数不存在"        
        exit 1
fi

function chk_result_status()
{
#判断result值是否存在
if [ ! "$result" ] ;then
        echo 0  
else
	echo $result
fi
}

##判断是否使用密码远程登陆
if [ "${redis_passwd}" ];then
        REDIS_COMM="${REDIS_CLI} -a ${redis_passwd} -p ${redis_port} info"
else
        REDIS_COMM="${REDIS_CLI} -p ${redis_port} info"
fi

function get_values()
{
if [ "master_link_status" == "${redis_info_key}" ];then
   	result=`$REDIS_COMM|/bin/grep -w "master_link_status"|awk -F':' '{print $2}'|/bin/grep -c up`
    chk_result_status 
elif [ "role" == "${redis_info_key}" ];then
    result=`$REDIS_COMM|/bin/grep -w "role"|awk -F':' '{print $2}'|/bin/grep -c master`
    chk_result_status 
elif [ "rdb_last_bgsave_status" == "${redis_info_key}" ];then
    result=`$REDIS_COMM|/bin/grep -w "rdb_last_bgsave_status" | awk -F':' '{print $2}' | /bin/grep -c ok`
    chk_result_status 
elif [ "aof_last_bgrewrite_status" == "${redis_info_key}" ];then
    result=`$REDIS_COMM|/bin/grep -w "aof_last_bgrewrite_status" | awk -F':' '{print $2}' | /bin/grep -c ok`
    chk_result_status 
elif [ `echo "${redis_info_key}" |egrep -cw 'dict_keys|dict_expires|intdict_keysi|intdict_expires|sentinel_status|sentinel_slaves|sentinel_nums'` == "1" ];then
	#cn=`echo "${redis_info_key}" |awk -F "," '{print $2}'`
	cn=`echo "${redis_info_key}"`
	case $cn in
	dict_keys)
		result=`$REDIS_COMM| /bin/grep -w "db0"|/bin/grep -w "dict"|/bin/grep -w "keys" | awk -F'=|,' '{print $3}'`
                chk_result_status 
	        ;;
	 dict_expires)
	        result=`$REDIS_COMM| /bin/grep -w "db0"|/bin/grep -w "dict"|/bin/grep -w "expires" | awk -F'=|,' '{print $5}'`
	        chk_result_status 
	        ;;
	 intdict_keys)
	        result=`$REDIS_COMM|/bin/grep -w "db0"|/bin/grep -w "intdict" |/bin/grep -w "keys" | awk -F'=|,' '{print $3}'`
	        chk_result_status 
	        ;;
         intdict_expires)     
           	result=`$REDIS_COMM|/bin/grep -w "db0"|/bin/grep -w "intdict" |/bin/grep -w "expites" | awk -F'=|,' '{print $5}'`
                chk_result_status 
                ;;
          sentinel_status)     
           	result=`$REDIS_COMM|/bin/grep -w "master0"|awk -F'=|,' '{print $4}'| /bin/grep -c ok`
                chk_result_status 
                ;;
          sentinel_slaves)     
           	result=`$REDIS_COMM|/bin/grep -w "master0"|awk -F'=|,' '{print $8}'`
                chk_result_status 
                ;;
          sentinel_nums)     
           	result=`$REDIS_COMM|/bin/grep -w "master0"|awk -F'=|,' '{print $10}'`
                chk_result_status 
                ;;
	esac
else
    result=`$REDIS_COMM|/bin/grep -w  "${redis_info_key}"|cut -d: -f2`
    chk_result_status 
fi
}

get_values


```

# 二、授权zabbix使用netstat

允许 `zabbix` 用户无密码运行 `netstat` 及 `Disable requiretty`
```bash
[root@redis02 homed]# echo "zabbix ALL=(root) NOPASSWD:/bin/netstat">>/etc/sudoers
[root@redis02 homed]# sed -i 's/^Defaults.*.requiretty/#Defaults    requiretty/' /etc/sudoers
```


# 三、配置zabbix UserParameter

修改/etc/zabbix/zabbix_agentd.conf 

```bash
[root@node02 homed]#  grep -Ev "^$|^#" /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.49.245
ServerActive=127.0.0.1
Hostname=Zabbix server
Include=/etc/zabbix/zabbix_agentd.d/*.conf

#添加以下内容
UnsafeUserParameters=1
UserParameter=redis_discovery[*],/bin/bash /usr/local/zabbix/redis_low_discovery.sh $1
UserParameter=redis_items[*],/bin/bash /usr/local/zabbix/redis_get_values.sh  -p $1 -k $2
UserParameter=sentinel_items[*],/bin/bash /usr/local/zabbix/redis_get_values.sh  -p $1 -k $2
```

# 四、重启agent并尝试获取值

重启zabbix-agent
```bash
[root@redis02 homed]# systemctl restart zabbix-agent.service
[root@redis02 homed]# systemctl status zabbix-agent.service
```

zabbix server主机上用zabbix_get 获取值

```bash
[root@node01 /]# zabbix_get -s 192.168.49.252 -k redis_discovery[redis]
{
	"data":[
	 {
			"{#REDISPORT}":"17035"},
	 {
			"{#REDISPORT}":"6379"},
	 {
			"{#REDISPORT}":"13135"},
	 {
			"{#REDISPORT}":"7379"},
	 {
			"{#REDISPORT}":"11835"},
	 {
			"{#REDISPORT}":"12635"},
	 {
			"{#REDISPORT}":"13635"}
	 ]
}
[root@node01 /]# zabbix_get -s 192.168.49.252 -k redis_discovery[sentinel]
{
	"data":[
	 {
			"{#REDISPORT}":"17034"},
	 {
			"{#REDISPORT}":"13134"},
	 {
			"{#REDISPORT}":"7378"},
	 {
			"{#REDISPORT}":"11834"},
	 {
			"{#REDISPORT}":"12634"},
	 {
			"{#REDISPORT}":"13634"}
	 ]
}


[root@node01 ~]#  zabbix_get -s 192.168.49.252 -p 10050  -k redis_items[7379,role]
slave

[root@node01 ~]# zabbix_get -s 192.168.49.252 -p 10050  -k redis_items[7379,uptime_in_seconds]
173728

[root@node01 ~]# zabbix_get -s 192.168.49.252 -p 10050  -k sentinel_items[7378,sentinel_status]
0

[root@node01 ~]# zabbix_get -s 192.168.49.252 -p 10050  -k sentinel_items[7378,sentinel_nums]
1

```

# 五、导入模板

* 导入zbx_export_templates，并连接监控主机


![](https://images2018.cnblogs.com/blog/1166598/201808/1166598-20180813180345136-1454421468.png)

![](https://images2018.cnblogs.com/blog/1166598/201808/1166598-20180813180434569-1293082620.png)

