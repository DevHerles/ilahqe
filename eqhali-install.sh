#!/bin/bash
################################################################################
# Script for installing Odoo V10 on Ubuntu 18.04, 16.04, 15.04, 14.04 (could be used for other version too)
# Author: Herles Incalla Chuquija
# Email: herles.incalla@gmail.com
#-------------------------------------------------------------------------------
# Make a new file:
# vim eqhali-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x eqhali-install.sh
# Execute the script to install Odoo+EQHALI:
# ./eqhali-install
################################################################################
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;36m"
NORMAL="\033[0m"

#odoo
ODOO_USER=$USER
ODOO_LOG=/var/log/odoo
ODOO_HOME=/opt/odoo
MINSA_HOME=/opt/minsa
JASPER=/opt/jasper
JASPERREPORT_PATH=jasperreports-server-cp-5.6.0
JASPER_HOME=$JASPER/$JASPERREPORT_PATH
JASPERSERVER_INSTALLER=jasperserver-installer.run
EQHALI=$MINSA_HOME/eqhali
EQHALI_PASSWORD="Hospital2018"
ODOO_PASSWORD=NJ^SH-jG4=vpFc-PL6Ch
INSTALL_WKHTMLTOPDF="True"
ODOO_SERVER=odoo-server
clear
cat << "HELLO_TEXT"
BIENVENIDO AL INSTALADOR DE EQHALI...
HELLO_TEXT

printf "\n${GREEN}ODOO=${RED}%s${NORMAL}" $ODOO_HOME
printf "\n${GREEN}EQHALI=${RED}%s${NORMAL}" $MINSA_HOME
printf "\n${GREEN}USUARIO=${RED}%s${NORMAL}\n\n\n" $ODOO_USER

sleep 3
clear
#echo "${NORMAL}"

if [ -d "$EQHALI" ]; then
  printf "${RED}%s${NORMAL}\n" "You already have $EQHALI directory."
  printf "${RED}%s${NORMAL}\n" "You have to remove $EQHALI if you want to re-install."
fi
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=https://downloads.wkhtmltopdf.org/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb
JASPERSERVER=ftp://ftp.minsa.gob.pe/sismed/SISMEDV2.0/Archivosx/jasperreports-server-cp-5.6.0-linux-x64-installer.run
#--------------------------------------------------
# Update Server
#--------------------------------------------------
printf "\n${RED}%s${NORMAL}\n" "Do you wish to Update Server?"
select yn in "Yes" "No"; do
    case $yn in
        Yes )
		sudo dpkg-reconfigure locales && apt-get update && sudo apt-get upgrade -y; break;;
        No ) break;;
    esac
done

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
printf "\n${RED}%s${NORMAL}\n" "Do you wish to Install PostgreSQL Server?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) sudo apt-get install postgresql -y; break;;
        No ) break;;
    esac
done

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $ODOO_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
printf "\n${RED}%s${NORMAL}\n" "Do you wish to Install python packages?"
select yn in "Yes" "No"; do
    case $yn in
	Yes ) 
		echo -e "\n---- Install tool packages ----"
		sudo apt-get install wget git python-pip gdebi-core -y

		echo -e "\n---- Install python packages ----";
		sudo apt-get install postgresql-contrib postgresql-plpython python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y python-suds

		echo -e "\n---- Install python libraries ----"
		sudo pip install gdata psycogreen ofxparse XlsxWriter xlrd pyPdf 
		sudo pip install --upgrade pip
		sudo pip install httplib2
		sudo pip install pyPdf
		sudo pip install jr_tools

		echo -e "\n--- Install other required packages"
		sudo apt-get install node-clean-css -y
		sudo apt-get install node-less -y
		sudo apt-get install python-gevent -y
		break;;
	No ) break;;
    esac
done

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF == "True" ]; then
	printf "\n${RED}%s${NORMAL}\n" "Do you wish to install wkhtml?"
	select yn in "Yes" "No"; do
		case $yn in
			Yes )
				echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 10 ----"
				#pick up correct one from x64 & x32 versions:
				if [ "`getconf LONG_BIT`" == "64" ]; then
				    _url=$WKHTMLTOX_X64
				else
				    _url=$WKHTMLTOX_X32
				fi
				sudo wget $_url
				sudo gdebi --n `basename $_url`
				sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
				sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
				break;;
			No ) break;;
		esac
	done
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

