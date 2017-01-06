#!/bin/bash
set -eux

HTTP_PROXY=$http_proxy_val
HTTPS_PROXY=$https_proxy_val

if [ "$HTTP_PROXY" != "None" ]
then
	export http_proxy=$HTTP_PROXY
	echo "Setting http_proxy var: $http_proxy"
fi

if [ "$HTTPS_PROXY" != "None" ]
then
	export https_proxy=$HTTPS_PROXY
	echo "Setting https_proxy var: $https_proxy"
fi

curl -L -O https://repos.fedorapeople.org/repos/openstack/openstack-liberty/rdo-release-liberty.rpm
yum -y install rdo-release-liberty.rpm
#yum -y update
yum -y install python-zaqarclient python-oslo-log python-psutil os-collect-config os-apply-config os-refresh-config dib-utils
