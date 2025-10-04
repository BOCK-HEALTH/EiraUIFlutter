🌐 Eira Health Assistant - Web Deployment Guide

This document provides step-by-step instructions for building and deploying the Eira Health Assistant web application.

The web app is a Single Page Application (SPA) built with Flutter Web, compiled into static assets (HTML, CSS, JavaScript, and images), and hosted on a web server.

🚀 Deployment Strategy

The Flutter web app is packaged into static files that can be hosted on any standard web server.

Recommended setup:

AWS EC2 + Apache → Serves the static files.

Amazon CloudFront (CDN) → Provides HTTPS, caching, and global distribution.

🛠 Building the Web App for Production

Navigate to the project root directory (where pubspec.yaml is located).

Fetch all dependencies:

flutter pub get


Build the web app (optimized for production):

flutter build web --release


Locate the build output at:

build/web/


This folder contains index.html, main.dart.js, flutter_service_worker.js, and assets/.

📦 Deployment on AWS EC2 with Apache
1. Prepare the Files

Compress the build/web directory:

zip -r frontend.zip build/web/*

2. Upload to EC2

Use scp to transfer the zipped files:

scp -i "your-key.pem" frontend.zip ubuntu@<YOUR_EC2_IP>:~/

3. Deploy on Server

SSH into your EC2 instance:

ssh -i "your-key.pem" ubuntu@<YOUR_EC2_IP>


Then:

# Remove old files
sudo rm -rf /var/www/html/*

# Extract new files into Apache web root
sudo unzip ~/frontend.zip -d /var/www/html/

4. Configure Apache for Flutter SPA

Enable Apache’s rewrite module:

sudo a2enmod rewrite


Edit the default site config:

sudo nano /etc/apache2/sites-available/000-default.conf


Add inside <VirtualHost *:80>:

<Directory /var/www/html>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>


Then create a .htaccess file in /var/www/html/:

<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>


This ensures all unknown routes are handled by Flutter’s router.

5. Restart Apache
sudo systemctl restart apache2

🔑 Notes & Best Practices

Backend URL:
Before building, confirm that the _baseUrl in:

lib/api_service.dart


points to the production backend IP or domain.

HTTPS Required:
Some Flutter web features (e.g., flutter_secure_storage, service workers) require HTTPS.
✅ Set up Amazon CloudFront with your EC2 as the origin to enable SSL (Let’s Encrypt can also be used directly on EC2).

Caching & CDN:
Use CloudFront or another CDN to serve static files efficiently worldwide.

✅ Summary

Run flutter build web --release to generate deployable static files.

Deploy to /var/www/html/ on Apache.

Configure rewrite rules for SPA routing.

Secure with HTTPS (CloudFront or Let’s Encrypt).
