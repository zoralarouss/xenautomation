#!/bin/bash

set -x

IFS=","

NEW_TEMPLATE_UUID=`xe template-list name-label="Ubuntu Trusty 14.04 (64-bit)-Fixed" params=uuid --minimal`
if [ "$NEW_TEMPLATE_UUID" != "" ]
then
  IFS=","
  for TEM in $NEW_TEMPLATE_UUID
  do
	xe template-param-set other-config:default_template=false uuid=$TEM
	xe template-param-set is-a-template=false uuid=$TEM
	xe vm-destroy uuid=$TEM
  done
fi

TEMPLATE_UUID=`xe template-list name-label="Ubuntu Lucid Lynx 10.04 (64-bit)" params=uuid --minimal`
NEW_TEMPLATE_UUID=`xe vm-clone uuid=$TEMPLATE_UUID new-name-label="Ubuntu Trusty 14.04 (64-bit)-Fixed"`
xe template-param-set other-config:default_template=true other-config:debian-release=trusty uuid=$NEW_TEMPLATE_UUID


VMNAME=ubuntutestvm1
TEMPLATENAME=Ubuntu14.04
MIRROR="http://us.archive.ubuntu.com/ubuntu"
KICKFILE="http://pimpampoum.free.fr/ubu.ks"
VMUUID=`xe vm-list name-label=$VMNAME params=uuid --minimal`
NETNAME="Pool-wide network associated with eth0"
NETUUID=`xe network-list name-label="$NETNAME" params=uuid --minimal`
TEMPLATEUUID=`xe template-list name-label=$TEMPLATENAME params=uuid --minimal`
#TEMPLATESOURCE=`xe template-list name-label="Ubuntu Trusty Tahr 14.04" params=uuid --minimal`
SR=`mount |grep sr-mount |cut -d' ' -f3`

if [ "$VMUUID" != "" ]; then xe vm-uninstall uuid=$VMUUID --force; fi;
if [ "$TEMPLATEUUID" != "" ]; then xe template-uninstall template-uuid=$TEMPLATEUUID --force; fi

TEMPLATEUUID=$(xe vm-clone uuid=`xe template-list name-label="Ubuntu Trusty 14.04 (64-bit)-Fixed" params=uuid --minimal` new-name-label="$TEMPLATENAME")

xe template-param-set uuid=$TEMPLATEUUID other-config:debian-release=trusty
xe template-param-get uuid=$TEMPLATEUUID param-name=other-config
xe template-param-set uuid=$TEMPLATEUUID other-config:disks='<provision><disk device="0" size="35769803776" sr="" bootable="true" type="system"/></provision>'

xe template-param-get uuid=$TEMPLATEUUID param-name=other-config

VMUUID=`xe vm-install template=$TEMPLATENAME new-name-label=$VMNAME`;

xe vif-create vm-uuid=$VMUUID network-uuid=$NETUUID mac=random device=0

xe vm-param-set uuid=$VMUUID other-config:install-repository=$MIRROR

xe vm-memory-limits-set uuid=$VMUUID static-min=1512MiB dynamic-min=1512MiB dynamic-max=3512MiB static-max=3512MiB

#xe vm-param-set platform:cores-per-socket= uuid=$VMUUID
xe vm-param-set platform:cores-per-socket=4 uuid=$VMUUID
xe vm-param-set VCPUs-at-startup=4 uuid=$VMUUID
xe vm-param-set VCPUs-max=4 uuid=$VMUUID

xe vm-param-set uuid=$VMUUID PV-args="--quiet console=hvc0 ks=$KICKFILE netcfg/disable_autoconfig=true netcfg/get_nameservers=8.8.8.8 netcfg/get_ipaddress=192.168.100.145 netcfg/get_netmask=255.255.255.0 netcfg/get_gateway=192.168.100.1 netcfg/confirm_static=true netcfg/get_hostname=localhost netcfg/get_domain=domain"

xe vm-start uuid=$VMUUID



