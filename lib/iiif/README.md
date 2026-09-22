# Cantaloupe IIIF
Instructions for setting up a Cantaloupe IIIF instance 

## Requirements
- Cantaloupe 5.0
- Java 11+ JDK
- FFMPEG

## Install Dependencies

```bash
sudo apt install default-jdk-headless unzip wget ffmpeg -y
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

## Modify cantaloupe.properties
Copy `cantaloupe.properties` to `/root/cantaloupe-5.0.6/cantaloupe.properties`, then set the values for this host.

- `endpoint.api.secret` must match `CANTALOUPE_API_PASSWORD` in the iiif-cloud app's environment. The app purges cache entries through the API (`Iiif::Server#clear_cache`), so the API endpoint must stay enabled.
- `S3Source.access_key_id` and `S3Source.secret_key`.

### Enable Admin Console (optional)

```bash
endpoint.admin.enabled = true
endpoint.admin.username = admin
endpoint.admin.secret = <password>
```

### Enable Delegate Script

```bash
delegate_script.enabled = true
```

## Build the Jena preinit
`start.sh` launches Cantaloupe through `CantaloupePreinit`, which initializes Apache Jena on a single thread before Cantaloupe starts accepting requests. Without it, concurrent requests shortly after startup can deadlock inside Jena's class initialization, permanently consuming Jetty's worker threads until the server stops responding. See `CantaloupePreinit.java` for more details.

Build it against this host's Cantaloupe jar:

```bash
cp CantaloupePreinit.java /root/
mkdir -p /root/preinit
javac --release 11 -cp /root/cantaloupe-5.0.6/cantaloupe-5.0.6.jar -d /root/preinit /root/CantaloupePreinit.java
```

## Create start.sh
Copy the `start.sh` file to `/root` and make it executable (`chmod 700 /root/start.sh`). Set `CANT`, `JAR` and `HEAP` at the top for this host.

## Create a service
Cantaloupe runs as a Java application. To set up Cantaloupe to run as a service on Ubuntu, add the `cantaloupe.service` file to:

```
/etc/systemd/system/cantaloupe.service
```

## Enable/start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable cantaloupe.service
sudo systemctl start cantaloupe
sudo systemctl status cantaloupe
```

Confirm the preinit ran and that systemd's main PID is the JVM:

```bash
journalctl -u cantaloupe --since '5 min ago' | grep preinit
ps -o pid,args -p $(systemctl show -p MainPID --value cantaloupe)
```

## Host setup

### Swap
Add a small swapfile on hosts without one:

```bash
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf && sysctl -p /etc/sysctl.d/99-swappiness.conf
```

### Cap journald

```bash
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=500M\n' > /etc/systemd/journald.conf.d/size.conf
systemctl restart systemd-journald
```

## Sizing
- `HEAP` in `start.sh` should be about half of available RAM, and never more than physical RAM.
- `http.max_threads` in `cantaloupe.properties` must be at least 8. If you want to set it higher, `(0.75 × HEAP ÷ 600 MB) + 3` is a safe rule of thumb.

## Upgrading Cantaloupe
1. Download and unzip the new release, and copy `cantaloupe.properties` and `delegates.rb` across.
2. Update `CANT` and `JAR` in `/root/start.sh`.
3. Rebuild the preinit against the new jar (see above). It is compiled against a specific Cantaloupe version.
4. Restart, and check for the `[preinit]` line.

## Logging
Application and error logs roll daily (`cantaloupe-application-YYYY-MM-DD.log`, `cantaloupe-error-YYYY-MM-DD.log`) and are kept for 14 days. The level is `info`. Log level `debug` writes on the order of 1 GB/day on a busy host, so raise it only temporarily.

journald holds only startup output and crashes:

```bash
sudo journalctl -f -u cantaloupe
```

GC logs are in `/root/gclogs/`. Heap dumps from an out-of-memory exit go to `/root/heapdumps/`; each is roughly the size of the heap, so delete them once analyzed.

## Troubleshooting a wedged server
If Cantaloupe stops responding while the process stays up, take a thread dump:

```bash
jcmd $(systemctl show -p MainPID --value cantaloupe) Thread.print > /root/threaddump.txt
```

Threads parked in `Metadata.loadXMP` with `waiting on the Class initialization monitor` for a Jena class mean the preinit isn't running: check that `start.sh` launches `CantaloupePreinit` and that `/root/preinit/CantaloupePreinit.class` exists.
