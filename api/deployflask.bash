#!/bin/bash
# Baldwin Browne <bbrowne83@gmail.com>
# This script deploys nsc cloud practicum API

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install python-pip
sudo apt-get install apache2
sudo apt-get install libapache2-mod-wsgi

sudo mkdir /var/www/FlaskApp
sudo mkdir /var/www/FlaskApp/FlaskApp
sudo mkdir /var/www/FlaskApp/FlaskApp/templates
sudo mkdir /var/www/FlaskApp/FlaskApp/static


if [ ! -f /var/www/FlaskApp/FlaskApp/__init__.py ]; then
sudo cat > /var/www/FlaskApp/FlaskApp/__init__.py <<'_EOF'
from flask import Flask

#declare flask app
app = Flask(__name__)

#hello world for testing purposes
@app.route("/hello")
def hello():
    return "Hello, world!"


#initializes app and runs debug
if __name__ == "__main__":
    app.debug=True 
    app.run()

_EOF
echo "__init__.py created"
fi

sudo pip install virtualenv
sudo virtualenv /var/www/FlaskApp/FlaskApp/venv

fapp='/var/www/FlaskApp/FlaskApp'
$fapp/venv/bin/pip install Flask
$fapp/venv/bin/pip install Azure
$fapp/venv/bin/pip install oauthlib
$fapp/venv/bin/pip install requests
$fapp/venv/bin/pip install requests_oauthlib
$fapp/venv/bin/pip install pydocumentdb

echo "Enter the url of your VM i.e. http://myvm.cloudapp.net"
read URL

config='/etc/apache2/sites-available/FlaskApp.conf'

echo "<VirtualHost *:80>" > $config
echo "                ServerName $URL" >> $config
echo "                ServerAdmin IAmTheAdmin@StillNotMyProblem.com" >> $config
echo "                WSGIScriptAlias / /var/www/FlaskApp/flaskapp.wsgi" >> $config
echo "                <Directory /var/www/FlaskApp/FlaskApp/>" >> $config
echo "                        Order allow,deny" >> $config
echo "                        Allow from all" >> $config
echo "                </Directory>" >> $config
echo "                Alias /static /var/www/FlaskApp/FlaskApp/static" >> $config
echo "                <Directory /var/www/FlaskApp/FlaskApp/static/>" >> $config
echo "                        Order allow,deny" >> $config
echo "                        Allow from all" >> $config
echo "                </Directory>" >> $config
echo "                ErrorLog \${APACHE_LOG_DIR}/error.log" >> $config
echo "                LogLevel warn" >> $config
echo "                CustomLog \${APACHE_LOG_DIR}/access.log combined" >> $config
echo "</VirtualHost>" >> $config

sudo /usr/sbin/a2ensite FlaskApp
sudo /etc/init.d/apache2 reload

sudo cat > /var/www/FlaskApp/flaskapp.wsgi <<'_EOF'

#!/usr/bin/python
import sys
import logging
logging.basicConfig(stream=sys.stderr)
sys.path.insert(0,"/var/www/FlaskApp/")

from FlaskApp import app as application
application.secret_key = 'random_string'

_EOF

sudo /etc/init.d/apache2 restart
