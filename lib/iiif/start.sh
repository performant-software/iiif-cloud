#!/bin/bash
#
# Launches Cantaloupe. Run by systemd; see cantaloupe.service.
#
# Set CANT, JAR and HEAP correctly for your host.
#
# CantaloupePreinit initializes Apache Jena single-threaded before handing off
# to Cantaloupe's normal entry point (see CantaloupePreinit.java). It is
# compiled against a specific Cantaloupe jar; rebuild it when upgrading.
#
set -eu

CANT=/root/cantaloupe-5.0.6
JAR=cantaloupe-5.0.6.jar
HEAP=4g
HEAP_DUMPS_KEPT=4
TMP=/root/cantaloupe-tmp

mkdir -p /root/heapdumps /root/gclogs "$TMP"

# Keep only the newest HEAP_DUMPS_KEPT heap dumps
ls -1t /root/heapdumps/*.hprof 2>/dev/null | tail -n +$((HEAP_DUMPS_KEPT + 1)) | xargs -r rm -f

# Clear tmp files from previous jvm process
find "$TMP" -mindepth 1 -delete

# exec, so the JVM replaces this shell and systemd's MainPID is the JVM itself.
exec java \
  -Dcantaloupe.config="$CANT/cantaloupe.properties" \
  -Xms"$HEAP" -Xmx"$HEAP" \
  -Djava.io.tmpdir="$TMP" \
  -XX:+ExitOnOutOfMemoryError \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/root/heapdumps/ \
  -Xlog:gc*:file=/root/gclogs/gc.log:time,uptime,level,tags:filecount=5,filesize=20M \
  -cp "$CANT/$JAR:/root/preinit" \
  CantaloupePreinit
