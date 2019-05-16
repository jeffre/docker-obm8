# AhsayOBM v8.1.1.50
backup agent for connecting to an AhsayCBS


## How to use
1. Create a user account with a fully configured backupset on your CBS
2. Set the "run backup on computers named:" to the same name you give to the container (use `--hostname`)
3. Choose your encryption (see Setting Encryption below)
2. Run: `docker run -e USERNAME=jeffre -e PASSWORD=secretpassword -e SERVER=cbs.example.com -e BSET-1498585537118=PKCS7Padding,AES-256,ECB,SuperStrongSecretString --hostname=docker-obm yoff/obm8`


### Available environment variables
+ `USERNAME`* - CBS username
+ `PASSWORD`* - CBS password
+ `PROTO` - [http|https]
+ `SERVER`* - CBS address
+ `BSET-{BACKUPSETID}` - (required) see "Setting Encryption" below
+ `ENABLE_AUA` - if set to TRUE, will run AUA daemon. Be aware, AUA does not
automatically restart after an update.  

\* = required


## Setting Encryption
Using CBS provided backupset id, you can formulate an
environment variable that specifies how OBM will encrypt your data. The format is:  
+ **BSID-{BACKUPSETID}=PKCS7Padding,{Algorithm}-{Bits},{Mode},{Key}**.

The available choices for the encryption attributes are:  
+ **PKCS7Padding:** PKCS7Padding  
+ **Algorithms:** AES, Twofish, TripleDES, "" &nbsp; &nbsp; &nbsp; &nbsp; # An empty string implies no encryption  
+ **Bits:** 128, 256  
+ **Modes:** ECB, CBC  
+ **Key:** {any string of your choosing}  


### Encryption Examples
+ Strong Encryption: `BSET-1498585537118=PKCS7Padding,AES-256,ECB,ElevenFoughtConstructionFavorite`  
+ No Encryption: `BSET-1468557583616=PKCS7Padding,-256,,`  

## Paths
+ Application home: **/obm/**  
+ User Config: **/root/.obm/**  


## Notes
+ Many files are excluded from the standard OBM installation to reduce image 
size. For a full accouting look at obm/extract-obm.sh
+ bin/Scheduler.sh is prevented from daemonizing.
