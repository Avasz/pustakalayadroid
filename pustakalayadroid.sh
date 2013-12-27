#!/bin/bash
mysql_password="olenepal"
sqlmy="mysql -u root -p$mysql_password"
echo "Updating package database...."
sleep 2
apt-get update 

echo "Installing Java packages......"
sleep 1
apt-get -y install openjdk-6-jre openjdk-6-jdk
sleep 2


#Changing mirror to that of precise for older version of php5

cp /etc/apt/sources.list /etc/apt/source.list.raring
sed -i "s/raring/precise/g" /etc/apt/sources.list.d/*.list

mkdir /etc/apt/sources.list.d/bkup
cp /etc/apt/sources.list.d/* /etc/apt/sources.list.d/bkup
sed -i "s/raring/precise/g" /etc/apt/sources.list.d/*.list
apt-get update
#apt-get -y install debconf #done, not needed.
echo "Installing LAMP packages"
echo "Give your desired mysql root password, press enter for default, (olenepal):"
read mysql_password

#Checking if the given input is empty or not. If not it will assign the given input as password for mysql root user else it will use the default password.

if [ -z "$mysql_password" ]
then
        mysql_password="olenepal"
else
        mysql_password=$mysql_password
fi

sleep 2
echo "mysql-server-5.5 mysql-server/root_password password $mysql_password" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_password" | debconf-set-selections
apt-get -y install mysql-client mysql-server libmysql-java libimage-exiftool-perl apache2 php5 php5-mysql php-pear php-xml-htmlsax3 php-xml-parser php5-curl php5-gd php5-mcrypt 
echo "Done installing LAMP packages"
clear
sleep 2

echo "Installing links and vim"
apt-get -y install links
clear
echo "Done installing links and vim"
sleep 1

wget -O /etc/profile.d/fedora-profile.sh https://gist.github.com/Avasz/7576577/raw/08bbed9fadde300cb0364accb0201d0eea24bed2/fedora-profile.sh
chmod 755 /etc/profile.d/fedora-profile.sh
sh /etc/profile.d/fedora-profile.sh
source /etc/profile.d/fedora-profile.sh

/etc/init.d/mysql start
clear
echo "Enter the root password & Answer \'n\' to all the questions that follows."
mysql_secure_installation

echo "Creating mysql database for fez...."
sleep 2

echo "Insert the nexc disk in the odroid, and press any key when ready...."
read
mount /dev/sda1 /mnt/

$sqlmy -e "CREATE DATABASE fezonline default character set utf8"
$sqlmy -e "GRANT ALL ON fezonline.* TO fezuser@localhost identified by 'FezSucks2012'"
$sqlmy -e "flush privileges"
$sqlmy fezonline < /mnt/nexc-fezonline.sql

$sqlmy -e "CREATE DATABASE fedora22 default character set utf8"
$sqlmy -e "GRANT ALL ON fedora22.* TO fedoraAdmin@localhost identified by 'FedoraSucks2012'"
$sqlmy -e "flush privileges"

cd /root/   
echo "Obtaining fedora 2.2.1 installer..."
sleep 2
wget http://dev.olenepal.org/Uploads/fedora-2.2.1-installer.jar
echo "The setup will now install fedora\-2.2.1, go to this link https://gist.github.com/Avasz/7594701 to see the answers to the questions it will ask. Press the return key when you are ready."
read
java -jar *.jar


echo "Configuring fedora server...."
wget -O /var/opt/fedora/server/config/fedora.fcfg https://gist.github.com/Avasz/7576556/raw/0e88cc75fa90d8ad4b27bfc5d9bef4380ce8fd6d/fedora.fcfg 

echo "Configuring tomcat servlet engine...."
wget -O /var/opt/fedora/tomcat/conf/server.xml https://gist.github.com/Avasz/7576547/raw/d66e7ddc09a5bd2ec6434d838e09b7893c21c32c/server.xml

echo "Setting fedora as service...."
wget -O /etc/init.d/fedora https://gist.github.com/Avasz/7576562/raw/77944de537aed401c89d31561cc8d0ebcc14e3d0/fedora
chmod 755 /etc/init.d/fedora
/etc/init.d/fedora start
ln -s /etc/init.d/fedora /etc/rc2.d/S99fedora 


mkdir -p /var/www/ && cd $_
cp /mnt/nexc-fez.tar .
tar -xvf nexc-fez.tar
rm -rf nexc-fez.tar
cp -Rv /mnt/nexc-fedora/* /var/opt/fedora/data/



echo "Configuring webserver apache and starting it...."
sleep 1
wget -O /etc/apache2/sites-available/default https://gist.github.com/Avasz/7576835/raw/8ab54c00930ab6489eafea819f4ff71b35711ff4/default
/etc/init.d/apache2 start
sleep 1

echo "Creating pustakalaya and dictionary databases..."
sleep 1
$sqlmy -e "CREATE DATABASE pustakalayaonline default character set utf8"
$sqlmy -e "GRANT ALL ON pustakalayaonline.* TO pustAdmin@localhost identified by 'pustAdminServer'"
$sqlmy -e "flush privileges"
$sqlmy -e "CREATE DATABASE np_dictionary_dbuni default character set utf8"
$sqlmy -e "GRANT ALL ON np_dictionary_dbuni.* TO sabdaadmin@localhost identified by 'sabdaadmin'"
$sqlmy -e "flush privileges"
echo "Done creating Pustakalaya & Dictionary databases."
sleep 2

echo "Copying required files from Disk to /var/www/fez..."
cp /mnt/nexc-sabdakosh.tar /var/www/fez
tar -xvf /var/www/fez/nexc-sabdakosh.tar
clear

echo "Importing corresponding databases...Press any key when ready...."
read
$sqlmy fedora22 < /mnt/nexc-fedora.sql
$sqlmy np_dictionary_dbuni < /mnt/nexc-np_dictionary_dbuni.sql
$sqlmy pustakalayaonline < /mnt/nexc-pustakalayaonline.sql
sleep 2
clear

echo "Setting fez for application url..."
$sqlmy -e "use fezonline"
$sqlmy fezonline -e "select * from fez_config"
$sqlmy fezonline -e "update fez_config set config_value='http://epustakalaya/fez/' where config_name='app_url'"
$sqlmy fezonline -e "update fez_config set config_value='epustakalaya' where config_name='app_hostname'"

chown -R www-data:www-data /var/www/fez/

echo epustakalaya > /etc/hostname
hostname epustakalaya

wget -O /etc/mysql/my.cnf https://gist.github.com/Avasz/8144562/raw/9dced13d1e57c3f7feda30d353a30ce70511e036/my.cnf
/etc/init.d/apache2 restart
/etc/init.d/mysql restart
/etc/init.d/fedora restart
reboot





