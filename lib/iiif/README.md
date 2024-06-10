# Cantaloupe IIIF
Instructions for setting up a Cantaloupe IIIF instance 

## Requirements
- Cantaloupe 5.0
- Java 11+

## Install Dependencies

```bash
sudo apt install default-jre unzip wget -y
```

## Download Cantaloupe

```bash
sudo wget https://github.com/cantaloupe-project/cantaloupe/releases/download/v5.0.6/cantaloupe-5.0.6.zip
```

## Custom Delegate
Add the contents of `custom_delegate.rb` to:

```bash
/root/cantaloupe-5.0.6/delegates.rb
```

## Modify cantaloupe.properties (Optional)
Set custom properties in `/root/cantaloupe-5.0.6/cantalouple.properties`

### Enable Admin Console

```bash
endpoint.admin.enabled = true
endpoint.admin.username = admin
endpoint.admin.secret = <password>
```

### Enable Delegate Script

```bash
delegate_script.enabled = true
```

## Create a service
Cantaloupe run as a Java application. To set up Cantaloupe to run as a service on Ubuntu, add the `cantaloupe.service` file to:

```
/etc/systemd/system/cantaloupe.service
```

## Create start.sh
Add the `start.sh` file to `/root`. Change the Cantaloupe version if necessary.

## Enable/start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable cantaloupe.service
sudo systemctl start cantaloupe
sudo systemctl status cantaloupe
```

## Logging

### Setup

```bash
sudo journalctl --unit=cantaloupe
```

### View

```bash
sudo journalctl -f -u cantaloupe
```