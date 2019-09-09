#!/bin/bash
set -e

### Configuration ###

APP_DIR=/var/www/myapp
GIT_URL=https://github.com/BackAged/aws-microservice.git
RESTART_ARGS=

### Automation steps ###

set -x

if hash git 2>/dev/null; then
    echo "git is  found"
else
    yum install -y git
fi

# Pull latest code
if [[ -e $APP_DIR/aws-microservice ]]; then
    cd $APP_DIR/aws-microservice
    git pull
else
    git clone $GIT_URL $APP_DIR/aws-microservice
    cd $APP_DIR/aws-microservice
fi

if hash npm 2>/dev/null; then
    echo "node and npm is found"
else
    yum install -y gcc-c++ make
    curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash -
    yum install -y nodejs
fi

# Install dependencies
npm install --production
npm prune --production

if hash pm2 2>/dev/null; then
    echo "pm2 is found"
else
    npm i -g pm2
fi

pm2 delete -s app || :
pm2 start app.js --name=app

if hash nginx 2>/dev/null; then
    echo "nginx is found"
else
    yum install -y nginx
fi

printf '
events {

}

http {
	upstream my_nodejs_upstream {
	    server 127.0.0.1:3000;
	    keepalive 64;
	}

	server {
	    listen 80;
	    
	    server_name www.my-website.com;
	    
	   
	    location / {
	    	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Real-IP $remote_addr;
	    	proxy_set_header Host $http_host;
		
	    	proxy_http_version 1.1;
	    	proxy_set_header Upgrade $http_upgrade;
	    	proxy_set_header Connection "upgrade";
		
	    	proxy_pass http://my_nodejs_upstream/;
	    	proxy_redirect off;
	    	proxy_read_timeout 240s;
	    }
	}
}' >/etc/nginx/nginx.conf

service nginx restart
