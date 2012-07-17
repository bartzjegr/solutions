#!/bin/sh
# vFabric ApplicationDirector Sample INSTALL script for vFabric GemFire

# This example uses the values posted below as defaults.   To change any of these
# values, add the Property Name as shown below as individual properties in your 
# service definition in the ApplicationDirector Catalog.   The value specified after
# the Property name is the Type to use for the property (i.e. String, Content, Array etc)
# There are two types of properties for this script: Required and Optional.  Both are 
# listed below.
#
# REQUIRED PROPERTIES:
# These are the properties you must add in order for this sample script to work. The property
# is added when you create your service definition in the ApplicationDirector Catalog.  
# Property Description:                                Property Value settable in blueprint [type]:
# --------------------------------------------------------------------------------------------
# Location of global configuration data                global_conf [Content]
# value: https://${darwin.server.ip}:8443/darwin/conf/darwin_global.conf
#                                                            
# OPTIONAL PROPERTIES:
# Property Description:                                Property Name settable in blueprint:
# --------------------------------------------------------------------------------------------
# which java to use                                    JAVA_HOME [String]
# Installed Location of GemFire                         GEMFIRE_HOME [String]
# GemFire version installed (default is 663)            GEMFIRE_VERSION [String]

# import global configuration data from ApplicationDirector
# . $global_conf

set -e

echo "######################################################################"
echo "#"
echo "# Starting vFabric Gemfire Install Script For Application Director"
echo "#"
echo "######################################################################"

export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
export VMWARE_HOME=/opt/vmware
export GEMFIRE_PACKAGE=vfabric-gemfire
export GEMFIRE_VERSION=${GEMFIRE_VERSION:="663"}
export GEMFIRE_HOME=${GEMFIRE_HOME:="$VMWARE_HOME/$GEMFIRE_PACKAGE/vFabric_GemFire_$GEMFIRE_VERSION"}
export EULA_LOCATION=${EULA_LOCATION:="http://www.vmware.com/download/eula/vfabric_app-platform_eula.html"}

# Any of the following may be set as Properties in your service definition, and if enabled, may be overwritten 
# in your application blueprint.
export JAVA_HOME=${JAVA_HOME:="/usr"}

# pre-set the license agreement for rpm
if [ ! -d "/etc/vmware/vfabric" ]; then
    mkdir -p /etc/vmware/vfabric
fi

echo "Setting Up vFabric Suite 5.1 RPM Repo"
echo "I_ACCEPT_EULA_LOCATED_AT=${EULA_LOCATION}" >> /etc/vmware/vfabric/accept-vfabric-eula.txt
echo "I_ACCEPT_EULA_LOCATED_AT=${EULA_LOCATION}" >> /etc/vmware/vfabric/accept-vfabric5.1-eula.txt

if [ -f /etc/redhat-release ] ; then
    DistroBasedOn='RedHat'
    DIST=`cat /etc/redhat-release |sed s/\ release.*//`
    REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*// | awk -F. '{ print $1 }'`
else
    echo "Installation only supported on RedHat; Exiting installation script"
    exit
fi
# setup repo
if [ -f /bin/rpm ]; then
   if [ "$REV" == "5" ]; then
      echo "Installing vFabric Suite 5.1 EULA"
      rpm --import http://repo.vmware.com/pub/rhel5/vfabric/5.1/RPM-GPG-KEY-VFABRIC-5.1-EL5 --httpproxy proxy.vmware.com --httpport 3128
      rpm -Uvh --force http://repo.vmware.com/pub/rhel5/vfabric/5.1/vfabric-5.1-repo-5.1-1.noarch.rpm --httpproxy proxy.vmware.com --httpport 3128
   elif [ "$REV" == "6" ]; then
      echo "Installing vFabric Suite 5.1 EULA"
      rpm --import http://repo.vmware.com/pub/rhel6/vfabric/5.1/RPM-GPG-KEY-VFABRIC-5.1-EL6
      rpm -Uvh --force http://repo.vmware.com/pub/rhel6/vfabric/5.1/vfabric-5.1-repo-5.1-1.noarch.rpm
   else
      echo "Unsupported RedHat Version: ${REV}; Exiting installation"
      exit
   fi  
else
   echo "RPM utility not available; Exiting installation script"
   exit
fi

if [ "$DistroBasedOn" == "RedHat" ]; then
   if [ "$DIST" == "CentOS" ]; then
      if [ -x /usr/sbin/selinuxenabled ] && /usr/sbin/selinuxenabled; then
         echo 'SELinux is enabled. This may cause installation to fail.'
      fi
   fi  
   if [ -f /usr/bin/yum ]; then
      echo "Installing ${GEMFIRE_PACKAGE}"
      yum -y -v install ${GEMFIRE_PACKAGE} 
   else
      echo "ERROR! Unable to locate yum in ${PATH}; Exiting installer"
      exit
   fi
fi

if [ -f ${GEMFIRE_HOME}/bin/gemfire ]; then
   echo "SUCCESS: ${GEMFIRE_PACKAGE} has been installed in ${GEMFIRE_HOME}"
   echo "Please see https://www.vmware.com/support/pubs/vfabric-gemfire.html for more information"
else
    echo "ERROR! GemFire executable not found in ${GEMFIRE_HOME}; Exiting installer"
    exit
fi

echo "######################################################################"
echo "#"
echo "# vFabric Gemfire Install Script Finished"
echo "#"
echo "######################################################################"
