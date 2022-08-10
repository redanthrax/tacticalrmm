#!/usr/bin/env bash
#
# https://www.freecodecamp.org/news/how-to-implement-runtime-environment-variables-with-create-react-app-docker-and-nginx-7f9d42a91d70/
#

: "${DEV:=0}"

# Recreate js config file on start
rm -rf ${PUBLIC_DIR}/env-config.js
touch ${PUBLIC_DIR}/env-config.js

# Add runtime base url assignment 
if [[ $DEV -eq 1 ]]; then
	echo "window._env_ = {PROD_URL: \"http://${API_HOST}\"}" >> ${PUBLIC_DIR}/env-config.js
else
	echo "window._env_ = {PROD_URL: \"https://${API_HOST}\"}" >> ${PUBLIC_DIR}/env-config.js
fi

nginx_config="$(cat << EOF
server {
  listen 8080;
  charset utf-8;

  location / {
    root /usr/share/nginx/html;
    try_files \$uri \$uri/ /index.html;
    add_header Cache-Control "no-store, no-cache, must-revalidate";
    add_header Pragma "no-cache";
  }
}
EOF
)"

echo "${nginx_config}" > /etc/nginx/conf.d/default.conf
