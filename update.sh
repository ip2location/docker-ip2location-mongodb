#!/bin/bash

error() { echo -e "\e[91m$1\e[m"; exit 0; }
success() { echo -e "\e[92m$1\e[m"; }

if [ ! -f /config ]; then
	error "Missing configuration file."
fi

TOKEN=$(grep 'TOKEN' /config | cut -d= -f2)
CODE=$(grep 'CODE' /config | cut -d= -f2)
MONGODB_PASSWORD=$(grep 'MONGODB_PASSWORD' /config | cut -d= -f2)

echo -n " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && error "[ERROR]" || success "[OK]"

cd /_tmp

echo -n " > Download IP2Location database "

wget -O database.zip -q --user-agent="Docker-IP2Location/MongoDB" http://www.ip2location.com/download?token=${TOKEN}\&productcode=${CODE} > /dev/null 2>&1

[ ! -f database.zip ] && error "[DOWNLOAD FAILED]"

[ ! -z "$(grep 'NO PERMISSION' database.zip)" ] && error "[DENIED]"

[ ! -z "$(grep '5 TIMES' database.zip)" ] && error "[QUOTA EXCEEDED]"

[ $(wc -c < database.zip) -lt 512000 ] && error "[FILE CORRUPTED]"

success "[OK]"

echo -n " > Decompress downloaded package "

unzip -q -o database.zip

if [ "$CODE" == "DB1" ]; then
	CSV="$(find . -name 'IPCountry.csv')"

elif [ "$CODE" == "DB2" ]; then
	CSV="$(find . -name 'IPISP.csv')"

elif [ ! -z "$(echo $CODE | grep 'LITE')" ]; then
	CSV="$(find . -name 'IP*.CSV')"

elif [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	CSV="$(find . -name 'IPV6-COUNTRY*.CSV')"

else
	CSV="$(find . -name 'IP-COUNTRY*.CSV')"
fi

[ -z "$CSV" ] && error "[FILE CORRUPTED]" || success "[OK]"

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
esac

if [ ! -z "$(echo $CODE | grep 'IPV6')" ]; then
	echo -n " > [MongoDB] Create index field "
	cat $CSV | awk 'BEGIN { FS="\",\""; } { s = "0000000000000000000000000000000000000000"$2; print "\"A"substr(s, 1 + length(s) - 40)"\","$0; }' > ./INDEXED.CSV
	if [ $? -ne 0 ] ; then
		error "[ERROR]"
	fi
	
	success "[OK]"
	
	echo -n " > [MongoDB] Create collection \"ip2location_database_tmp\" and import data "
	mongoimport -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin --drop --db ip2location_database --collection ip2location_database_tmp --type csv --file "./INDEXED.CSV" --fields ip_to_index,ip_from,ip_to,country_code,country_name$FIELDS

	if [ $? -ne 0 ] ; then
		error "[ERROR]"
	fi
	
	success "[OK]"
	
	echo -n " > [MongoDB] Create index "
	mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.createIndex({ip_to_index: 1})
exit
EOF
	
	if [ $? -ne 0 ] ; then
		error "[ERROR]"
	fi
	
	success "[OK]"
else
	echo -n " > [MongoDB] Create collection \"ip2location_database_tmp\" and import data "
	mongoimport -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin --drop --db ip2location_database --collection ip2location_database_tmp --type csv --file "$CSV" --fields ip_from,ip_to,country_code,country_name$FIELDS

	if [ $? -ne 0 ] ; then
		error "[ERROR]"
	fi
	
	success "[OK]"
	
	echo -n " > [MongoDB] Create index "
	mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.createIndex({ip_to: 1})
exit
EOF
	
	if [ $? -ne 0 ] ; then
		error "[ERROR]"
	fi
	
	success "[OK]"
fi

echo -n " > [MongoDB] Rename collection \"ip2location_database_tmp\" to \"ip2location_database\" "
mongosh -u mongoAdmin -p "$MONGODB_PASSWORD" --authenticationDatabase admin << EOF
use ip2location_database
db.ip2location_database_tmp.renameCollection("ip2location_database", true)
exit
EOF

if [ $? -ne 0 ] ; then
	error "[ERROR]"
fi

success "[OK]"

rm -rf /_tmp

success "   [UPDATE COMPLETED]"