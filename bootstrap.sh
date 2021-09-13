#!/usr/bin/env bash

SCRIPT_LOCATION=$(readlink -f "$0")
SCRIPT_PATH=$(dirname ${SCRIPT_LOCATION})
PROJECT_PATH="${PROJECT_PATH:-$SCRIPT_PATH}"
NGINX_VERSION=1.21.3
NGINX_RTMP_MODULE_VERSION=dev
NGINX_PATH=/usr/sbin/nginx                              # Make sure to change the init file too

echo "Script location: ${SCRIPT_LOCATION}"
echo "Project path: ${PROJECT_PATH}"
echo "Nginx version: ${NGINX_VERSION}"
echo "Nginx RTPM module version: ${NGINX_RTMP_MODULE_VERSION}"
echo "Nginx path: ${NGINX_PATH}"

sudo apt-get install software-properties-common
# Check that Nginx is not already installed
if [ ! -e $NGINX_PATH ]; then
    echo "Nginx server doesn't exist yet."
    
    # Make sure the new APT repository is taken into account
    apt-get update
    
    # Install requirements
    apt-get install -y build-essential libpcre3 libpcre3-dev openssl libssl-dev unzip libaio1 ffmpeg
    
    # Download Nginx server
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
    
    # Unzip the downloaded tarball
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz
    
    # Download Nginx's RTMP module used for live broadcasting
    
    wget https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/refs/heads/dev.zip
    # Unzip the zip file
    unzip ${NGINX_RTMP_MODULE_VERSION}.zip
    cd nginx-rtmp-module-dev
    find ./ -type f -exec sed -i 's/rtmp/pogi/g' {} \;
    mmv '*rtmp*' '#1pogi#2'
    cd ..
    
    # Build Nginx with the RTMP module included
    cd nginx-${NGINX_VERSION}
    ./configure --without-http_gzip_module --with-http_ssl_module --add-module=../nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}
    make
    make install
    cd ..

    # Remove downloaded archives


    # Remove folder used to build Nginx


    # Create a symlink to use Nginx as a command
    ln -fs /usr/local/nginx/sbin/nginx $NGINX_PATH

    # Create symlinks for Nginx config files
    rm -rf /usr/local/nginx/html
    ln -fs ${PROJECT_PATH}/nginx/html /usr/local/nginx/
    ln -fs ${PROJECT_PATH}/nginx/conf/nginx.conf /usr/local/nginx/conf

    # Make sure Nginx HTML files will be readable online
    chmod 755 ${PROJECT_PATH}/nginx/html/*

    # Create new aliases
    echo "alias gonginx='cd /usr/local/nginx'" >> ~/.bashrc

    # Copy Nginx scripts
    cp -rf ${PROJECT_PATH}/nginx/script/ /usr/local/nginx

    # Copy Nginx script to launch Nginx at startup
    cp -f ${PROJECT_PATH}/nginx/init/nginx /etc/init.d/
    
    # Make sure that the script uses Unix line endings
    sed -i 's/\r//' /etc/init.d/nginx
    sed -i 's/\r//' /usr/local/nginx/script/restart.sh

    # Make sure the scripts can be executed 
    chmod +x /etc/init.d/nginx
    chmod +x /usr/local/nginx/script/restart.sh
    
    update-rc.d nginx defaults
fi

/etc/init.d/nginx start