cat /etc/passwd | grep $ODOO_USER >/dev/null 2>&1
if [ $? -eq 0 ]; then
	printf "\n${GREEN}%s${NORMAL}" "User $ODOO_USER exists..."
else
	echo -e "\n---- Create ODOO system user ----"
	sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_HOME --gecos 'ODOO' --group $ODOO_USER
	#The user should also be added to the sudo'ers group.
	sudo adduser $ODOO_USER sudo
	echo -e "$ODOO_PASSWORD\n$ODOO_PASSWORD" | sudo passwd $ODOO_USER
fi
echo -e "\n---- Create Log directory ----"

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
MINSA_ADDONS_PATH=$MINSA_HOME/eqhali/addons
MINSA_ADDONS=$MINSA_ADDONS_PATH,$MINSA_ADDONS_PATH/hcesg_segundo_nivel,$MINSA_ADDONS_PATH/odoo-share,$MINSA_ADDONS_PATH/gestion_rrhh,$MINSA_ADDONS_PATH/oehealth_all_in_one_10,$MINSA_ADDONS_PATH/odoo_catalogos,$MINSA_ADDONS_PATH/jasperserver

create_jasperserver_service(){
printf "${GREEN}%s${NORMAL}\n" "Creating jasperserver ..."
cat <<EOF > ~/jasperserver
#!/bin/sh
#
# Start/Stop of JasperReports Server
#

JASPER_USER=$USER

case "$1" in 
  start) 
    if [ -f $JASPER_HOME/ctlscript.sh ]; then 
      echo "Starting JasperServer" 
      su $JASPER_USER -c "$JASPER_HOME/ctlscript.sh start" 
    fi 
    ;; 
  stop) 
    if [ -f $JASPER_HOME/ctlscript.sh ]; then 
      echo "Stopping JasperServer" 
      su $JASPER_USER -c "$JASPER_HOME/ctlscript.sh stop" 
    fi 
    ;; 
  restart) 
    if [ -f $JASPER_HOME/ctlscript.sh ]; then 
      echo "Restarting JasperServer" 
      su $JASPER_USER -c "$JASPER_HOME/ctlscript.sh restart" 
    fi 
    ;; 
  status) 
    if [ -f $JASPER_HOME/ctlscript.sh ]; then 
      su $JASPER_USER -c "$JASPER_HOME/ctlscript.sh status" 
    fi 
    ;; 
  *) 
    echo $"Usage: ./jasperserver {start|stop|restart|status}" 
    exit 1 
    ;; 
esac
EOF


echo -e "* Creating jasperserver service file..."
cat <<EOF > ~/jasperserver.service
[Unit]
Description=JasperServer
After=network.target

[Service]
Type=simple
PermissionsStartOnly=true
SyslogIdentifier=jasperserver
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$JASPER_HOME/ctlscript
WorkingDirectory=$JASPER_HOME

[Install]
WantedBy=multi-user.target
EOF
}

install_jasper_server(){
	printf "${GREEN}%s${NORMAL}\n" "Creating jasperserver home path..."
	sudo mkdir -p $JASPER_HOME
	sudo chown $USER:$USER $JASPER_HOME
	cd $JASPER_HOME
	printf "${GREEN}%s${NORMAL}\n" "Dowloading jasperserver..."
	sudo wget -cO - $JASPERSERVER > $JASPERSERVER_INSTALLER 
	chmod +x $JASPERSERVER_INSTALLER
	printf "${GREEN}%s${NORMAL}\n" "Installing jasperserver..."
	sudo ./$JASPERSERVER_INSTALLER
	create_jasperserver_service
	printf "${GREEN}%s${NORMAL}\n" "Installing jasperserver service ..."
	sudo mv ~/jasperserver /etc/init.d
	sudo chmod 744 /etc/init.d/jasperserver
	sudo chown root:root /etc/init.d/jasperserver
	printf "${GREEN}%s${NORMAL}\n" "Starting jasperserver ..."
	cd /opt/$JASPERREPORT_PATH
	sudo ./ctlscript.sh start
	#sudo service jasperserver start
	#sudo service jasperserver status
	sudo rm -rf /opt/jasper
}
install_odoo_server(){
	echo -e "\n---- Install python packages ----";
	echo -e "\n==== Installing ODOO Server ===="
	sudo git clone --depth 1 --branch 10.0 https://www.github.com/odoo/odoo $ODOO_HOME
	echo -e "\n---- Create custom module directory ----"
	sudo mkdir -p $MINSA_ADDONS_PATH
	echo -e "\n---- Setting permissions on home folder ----"
	sudo chown -R $ODOO_USER:$ODOO_USER $MINSA_ADDONS_PATH
}

