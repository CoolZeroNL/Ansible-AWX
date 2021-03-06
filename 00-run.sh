#!/bin/bash
# https://medium.com/swlh/ansible-awx-installation-5861b115455a

# First of all let’s install docker engine and docker-compose from docker repo.

_username=${1:-'admin'}
_password=${2:-'password'}
_enablehtpasswd=${3:-'false'}

# update
yum clean all
yum -y update

## Install epel repo and then install jq
yum install -y epel-release && yum install -y jq

## Install docker-ce related packages
yum install -y yum-utils device-mapper-persistent-data lvm2

## Enable docker-ce repo and install docker engine.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl enable docker && systemctl start docker

## Install latest docker-compose
LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# install
yum groupinstall -y "Development Tools"
yum install -y python-devel

## Install AWX dependencies
yum install -y python2-pip 
pip install ansible
pip install more_itertools==5.0.0
pip install zipp==1.0.0
pip install docker-compose

#############################################################################
# download the latest AWX release tarball to the home directory and extract it.

## Change dir to the home directory.
cd ~

## Get the latest release of ansible awx tarball and extract it. 
LATEST_AWX=$(curl -s https://api.github.com/repos/ansible/awx/tags |egrep name |head -1 |awk '{print $2}' |tr -d '"|,')
curl -L -o ansible-awx-$LATEST_AWX.tar.gz https://github.com/ansible/awx/archive/$LATEST_AWX.tar.gz && \
tar xvfz ansible-awx-$LATEST_AWX.tar.gz && \
rm -f ansible-awx-$LATEST_AWX.tar.gz

## Enter awx folder.  
cd awx-$LATEST_AWX

#############################################################################

## Disable dockerhub reference in order to build local images.
sed -i "s|^dockerhub_base=ansible|#dockerhub_base=ansible|g" installer/inventory

#############################################################################

## Create a folder in /opt/ to hold awx psql data
mkdir -p /opt/awx-psql-data

## Provide psql data path to installer.
sed -i "s|^postgres_data_dir.*|postgres_data_dir=/opt/awx-psql-data|g" installer/inventory

#############################################################################

## Create awx-ssl folder in /etc.
mkdir -p /etc/awx-ssl/

## Make a self-signed ssl certificate
openssl req -subj '/CN=secops.tech/O=Secops Tech/C=TR' \
	-new -newkey rsa:2048 \
	-sha256 -days 1365 \
	-nodes -x509 \
	-keyout /etc/awx-ssl/awx.key \
	-out /etc/awx-ssl//awx.crt

## Merge awx.key and awx.crt files
cat /etc/awx-ssl/awx.key /etc/awx-ssl/awx.crt > /etc/awx-ssl/awx-bundled-key.crt

## Pass the full path of awx-bundled-key.crt file to ssl_certificate variable in inventory.
sed -i -E "s|^#([[:space:]]?)ssl_certificate=|ssl_certificate=/etc/awx-ssl/awx-bundled-key.crt|g" installer/inventory

#############################################################################

## Change dir to where awx main folder is placed:
cd ~

## Download and extract awx-logos repository. 
## (We could use git to clone the repo; but it requires git to be installed on the host.)
curl -L -o awx-logos.tar.gz https://github.com/ansible/awx-logos/archive/master.tar.gz
tar xvfz awx-logos.tar.gz

## Rename awx-logos-master folder as awx-logos  
mv awx-logos-master awx-logos

## Remove tarball
rm -f *awx*.tar.gz

#############################################################################

## Change dir to awx and replace awx_official parameter
# cd ~/awx-6.1.0
cd ~/awx-$LATEST_AWX
sed -i -E "s|^#([[:space:]]?)awx_official=false|awx_official=true|g" installer/inventory

#############################################################################

## Define the default admin username
sed -i "s|^admin_user=.*|admin_user="$_username"|g" installer/inventory

## Set a password for the admin
sed -i "s|^admin_password=.*|admin_password="$_password"|g" installer/inventory

#############################################################################

# Installation
## Enter the installer directory.
# cd ~/awx-6.1.0/installer
cd ~/awx-$LATEST_AWX/installer

#############################################################################

if [ "$_enablehtpasswd" = true ] ; then

	## EDIT (Add Basic Auth)
	yum install -y httpd-tools

	htpasswd -b -c /root/.awx/awxcompose/.htpasswd $_username $_password

	# add .htaccess to the Web: volumes container..
	sed -i -e '1,/volumes:/{/volumes:/a \     \ - "{{ docker_compose_dir }}/.htpasswd:/etc/nginx/.htpasswd" ' -e '}' /root/awx-$LATEST_AWX/installer/roles/local_docker/templates/docker-compose.yml.j2

	# Add code for Basic Auth into nginx.conf
	sed -i '/listen 8053 ssl;.*/a \       \ auth_basic "Restricted Content";' /root/awx-$LATEST_AWX/installer/roles/local_docker/templates/nginx.conf.j2
	sed -i '/auth_basic "Restricted Content";.*/a \       \ auth_basic_user_file /etc/nginx/.htpasswd;' /root/awx-$LATEST_AWX/installer/roles/local_docker/templates/nginx.conf.j2

fi

#############################################################################

## Initiate install.yml
ansible-playbook -i inventory install.yml

#############################################################################

systemctl stop firewalld

echo "Done..."
echo ""
echo "Username: "$_username
echo "Password: "$_password

