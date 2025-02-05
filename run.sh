#!/bin/bash

text_primary() { echo -n " $1 $(printf '\055%.0s' {1..70})" | head -c 70; echo -n ' '; }
text_success() { printf "\e[00;92m%s\e[00m\n" "$1"; }
text_danger() { printf "\e[00;91m%s\e[00m\n" "$1"; exit 0; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Location/MongoDB-Docker; https://hub.docker.com/r/ip2location/mongodb)"
CODES=("DB1-LITE DB3-LITE DB5-LITE DB9-LITE DB11-LITE DB1 DB2 DB3 DB4 DB5 DB6 DB7 DB8 DB9 DB10 DB11 DB12 DB13 DB14 DB15 DB16 DB17 DB18 DB19 DB20 DB21 DB22 DB23 DB24 DB25 DB26")

if [ -f /config ]; then
	mongod --fork --logpath /var/log/mongodb/mongod.log --auth --bind_ip_all
	tail -f /dev/null
fi

[ "$TOKEN" == "FALSE" ] && text_danger "Missing download token."

[ "$CODE" == "FALSE" ] && text_danger "Missing database code."

[ "$MONGODB_PASSWORD" == "FALSE" ] && text_danger "Missing MongoDB password."

FOUND=""
for i in "${CODES[@]}"; do
	if [ "$i" == "$CODE" ] ; then
		FOUND="$CODE"
	fi
done

if [ -z $FOUND == "" ]; then
	text_danger "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

rm -rf /_tmp && mkdir /_tmp && cd /_tmp

text_primary " > Download IP2Location database"

if [ "$IP_TYPE" == "IPV4" ]; then
	wget -qO ipv4.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
else
	wget -qO ipv6.zip --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
fi

text_success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | sort -nr | grep -Eio 'IP(V6)?.*CSV' | head -n 1)

	text_primary " > Decompress $CSV from $ZIP"

	unzip -oq $ZIP $CSV

	if [ ! -f $CSV ]; then
		text_danger "[ERROR]"
	fi

	text_success "[OK]"
done

text_primary " > [MongoDB] Create data directory "
mkdir -p /data/db

[ $? -ne 0 ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MongoDB] Start daemon "
mongod --fork --logpath /var/log/mongodb/mongod.log --bind_ip_all

[ $? -ne 0 ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MongoDB] Create admin user "
mongosh << EOF
use admin
db.createUser({user: "mongoAdmin", pwd: "$MONGODB_PASSWORD", roles:["root"]})
exit
EOF

[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MongoDB] Shut down daemon "
mongod --shutdown

[ $? -ne 0 ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [MongoDB] Start daemon with authentication "
mongod --fork --logpath /var/log/mongodb/mongod.log --auth --bind_ip_all

[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

case "$CODE" in
	DB1|DB1LITE|DB1IPV6|DB1LITEIPV6 )
		FIELDS=''
	;;

	DB2|DB2IPV6 )
		FIELDS=',isp'
	;;

	DB3|DB3LITE|DB3IPV6|DB3LITEIPV6 )
		FIELDS=',region_name,city_name'
	;;

	DB4|DB4IPV6 )
		FIELDS=',region_name,city_name,isp'
	;;

	DB5|DB5LITE|DB5IPV6|DB5LITEIPV6 )
		FIELDS=',region_name,city_name,latitude,longitude'
	;;

	DB6|DB6IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,isp'
	;;

	DB7|DB7IPV6 )
		FIELDS=',region_name,city_name,isp,domain'
	;;

	DB8|DB8IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,isp,domain'
	;;

	DB9|DB9LITE|DB9IPV6|DB9LITEIPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code'
	;;

	DB10|DB10IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,isp,domain'
	;;

	DB11|DB11LITE|DB11IPV6|DB11LITEIPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone'
	;;

	DB12|DB12IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain'
	;;

	DB13|DB13IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,time_zone,net_speed'
	;;

	DB14|DB14IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed'
	;;

	DB15|DB15IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,idd_code,area_code'
	;;

	DB16|DB16IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code'
	;;

	DB17|DB17IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,time_zone,net_speed,weather_station_code,weather_station_name'
	;;

	DB18|DB18IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name'
	;;

	DB19|DB19IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,isp,domain,mcc,mnc,mobile_brand'
	;;

	DB20|DB20IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name,mcc,mnc,mobile_brand'
	;;

	DB21|DB21IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,idd_code,area_code,elevation'
	;;

	DB22|DB22IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name,mcc,mnc,mobile_brand,elevation'
	;;

	DB23|DB23IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,isp,domain,mcc,mnc,mobile_brand,usage_type'
	;;

	DB24|DB24IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name,mcc,mnc,mobile_brand,elevation,usage_type'
	;;

	DB25|DB25IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name,mcc,mnc,mobile_brand,elevation,usage_type,address_type,category'
	;;
	
	DB266|DB26IPV6 )
		FIELDS=',region_name,city_name,latitude,longitude,zip_code,time_zone,isp,domain,net_speed,idd_code,area_code,weather_station_code,weather_station_name,mcc,mnc,mobile_brand,elevation,usage_type,address_type,category,district,asn,as
	;;
esac

if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	text_primary " > [MongoDB] Create index field "
	cat $CSV | awk 'BEGIN { FS="\",\""; } { s = "0000000000000000000000000000000000000000"$2; print "\"A"substr(s, 1 + length(s) - 40)"\","$0; }' > ./INDEXED.CSV

	[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

	text_primary " > [MongoDB] Create collection \"ip2location_database_tmp\" and import data "
	mongoimport -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin --drop --db ip2location_database --collection ip2location_database_tmp --type csv --file "./INDEXED.CSV" --fields ip_to_index,ip_from,ip_to,country_code,country_name$FIELDS

	[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

	text_primary " > [MongoDB] Create index "
	mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.createIndex({ip_to_index: 1})
exit
EOF

	[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"
else
	text_primary " > [MongoDB] Create collection \"ip2location_database_tmp\" and import data "
	mongoimport -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin --drop --db ip2location_database --collection ip2location_database_tmp --type csv --file "$CSV" --fields ip_from,ip_to,country_code,country_name$FIELDS

	[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

	text_primary " > [MongoDB] Create index "
	mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.createIndex({ip_to: 1})
exit
EOF
	[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"
fi

text_primary " > [MongoDB] Rename collection \"ip2location_database_tmp\" to \"ip2location_database\" "
mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.renameCollection("ip2location_database", true)
exit
EOF

[ $? -ne 0 ] &&  text_danger "[ERROR]" || text_success "[OK]"

echo " > Setup completed"
echo ""
echo " > You can now connect to this MongoDB server using:"
echo ""
echo "   mongosh -u mongoAdmin -p \"$MONGODB_PASSWORD\" --authenticationDatabase admin"
echo ""

echo "MONGODB_PASSWORD=$MONGODB_PASSWORD" > /config
echo "TOKEN=$TOKEN" >> /config
echo "CODE=$CODE" >> /config

rm -rf /_tmp

tail -f /dev/null