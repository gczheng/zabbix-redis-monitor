#!/bin/bash
# line:           V1.0
# mail:           zhenggc@ipanel.cn
# data:           2018-08-06
# script_name:    ipanel_redis_low_discovery.sh
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
