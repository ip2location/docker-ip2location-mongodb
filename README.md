docker-ip2location-mongodb
==========================

This is a pre-configured, ready-to-run MongoDB server with IP2Location Geolocation database setup scripts. It simplifies the development team to install and set up the IP2Location geolocation database in MongoDB server. The setup script supports the [commercial database packages](https://www.ip2location.com) and [free LITE package](https://lite.ip2location.com). Please register for a free or commercial account before running this image, as it requires a download token during the setup process.

This docker image supports the IP2Location (DB1 to DB25) database.


### Usage

1. Run this image as daemon using the download token and product code from [IP2Location LITE](https://lite.ip2location.com) or [IP2Location](https://www.ip2location.com).

```bash
docker run --name ip2location -d -e TOKEN={DOWNLOAD_TOKEN} -e CODE={DOWNLOAD_CODE} -e MONGODB_PASSWORD={MONGODB_PASSWORD} ip2location/mongodb
```

    **ENV VARIABLE**

    TOKEN – Download token obtained from IP2Location.
    CODE – The CSV file download code. You may get the download code from your account panel.

    MONGODB_PASSWORD - Password for MongoDB admin.

2. The installation may take seconds to minutes depending on your database sizes, downloading speed and hardware specs. You may check the installation status by viewing the container logs. Run the below command to check the container log:

```bash
docker logs -f ip2location
```

    You should see the line `=> Setup completed` if you have successfully completed the installation.


### To create a test container

1. Download Debian Docker image.

```bash
sudo docker pull debian
```

2. Start the container in interactive mode.

```bash
sudo docker run --name debian-test -it debian bin/bash
```

3. Press Ctrl+P then Ctrl+Q to detach from the container. Please do not type the **exit** command as it will shut down the container, as we still need the container to be up and running for the testing.


### To create a network bridge to allow both containers to communicate

1. Create the network bridge.

```bash
sudo docker network create simple-network
```

2. Connect both containers to the same network using the below command.

```bash
sudo docker network connect simple-network ip2location
sudo docker network connect simple-network debian-test
```


### Query for IP information

1. Go back to the debian-test container.

```bash
sudo docker attach debian-test
```

2. Install MongoDB and Mongo Shell first by following the installation steps in https://docs.mongodb.com/manual/tutorial/install-mongodb-on-debian/.

3. Run the Mongo Shell with the password you've specified during the installation.

```bash
mongosh --host ip2location -u mongoAdmin -p {MONGODB_PASSWORD} --authenticationDatabase admin
```

4. To test the IPv4 database, key in the commands below to query geolocation info for IPv4 address 8.8.8.8 (IP number: 134744072).

```
use ip2location_database
db.ip2location_database.findOne( { ip_to: { $gte: 134744072 } } )
```

5. To test the IPv6 database, key in the commands below to query geolocation info for IPv6 address 2001:4860:4860::8888 (IP number: 42541956123769884636017138956568135816).

```
use ip2location_database
db.ip2location_database.findOne( { ip_to_index: { $gte: "A0042541956123769884636017138956568135816" } } )
```

If you don't know how to convert an IP address to IP number, please see [IP2Location FAQs](https://www.ip2location.com/faqs#technical).

**NOTES**: The search param for IPv4 database is a number BUT the param for IPv6 database is a string of the IP number left-padded with zeroes till 40 characters and prefixed with an "A".
Also, IPv6 database is filtering on the ip_to_index field while IPv4 database is filtering on the ip_to field.
When querying IPv4 address using the IPv6 database, you need to convert the IPv4 address into [IPv4-mapped IPv6 address](https://blog.ip2location.com/knowledge-base/ipv4-mapped-ipv6-address/) before converting to IP number.


### Update IP2Location Database

To update your IP2Location database to latest version, please run the following  command:

```bash
docker exec -it ip2location ./update.sh
```


### Articles and Tutorials

You can visit the below link for more information about this docker image:
[IP2Location Articles and Tutorials](https://blog.ip2location.com)
