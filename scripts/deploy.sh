#!/bin/bash


# git pull origin mainしたら、nginxフォルダとMySQLフォルダにファイルをコピーする
sudo git pull origin main
sudo cp -r confings/nginx/* /etc/nginx/
sudo cp -r confings/mysql/ /etc/mysql/

# ruby再起動, nginx再起動, mysql再起動する
sudo systemctl restart isuride-ruby.service
sudo systemctl restart nginx.service
sudo systemctl restart mysql.service

# nginx.logを削除する、mysql.logを削除する
sudo rm /var/log/nginx/access.log
sudo rm /var/log/mysql/slow.log