printf "${RED}%s${NORMAL}\n" "Do you wish to install Jasperserver"
select yn in "Yes" "No"; do
case $yn in
Yes )
if [ -d "/opt/$JASPERREPORT_PATH" ]; then
	printf "${RED}%s${NORMAL}\n" "Do you wish to re-install Jasperserver"
	select yn in "Yes" "No"; do
		case $yn in
			Yes )
				cd /opt/$JASPERREPORT_PATH
				if [ -f uninstall ]; then
					sudo ./uninstall
				fi
				install_jasper_server
				break;;
			No ) break;;
		esac
	done
else
	install_jasper_server
fi
break;;
No ) break;;
esac
done

if [ -d "$ODOO_HOME" ]; then
	printf "${RED}%s${NORMAL}\n" "Do you wish to Reinstall Odoo Server?"
	select yn in "Yes" "No"; do
	    case $yn in
		Yes ) 
			sudo rm -rf $ODOO_HOME
			install_odoo_server
			break;;
		No ) break;;
	    esac
	done
else
	install_odoo_server
fi

echo -e "* Setting up server config file..."
cat <<EOF > ~/$ODOO_SERVER.conf
[options]
addons_path = $ODOO_HOME/addons,$MINSA_ADDONS
admin_passwd = W*4y+bN39ZR(-W9/U-Q
csv_internal_sep = ,
data_dir = $MINSA_HOME/.local/share/odoo
db_host = False
db_maxconn = 64
db_name = False
;db_password = $ODOO_PASSWORD
db_port = 5432
db_template = template1
db_user = $ODOO_USER
dbfilter = .*
demo = {}
email_from = False
geoip_database = /usr/share/GeoIP/GeoLiteCity.dat
import_partial =
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
limit_time_real_cron = -1
list_db = True
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = $ODOO_LOG/$ODOO_SERVER.log
logrotate = False
longpolling_port = 8072
max_cron_threads = 2
osv_memory_age_limit = 1.0
osv_memory_count_limit = False
pg_path = None
pidfile = None
proxy_mode = False
reportgz = False
server_wide_modules = web,web_kanban
smtp_password = False
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
smtp_user = False
syslog = False
test_commit = False
test_enable = False
test_file = False
test_report_directory = False
translate_modules = ['all']
unaccent = False
without_demo = False
workers = 0
xmlrpc = True
xmlrpc_interface =
EOF

REPO_MPI_CLIENTE="git+https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/mpi-client.git@develop#egg=mpi_client"
REPO_ODOO_SHARE="https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/odoo-share.git -b develop"
REPO_GESTION_RRHH="https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/gestion_rrhh.git -b develop"
REPO_HCESG_SEGUNDO_NIVEL="https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/hcesg_segundo_nivel.git -b develop"
REPO_OEHEALTH_ALL_IN_ONE_10="https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/oehealth_all_in_one_10.git"
REPO_ODOO_CATALOGOS="https://eqhaliminsa:$EQHALI_PASSWORD@git.minsa.gob.pe/oidt/odoo_catalogos.git -b catalogo_medicamentos"
REPO_JASPER_SERVER="https://github.com/DevHerles/jasperserver.git -b 10.0"

clone_eqhali_addons() {
	sudo mkdir -p $MINSA_ADDONS_PATH
	
	echo -e "\n---- Create Log directory ----"
	sudo mkdir $ODOO_LOG
	sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_LOG
	
	sudo chown -R $ODOO_USER:$ODOO_USER $MINSA_HOME

	cd $MINSA_ADDONS_PATH

	echo -e "\n---- Cloning modules... ----";
	printf "${BLUE}%s${NORMAL}\n" "Cloning mpi-cliente from ${REPO_MPI_CLIENTE}"
	pip install -U ${REPO_MPI_CLIENTE} --user

	printf "${BLUE}%s${NORMAL}\n" "Cloning odoo-share from ${REPO_ODOO_SHARE}"
	git clone ${REPO_ODOO_SHARE}

	printf "${BLUE}%s${NORMAL}\n" "Cloning gestion_rrhh from ${REPO_GESTION_RRHH}"
	git clone ${REPO_GESTION_RRHH}

	printf "${BLUE}%s${NORMAL}\n" "Cloning hcesg_segundo_nivel from ${REPO_HCESG_SEGUNDO_NIVEL}"
	git clone ${REPO_HCESG_SEGUNDO_NIVEL}

	printf "${BLUE}%s${NORMAL}\n" "Cloning oehealth_all_in_on from ${REPO_OEHEALTH_ALL_IN_ONE_10}"
	git clone ${REPO_OEHEALTH_ALL_IN_ONE_10}

	printf "${BLUE}%s${NORMAL}\n" "Cloning odoo_catalogos from ${REPO_ODOO_CATALOGOS}"
	git clone ${REPO_ODOO_CATALOGOS}

	printf "${BLUE}%s${NORMAL}\n" "Cloning jasper_server from ${REPO_JASPER_SERVER}"
	git clone ${REPO_JASPER_SERVER}
}

if [ -d "$MINSA_HOME/eqhali" ]; then
printf "\n${RED}%s${NORMAL}\n" "Do you wish to reclone EQHALI addons?"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) 	
			sudo rm -rf $MINSA_HOME/eqhali
			sudo rm /etc/$ODOO_SERVER.conf
			sudo rm -rf $ODOO_LOG
			clone_eqhali_addons
			break;;
		No )	break;;
	esac
