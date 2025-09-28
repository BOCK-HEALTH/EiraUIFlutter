Eira Health Assistant - Web Deployment Guide

This guide explains how to build and deploy the Eira Health Assistant Flutter web application. The web app is a Single Page Application (SPA), packaged as static files (HTML, JS, CSS, assets) that can be hosted on any web server.

The recommended production setup uses AWS EC2 with Apache, optionally fronted by Amazon CloudFront for HTTPS and global content delivery.

1. Building the Web App for Production

Navigate to the project root directory.

Install dependencies:

flutter pub get


Build the web app for production:

flutter build web --release


Locate the output:
All production-ready static files are generated in the build/web directory. This directory will be uploaded to your web server.

2. Deploying on EC2 with Apache
Step 1: Prepare files

Zip the contents of build/web for easy transfer:

cd build/web
zip -r frontend.zip . 

Step 2: Upload to the server

Use scp to securely transfer files to your EC2 instance:

scp -i "your-key.pem" frontend.zip ubuntu@<YOUR_EC2_IP>:~/

Step 3: Deploy on Apache

SSH into your EC2 instance:

ssh -i "your-key.pem" ubuntu@<YOUR_EC2_IP>


Remove old website files:

sudo rm -rf /var/www/html/*


Unzip new files into Apache's web root:

sudo unzip ~/frontend.zip -d /var/www/html/

Step 4: Configure Apache for SPA routing

Enable mod_rewrite:

sudo a2enmod rewrite


Edit Apache configuration (/etc/apache2/sites-available/000-default.conf) and add a directory block to redirect all non-existent paths to index.html:

<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>


Create a .htaccess file in /var/www/html/ with:

RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.html [QSA,L]

Step 5: Restart Apache
sudo systemctl restart apache2

3. Important Notes

Backend URL: Ensure _baseUrl in lib/api_service.dart points to the production backend server.

HTTPS: The web app must be served over HTTPS for features like flutter_secure_storage to work. This can be achieved using CloudFront or another reverse proxy.

Caching & CDN: Using CloudFront or a similar CDN ensures fast global delivery and proper caching of static assets.

✅ Tip: For future updates, consider automating the deployment with a script that builds, zips, uploads, and deploys the web app in one command. This reduces errors and speeds up production releases.
