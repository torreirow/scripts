#!/bin/bash
if [[ -f /usr/bin/systemctl ]]
 then rhel=7
 elif [[ -f /sbin/service ]]
  then rhel=6
 else
  echo "!! Can't determine rhel version"
  exit 1
fi

if [[ ${rhel} == "7" ]]
 then
  tomcatsenabled=$(systemctl list-unit-files | grep enabled |grep -i tomcat|awk '{print $1}')
  for tomcat in ${tomcatsenable[@]}
   do
    tomcatPID=$(systemctl status ${tomcat}|grep PID|awk '{print $3}'
	if [[ ! -z ${tomcatPID} ]]
	 then
	  echo "Stopping tomcat process ${tomcat}"
	  systemctl stop ${tomcat}
	 else
	  echo "Tomcat process ${tomcat} not running"
	fi
    tomcatjavaPIDs=$( ps -ef |grep -i java|grep tomcat|awk '{print $2}')
    if [[ ! -z ${javaPID} ]]
     then
	  echo "!! There are still tomcats running. Killing them: ${tomcatjavaPIDs}"
	  kill ${tomcatjavaPIDs}
	fi
      	 
  fi
  
  