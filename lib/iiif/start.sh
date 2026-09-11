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

mkdir -p /root/heapdumps /root/gclogs

# exec, so the JVM replaces this shell and systemd's MainPID is the JVM itself.
exec java \
  -Dcantaloupe.config="$CANT/cantaloupe.properties" \
  -Xms"$HEAP" -Xmx"$HEAP" \
  -XX:+ExitOnOutOfMemoryError \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/root/heapdumps/ \
  -Xlog:gc*:file=/root/gclogs/gc.log:time,uptime,level,tags:filecount=5,filesize=20M \
  -cp "$CANT/$JAR:/root/preinit" \
  CantaloupePreinit
