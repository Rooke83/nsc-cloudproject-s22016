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
from flask import request
from flask import jsonify
from azure_components.api_methods import *

#declare flask app
app = Flask(__name__)

#route for get images call
@app.route("/getImages", methods=['GET'])
def getImages():
    #header variables for get api method
    timestamp = request.headers.get('timestamp')
    tags = request.headers.get('tags')
    username = request.headers.get('username')
    token = request.headers.get('token')
    secret = request.headers.get('secret')
    prev = request.headers.get('prev')
    # checks if prev variable is set
    if opt_param is None:
        # updates variable to false
        prev = 'false'
    #calls get image method to get JSON from api method (get)
    rtn_json = getImagesJSON(timestamp, prev, tags, username, token, secret)
    # return json request
    return jsonify(request=rtn_json)

#route for uploading images
@app.route("/uploadImage", methods=['POST'])
def uploadImage():
    #header variables for post api method
    username = request.headers.get('username')
    blob = request.headers.get('blob')
    filename = request.headers.get('filename')
    token = request.headers.get('token')
    secret = request.headers.get('secret')
    tags = request.headers.get('tags')

    #calls upload image method (post)
    rtn_json = uploadImageJSON(username, blob, filename, token, secret, tags)
    #returns json succes or error json message
    return jsonify(request=rtn_json)

#route for deleting images
@app.route("/deleteImage", methods=['DELETE'])
def deleteImage():
    #header variables for delete api method
    blobURL = request.headers.get('blobURL')
    token = request.headers.get('token')
    secret = request.headers.get('secret')

    #calls delete image method (delete)
    rtn_json = deleteImageJSON(username, blobURL, token, secret)
    #returns json succes or error json message
    return jsonify(request=rtn_json)

#route for updating tags
@app.route("/updateTags", methods=['PUT'])
def updateTags():
    #header variables for put api method
    blobURL = request.headers.get('blobURL')
    tags = request.headers.get('tags')
    token = request.headers.get('token')
    secret = request.headers.get('secret')

    #calls update tags method (put)
    rtn_json = updateTagsJSON(blobURL, tags, username, token, secret)
    #returns json succes or error json message
    return jsonify(request=rtn_json)

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


if [ ! -f /var/www/FlaskApp/FlaskApp/azure_components/api_methods.py ]; then
sudo cat > /var/www/FlaskApp/FlaskApp/azure_components/api_methods.py <<'_EOF'

from blob import uploadBlob, deleteBlob
from verify_oauth import verifyOauth
from make_meta_data import makeMetadata
from static.app_json import *

def uploadImageJSON(username, blob, filename, token, secret, tags):
    oauth_verify_code = verifyOauth(token, secret)
    if oauth_verify_code != 200:
        return oauth_error_json
        
    rtnBlobList = uploadBlob(username, blob, filename)
    if len(rtnBlobList) < 2:
        return upload_image_blob_error_json


    rtnDocumentdbMsg = makeMetadata(username, filename, tags, rtnBlobList[0], rtnBlobList[1])  
    if rtnDocumentdbMsg  != "success":
        return upload_image_db_error_json
        
    return upload_image_success_json


def deleteImageJSON(username, blobURL, token, secret):
    oauth_verify_code = verifyOauth(token, secret)
    if oauth_verify_code != 200:
        return oauth_error_json
    
    rtnBlobList = deleteBlob(blobURL)
    if rtnBlobList[0]  != "success":
        return delete_image_blob_error_json

    return delete_image_success_json

def getImagesJSON(timestamp, tags, username, token, secret):
    oauth_verify_code = verifyOauth(token, secret)
    if oauth_verify_code != 200:
        return oauth_error_json

    rtnJSON = {'imgs' : 'get_images_placeholder'}
    return rtnJSON

def updateTagsJSON(blobURL, tags, username, token, secret):
    oauth_verify_code = verifyOauth(token, secret)
    if oauth_verify_code != 200:
        return oauth_error_json
    
    return update_tags_success_json

