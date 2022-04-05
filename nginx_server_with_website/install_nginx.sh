#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo su
echo "<html><body bgcolor="olive"><h1 align="center"> This is my Application Page<br>MAIN PAGE<br></h1></body></html>"> /var/www/html/index.html