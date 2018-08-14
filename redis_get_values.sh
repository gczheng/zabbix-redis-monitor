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