def main():
    print(uploadImageJSON('fin', '/Users/rjhunter/Desktop/bridge.jpg', 'Todd','4800385332-ZbrU1XfignI2lA3MjQu7U8KbIkTdYAdj1ArMVFR','BPSs4gwICptsGVZQc9F2EpWcw6ar1gsv4Nlnqvq5PFIdF','fun'))
    print(deleteImageJSON('fin', "https://ad440rjh.blob.core.windows.net/fin/2016-02-21130446459836_Todd",'4800385332-ZbrU1XfignI2lA3MjQu7U8KbIkTdYAdj1ArMVFR','BPSs4gwICptsGVZQc9F2EpWcw6ar1gsv4Nlnqvq5PFIdF'))
    print(getImagesJSON('10/2/15 4:40AM',['fun','luck'], 'fred','4800385332-ZbrU1XfignI2lA3MjQu7U8KbIkTdYAdj1ArMVFR','BPSs4gwICptsGVZQc9F2EpWcw6ar1gsv4Nlnqvq5PFIdF'))
    print(updateTagsJSON("www.blob.com", ['fun','luck'],'fred','4800385332-ZbrU1XfignI2lA3MjQu7U8KbIkTdYAdj1ArMVFR','BPSs4gwICptsGVZQc9F2EpWcw6ar1gsv4Nlnqvq5PFIdF'))


# call main
if __name__ == "__main__":
    main()

_EOF

fi

if [ ! -f /var/www/FlaskApp/FlaskApp/azure_components/blob.py ]; then
sudo cat > /var/www/FlaskApp/FlaskApp/azure_components/blob.py <<'_EOF'

from azure.storage.blob import BlobService
import datetime
import string
from static.app_keys import blob_account_name, blob_account_key

#get accountName and accountKey from app_keys module
accountName = blob_account_name
accountKey = blob_account_key
#create the blob_service object which connects to the Azure Storage account
blob_service = BlobService(accountName, accountKey)
#flag variable to verify upload
uploaded = False

#uploadBlob takes in the username which is used for the storage container name
#file is the file to be uploaded
#filename is concatenated onto the URL for user readability
#token and secret are used for oAuth verification which must happen at every step.
def uploadBlob(username, file, filename):
    try:
        global uploaded
        username = username.lower()
        returnList = []

        blob_service.create_container(username, x_ms_blob_public_access='container')

        #get current datetime in UTC for a completely unique identifier
        time = datetime.datetime.utcnow()
        #convet to string and replace characters illegal for a URL
        #do it in a new variable since "time" is sent to DocumentDB as a pure datetime object
        timeReplaced = str(time).replace(':','').replace('.','').replace(' ','') + "_" + filename
        #build the URL ahead of the upload and have it ready to send to DB if successful
        URLstring = "https://" + accountName + ".blob.core.windows.net/" + username + "/" + timeReplaced 

        uploaded = False
        #put the blob into storage
        #username is the container name, timeReplaced is the blob name
        #progress_callback calls the method of the same name and
        #checks upload status in bytes at the server tick rate
        blob_service.put_block_blob_from_path(
            username,
            timeReplaced,
            file,
            x_ms_blob_content_type='image/png',
            progress_callback=progress_callback
            )
        
        #if upload is successful, return a list with the timestamp and the final URL
        #to be put in database, else return an error
        if uploaded:
            returnList = [time, URLstring]
            return returnList
        else:
            return returnList["error"]

    except Exception:
        return ["error"]

#deleteBlob takes in the URL from http request headers
#finds the blob to be deleted by exploding the url and using
#last two elements as container name, blob name
def deleteBlob(blobURL):
    try:
        exploded = blobURL.split("/")#split based on /'s
        #second to last element is container name(username), last element is blob name
        blob_service.delete_blob(exploded[len(exploded)-2], exploded[len(exploded)-1])
        return ["success"]
    except Exception:
        return ["error"]
    
