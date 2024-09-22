#!/bin/bash
# Update the package repository
yum update -y
# Install Apache HTTP Server
yum install -y httpd
# Create a custom index.html file
echo "<html><body><h1>Welcome to My Web Server!</h1></body></html>" > /var/www/html/index.html
# Start the Apache service
systemctl start httpd
# Enable Apache to start on boot
systemctl enable httpd
