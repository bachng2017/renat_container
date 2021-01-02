#!/bin/sh

usage() {
  echo "Usage: $0 [-g logstash-addr] [-z timezone]" 1>&2
  exit 1
}

while getopts g:z:h  OPT
do
  case $OPT in
    g)  LOGSTASH_ADDR=$OPTARG
        ;;
    z)  TIME_ZONE=$OPTARG 
        ;;
    h)  usage
        ;;
  esac
done


# set timezone
if [ "$TIME_ZONE" != "" ]; then
  ln -fs /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
  echo "change timezone to $TIME_ZONE"
fi

# set logstash address
if [ "$LOGSTASH_ADDR" != "" ]; then
  sed -i "s/\"logstash:5044\"/\"$LOGSTASH_ADDR:5044\"/g" /etc/filebeat/filebeat.yml
  echo "logstash server: $LOGSTASH_ADDR"
fi	


# prepare configuration file
for item in $(ls -1 $RENAT_PATH/misc/config.sample); do 
  if [ ! -f $RENAT_PATH/config/$item ]; then
     cp $RENAT_PATH/misc/config.sample/$item $RENAT_PATH/config/$item
  fi
done


# start services
exec /usr/sbin/init



