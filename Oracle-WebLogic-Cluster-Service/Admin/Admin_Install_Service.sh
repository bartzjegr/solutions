#!/bin/bash

export http_proxy=http://proxy.vmware.com:3128
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/vmware/bin:/opt/vmware/bin
export JAVA_HOME=/usr/java/jre-vmware
export PATH=$JAVA_HOME/bin:$PATH

if [ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled; then
    if [ -x /usr/sbin/setenforce ]; then
        /usr/sbin/setenforce Permissive
    else
        echo 'SELinux is enabled.This may cause installation to fail.'
    fi
fi

# SCRIPT INTERNAL PARAMETERS -- START
BEA_HOME="$webLogic_home"
WLS_INSTALL_DIR="$BEA_HOME/WebLogic"
WLSINSTALLERLOCATION="$WLS_INSTALL_DIR/INSTALLER"
WLSINSTALLSCRIPT="$WLSINSTALLERLOCATION/wls_install.sh"
SILENT_XML="$WLSINSTALLERLOCATION/silent.xml"
WEBLOGIC_USER="$user_name"
WEBLOGIC_GROUP="$group_name"
WEBLOGIC_PASSWORD="$admin_password"
ADMIN_SERVER_NAME="$server_name"
ADMIN_HTTP_PORT="$admin_http_port"
ADMIN_SERVER_IP="$admin_ip"
DOMAIN_NAME="$domain_name"
CLUSTER_NUMBER="$cluster_number"
MANAGED_SERVER_HTTP_PORT="$servers_http_port"
MANAGED_SERVER_HTTPS_PORT="$servers_https_port"
MANAGED_SERVER_NUMBER="$managed_server_number"
STANDALONE_MANAGED_SERVRES_NUM="$standalone_managedserver_number"
# NFS_PATH="$nfspath"
#MOUNTPOINTLOCATION="/tmp/mount"
# SCRIPT INTERNAL PARAMETERS -- END

# FUNTION TO CHECK ERROR
PROGNAME=`basename $0`
function Check_error()
{
   if [ ! "$?" = "0" ]; then
      Error_exit "$1";
   fi
}
# FUNCTION TO DISPLAY ERROR AND EXIT
function Error_exit()
{
   echo "${PROGNAME}: ${1:-"UNKNOWN ERROR"}" 1>&2
   exit 1
}
# FUNCTION TO VALIDATE THE INTEGER
function valid_int()
{
   local  data=$1
   if [[ $data =~ ^[0-9]{1,9}$ ]]; then
      return 0;
   else
      return 1
   fi
}

# FUNCTION TO VALIDATE IP ADDRESS
function valid_ip()
{
    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}
# FUNCTION TO VALIDATE NAME STRING
function valid_string()
{
    local  data=$1
    if [[ $data =~ ^[A-Za-z]{1,}[A-Za-z0-9_]{1,}$ ]]; then
       return 0;
    else
       return 1;
    fi
}

# FUNCTION TO VALIDATE PASSWORD
function valid_password()
{
    local  data=$1
    length=${#data}
    if [ $length -le 7 ]; then
        Check_error "PASSWORD MUST BE OF AT LEAST 8 CHARACTERS"
    else
        if [[ $data =~ ^[A-Za-z]{1,}[0-9_@#$%^+=]{1,}[A-Za-z0-9]{2,}$ ]]; then
           return 0;
        else
           return 1;
        fi
    fi
}

# PARAMETER VALIDATION -- START
echo "VALIDATING PARAMETERS..."
if [ "x${BEA_HOME}" = "x" ]; then
    Error_exit "WEBLOGIC HOME NOT SET."
fi
if [ "x${WEBLOGIC_GROUP}" = "x" ]; then
    Error_exit "GROUP NAME NOT SET."
else
   if ! valid_string ${WEBLOGIC_GROUP}; then
      Error_exit "INVALID PARAMETER WEBLOGIC GROUP"
   fi
fi
if [ "x${WEBLOGIC_USER}" = "x" ]; then
    Error_exit "WEBLOGIC USER NAME NOT SET."
else
   if ! valid_string ${WEBLOGIC_USER}; then
      Error_exit "INVALID PARAMETER WEBLOGIC USER"
   fi
fi
if [ "x${WEBLOGIC_PASSWORD}" = "x" ]; then
    Error_exit "WEBLOGIC PASSWORD NOT SET."
else
	if ! valid_password ${WEBLOGIC_PASSWORD}; then
		Error_exit "INVALID PASSWORD"
	fi
fi
if [ "x${ADMIN_SERVER_NAME}" = "x" ]; then
    Error_exit "WEBLOGIC ADMIN SERVER NAME NOT SET."
else
	if ! valid_string ${ADMIN_SERVER_NAME}; then
		Error_exit "INVALID PARAMETER ADMIN SERVER NAME"
	fi
fi
if [ "x${ADMIN_HTTP_PORT}" = "x" ]; then
    Error_exit "WEBLOGIC ADMIN SERVER LISTENING PORT NOT SET."
else
	if ! valid_int ${ADMIN_HTTP_PORT}; then
		Error_exit "INVALID PARAMETER ADMIN HTTP PORT.MUST BE AN INTEGER."
	fi
fi
if [ "x${ADMIN_SERVER_IP}" = "x" ]; then
    Error_exit "WEBLOGIC ADMIN SERVER IP NOT SET."
else
	if ! valid_ip ${ADMIN_SERVER_IP}; then
		Error_exit "INVALID PARAMETER ADMIN SERVER IP"
	fi
fi
# if [ "x${NFS_PATH}" = "x" ]; then 
    # Error_exit "NFS PATH NOT SET."
# fi

if [ "x${DOMAIN_NAME}" = "x" ]; then
    Error_exit "DOMAIN NAME NOT SET."
else
	if ! valid_string ${DOMAIN_NAME}; then
		Error_exit "INVALID PARAMETER DOMAIN NAME"
	fi
fi 
if [ "x${MANAGED_SERVER_HTTP_PORT}" = "x" ]; then
	Error_exit "WEBLOGIC MANAGED SERVER LISTENING PORT NOT SET."
else
	if ! valid_int ${MANAGED_SERVER_HTTP_PORT}; then
		Error_exit "INVALID PARAMETER MANAGED HTTP PORT.MUST BE AN INTEGER."
	fi
fi
if [ "x${MANAGED_SERVER_HTTPS_PORT}" = "x" ]; then
    Error_exit "WEBLOGIC MANAGED SERVER SSL PORT NOT SET.MUST BE AN INTEGER."
else
	if ! valid_int ${MANAGED_SERVER_HTTPS_PORT}; then
		Error_exit "INVALID PARAMETER MANAGED HTTPS PORT.MUST BE AN INTEGER."
	fi
fi          
if [ "x${MANAGED_SERVER_NUMBER}" = "x" ]; then
    Error_exit "WEBLOGIC MANAGED SERVER NUMBER NOT SET."
else
	if ! valid_int ${MANAGED_SERVER_NUMBER}; then
		Error_exit "MANAGED SERVER NUMBER MUST BE AN INTEGER"
	fi
fi
if [ "x${CLUSTER_NUMBER}" = "x" ]; then
    Error_exit "TOTAL CLUSTER NUMBER NOT SET."
else
	if ! valid_int ${CLUSTER_NUMBER}; then
		Error_exit "INVALID CLUSTER NUMBER.NUMBER MUST BE OF INTEGER TYPE"
	fi
	index=1
	TOTAL_CLUSTER=0
	while [ $index -le $CLUSTER_NUMBER ]
	do
		tmp_num=cluster_managedservers_number[index-1]
		if ! valid_int ${!tmp_num}; then
			Error_exit "INVALID CLUSTER INDEX.INDEX MUST BE OF INTEGER TYPE"
		fi
		TOTAL_CLUSTER=`expr $TOTAL_CLUSTER + ${!tmp_num}`
		CLUSTER_INDEX=1
		while [ $CLUSTER_INDEX -le ${!tmp_num} ]
		do
			tmp_ip=cluster_"$index"_ip[CLUSTER_INDEX-1]
			if ! valid_ip ${!tmp_ip}; then
				Error_exit "INVALID CLUSTER IP AT INDEX $CLUSTER_INDEX."
			fi
			CLUSTER_INDEX=`expr $CLUSTER_INDEX + 1`
		done
		index=`expr $index + 1`
	done 
	if [ $TOTAL_CLUSTER -gt  $MANAGED_SERVER_NUMBER ]; then
		Error_exit "ERROR: TOTAL CLUSTER NUMBER MUST BE LESS THAN OR EQUAL TO THE MANAGED SERVERS NUMBER."
	fi
fi
if [ "x${STANDALONE_MANAGED_SERVRES_NUM}" = "x" ]; then
    Error_exit "TOTAL NUMBER OF STANDALONE MANAGED SERVERS NOT SET."
else
	if ! valid_int ${STANDALONE_MANAGED_SERVRES_NUM}; then
		Error_exit "INVALID STANDALONE MANAGED SERVERS NUMBER.NUMBER MUST BE OF INTERGER TYPE"
	fi
	index=1
	while [ $index -le $STANDALONE_MANAGED_SERVRES_NUM ]
	do
		tmp_ms_ip=standalone_"$index"_ip
		if ! valid_ip ${!tmp_ms_ip}; then
			Error_exit "INVALID MANAGED SERVER IP AT INDEX $index."
		fi
		index=`expr $index + 1`
	done
fi 
echo "PARAMTER VALIDATION -- DONE"
# PARAMETER VALIDATION -- END

#BASIC DIRECTORY STRUCTURE
mkdir -p $WLSINSTALLERLOCATION
# mkdir -p $MOUNTPOINTLOCATION
Check_error "ERRORS DURING CREATING BASIC DIRECOTRY STRUCTURE."

# MOUNTING WEBLOGIC INSTALLER -- START
# echo "MOUNTING WEBLOGIC INSTALLER..."
# if [ -f /etc/redhat-release ] ; then
	# DIST=`cat /etc/redhat-release |sed s/\ release.*//`
	# if [ "$DIST" = "CentOS" ] ; then
		# yum --nogpgcheck --noplugins -y install nfs-utils expect
		# /sbin/service portmap start
		# Check_error "ERROR: PORTMAP NOT STARTED"
	# else
		# yum update -y
		# yum --nogpgcheck --noplugins -y install nfs-utils ld-linux.so.2 expect
		# /sbin/service rpcbind start
		# Check_error "ERROR: PORTMAP NOT STARTED"
	# fi
# elif [ -f /etc/debian_version ] ; then
	# DistroBasedOn='Debian'
	# apt-get update -y
	# apt-get -f -y install
	# apt-get -y install nfs-common expect --fix-missing
	# service portmap restart
	# Check_error "ERROR: PORTMAP NOT STARTED"
# else
     # zypper rr repo-oss
     # zypper ar -f http://download.opensuse.org/distribution/11.2/repo/oss/ repo-oss
     # zypper --non-interactive --no-gpg-checks ref
     # zypper --non-interactive --no-gpg-checks install expect
     # /sbin/service rpcbind start
     # Check_error "ERROR: PORTMAP NOT STARTED"
# fi
# echo "RPCBIND CALL DONE... " 

# mount $NFS_PATH $MOUNTPOINTLOCATION
# Check_error "ERRORS DURING MOUNTING WEBLOGIC INSTALLER."

#COPY WEBLOGIC 12C INSTALLER
# cp $MOUNTPOINTLOCATION/webLogicInstaller.bin $WLSINSTALLERLOCATION
# Check_error "ERRORS DURING COPYING WEBLOGIC INSTALLER"
# echo "MOUNTING WEBLOGIC 12C INSTALLER -- DONE"
# MOUNTING WEBLOGIC INSTALLER -- END

echo "COPYING INSTALLER FILES..."
cd $WLSINSTALLERLOCATION
wget http://10.20.140.69:8080/weblogic/webLogicInstaller.bin
wget http://10.20.140.69:8080/weblogic/expect.rpm
wget http://10.20.140.69:8080/weblogic/tcl.rpm
Check_error "ERRORS DURING COPYING WEBLOGIC INSTALLER";

rpm -ivh tcl.rpm
rpm -ivh expect.rpm

# ADDING THE DEDICATED GROUP AND WEBLOGIC USER -- START
echo "ADDING WEBLOGIC USER..."
groupadd $WEBLOGIC_GROUP
useradd -g $WEBLOGIC_GROUP -s /bin/bash -d $BEA_HOME $WEBLOGIC_USER
Check_error "ERRORS DURING SETTING UP WEBLOGIC USER ACCOUNTS.";
echo "ADDING WEBLOGIC USER -- DONE"

cat << EOF > $WLSINSTALLERLOCATION/password.exp
#!/usr/bin/expect
spawn passwd $WEBLOGIC_USER
expect "New password:"
send "$WEBLOGIC_PASSWORD\r"
expect "Retype new password:"
send "$WEBLOGIC_PASSWORD\r"
expect eof
EOF

Check_error "ERROR IN CREATING password.exp FILE";

# CHANGING THE PERMISSION OF THE EXP FILE
chmod 777 $WLSINSTALLERLOCATION/password.exp

# SETTING UP THE PASSWORD FOR WebLogic USER
$WLSINSTALLERLOCATION/password.exp
Check_error "ERROR IN SETTING THE PASSWORD FOR WEBLOGIC USER.";
# ADDING THE DEDICATED GROUP AND WEBLOGIC USER -- END

# INSTALLING WEBLOGIC APPLICATION SERVER -- START
# CREATING SILENT XML FILE
echo "CREATING silent.xml INSTALLATION FILE FOR WEBLOGIC APPLICATION SERVER"
cat <<EOF> $SILENT_XML 
<?xml version="1.0" encoding="UTF-8"?>

<bea-installer> 
  <input-fields> 
    <data-value name="BEAHOME"                     value="$BEA_HOME" /> 
    <data-value name="WLS_INSTALL_DIR"             value="$WLS_INSTALL_DIR"/>
    <data-value name="COMPONENT_PATHS"             value="WebLogic Server|Oracle Enterprise Pack for Eclipse|Oracle Coherence/Coherence Product Files|Oracle Coherence/Coherence Examples"/>
    <data-value name="USE_EXTERNAL_ECLIPSE"        value="false"/>
    <data-value name="EXTERNAL_ECLIPSE_DIR"        value="$WLS_INSTALL_DIR/eclipse/eclipse32" /> 
  </input-fields> 
</bea-installer>
EOF
Check_error "ERROR WHILE CREATING silent.xml FILE"
echo "silent.xml FILE CREATED SUCCESSFULLY"

cat << EOF > $WLSINSTALLSCRIPT
#!/bin/bash
cd $WLSINSTALLERLOCATION
./webLogicInstaller.bin -mode=silent -silent_xml=$SILENT_XML
EOF
Check_error "ERROR WHILE CREATING INSTALLATION FILE"
chown -R $WEBLOGIC_USER:$WEBLOGIC_GROUP $BEA_HOME
chmod -R 775 $BEA_HOME
chmod -R 775 $WLSINSTALLSCRIPT

echo "INSTALLING WEBLOGIC APPLICATION SERVER.."
su - $EBLOGIC_USER -c $WLSINSTALLSCRIPT
Check_error "ERRORS DURING INSTALLING WEBLOGIC APPLICATION SERVER INSTALLER.";
echo "WEBLOGIC APPLICATION SERVER INSTALLED SUCCESSFULLY"
# INSTALLING WEBLOGIC APPLICATION SERVER -- END