#unused function incase list of all blobs in container is desired.
def listBlobs(username):
    username = username.lower()
    blobs = []
    marker = None
    while True:
        batch = blob_service.list_blobs(username, marker=marker)
        blobs.extend(batch)

        if not batch.next_marker:
            break
        marker = batch.next_marker

    for blob in blobs:
        print(blob.name)
#calls progress_callback function in the Azure SDK
#current is total bytes that have been uploaded so far
#total is the total number of bytes in the file
def progress_callback(current, total):
    global uploaded
    #if current bytes uploaded == total file size, upload successful
    if(current==total):
        uploaded = True
_EOF
fi

if [ ! -f /var/www/FlaskApp/FlaskApp/azure_components/make_meta_data.py ]; then
sudo cat > /var/www/FlaskApp/FlaskApp/azure_components/make_meta_data.py <<'_EOF'

import pydocumentdb.document_client as document_client
import verify_oauth
import datetime
from datetime import timedelta
from static.app_keys import db_client, db_client_key, db_name, db_collection
	

#Need a function specifically oriented toward making the call.
#This is *not* async, which will need to change.
#Ideally, after this is complete, we'd send the confirmation to the UI that the upload completed.
def makeMetadata(user, originalFilename, tags, time, url):
    try:

        epoc = datetime.datetime(2016, 2, 23, 3, 0, 00, 000000);
        val = (time - epoc).total_seconds()*1000000;
                
        client = document_client.DocumentClient(db_client, {'masterKey': db_client_key});
        
        #Not sure we need this. Client may be it.
        db = next((data for data in client.ReadDatabases() if data['id'] == db_name));
        
        coll = next((coll for coll in client.ReadCollections(db['_self']) if coll['id'] == db_collection));

        #create document. Tags is an array, as passed.
        document = client.CreateDocument(coll['_self'],
                        {   "user_id": user,
                                "file_name": originalFilename,
                                "photo_url": url,
                                "photo_id": val,
                                "tags": tags
                        });
        
        returnlist = [];	
        

        return "success"
        
    except Exception:
        return "error"

_EOF
fi

if [ ! -f /var/www/FlaskApp/FlaskApp/azure_components/verify_oauth.py ]; then
sudo cat > /var/www/FlaskApp/FlaskApp/azure_components/verify_oauth.py <<'_EOF'

# RJ Hunter
# AD 440
# Cloud Practicum
# 
# file contains method to call twitter api and verify credentials of the
# app user.   
# 

import requests
from static.app_keys import oauth_consumer_key, oauth_consumer_secret 
from requests_oauthlib import OAuth1

# method calls twitter api and verifys a user's credentials.  The method
# will return a HTTP status code (200 for success, 401 for error). The
# method uses 2 parameters (access token, access token secret). The
# access token and secret are generated by the web/mobile client when
# logging into the app using twitter. These parameters will be handed
# to the server side api when making any requests.
def verifyOauth(access_token,access_token_secret):
    # consumer key and secret.  these keys are generated when creating
    # our twitter app on the twitter developer portal.  They are needed
    # when verifing twitter credentials
    try:
        consumer_key= oauth_consumer_key
        consumer_secret= oauth_consumer_secret 

        # url of twitter api that verifys a users credentials
        url = 'https://api.twitter.com/1.1/account/verify_credentials.json'
        # oAuth1 method that creates an authorization object to hand to
        # twitters api
        auth = OAuth1(consumer_key, consumer_secret, access_token, access_token_secret)

        # gets request from twitter api
        # returns json result from request
        rtnVerifyCode = requests.get(url, auth=auth)
        return rtnVerifyCode.status_code
    except Exception:
        return "error"

# main method
def main():
    
    # access token and secret are generated by the web client.  These tokens are used
    # to verify user's credentials 
    access_token=''
    access_token_secret=''
    # call method and print result
    #print(verify_oauth(access_token,access_token_secret))
    print(verify_oauth(access_token,access_token_secret))

# call main
if __name__ == "__main__":
    main()

_EOF
fi

sudo /etc/init.d/apache2 restart