done
else
	clone_eqhali_addons
fi
sudo mv ~/$ODOO_SERVER.conf /etc/$ODOO_SERVER.conf
sudo chown $ODOO_USER:$ODOO_USER /etc/$ODOO_SERVER.conf
sudo chown -R $ODOO_USER:$ODOO_USER $MINSA_HOME 

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------
SYSTEM_DAEMON_PATH=/lib/systemd/system
ODOO_SERVER_SERVICE=$ODOO_SERVER.service

ODOO_DAEMON=$ODOO_HOME/odoo-bin
EQHALI_CONFIGFILE="/etc/$ODOO_SERVER.conf"

echo -e "* Create init file"
cat <<EOF > ~/${ODOO_SERVER_SERVICE}
[Unit]
Description=Odoo Open Source ERP and CRM
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
PermissionsStartOnly=true
SyslogIdentifier=$ODOO_SERVER
User=$ODOO_USER
Group=$ODOO_USER
ExecStart=$ODOO_DAEMON --config=$EQHALI_CONFIGFILE
WorkingDirectory=$ODOO_HOME
;StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

echo -e "* Create PosgreSQL config file"
POSTGRESQL_CONF=pg_hba.conf
cat <<EOF > ~/pg_hba.conf
#Generated from EQHALI v0.0.1
local	all		postgres				trust
local	all		all					trust
host	all		all		127.0.0.1/32		trust
host	all		all		::1/128			trust
local	replication	all					trust
host	replication	all		127.0.0.1/32		trust
host	all		all		0.0.0.0/0		trust
host	replication	all		::1/128			trust
EOF

sudo mv ~/$POSTGRESQL_CONF /etc/postgresql/10/main/

echo -e "* Security Init File"
sudo mv ~/$ODOO_SERVER_SERVICE $SYSTEM_DAEMON_PATH
sudo chmod 755 $SYSTEM_DAEMON_PATH/$ODOO_SERVER_SERVICE
sudo chown $ODOO_USER:$ODOO_USER $SYSTEM_DAEMON_PATH/$ODOO_DAEMON_SERVICE
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME
sudo chown -R $ODOO_USER:$ODOO_USER $MINSA_HOME

sudo chmod 755 /lib/systemd/system/$ODOO_SERVER_SERVICE
sudo chown $ODOO_USER:$ODOO_USER /lib/systemd/system/$ODOO_SERVER_SERVICE
sudo chown $ODOO_USER:$ODOO_USER $ODOO_LOG

sudo systemctl daemon-reload
sudo systemctl enable $ODOO_SERVER_SERVICE 
sudo systemctl enable $JASPER_SERVER_SERVICE 

export JASPER_URL=http://localhost:8080/jasperserver
export JASPER_USERNAME=jasperadmin
export JASPER_PASSWORD=jasperadmin

cd $MINSA_ADDONS_PATH/hcesg_segundo_nivel/ && jr_tools load jasper.yml && cd ~

echo -e "* Starting $ODOO_SERVER..."
sudo systemctl start $ODOO_SERVER
sudo systemctl enable $ODOO_SERVER_SERVICE
sudo service $ODOO_SERVER status
printf "\n\n\n${GREEN}%s${NORMAL}\n" "La instalación ha finalizado correctamente."
