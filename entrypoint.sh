#!/bin/bash

CIF_HOME=/opt/cif
PATH=$CIF_HOME/bin:$PATH
PERL5LIB=/opt/cif/lib/perl5
DATA_DIR=/var/cif/data
LOG_DIR=/var/cif/log
CONF_DIR=/var/cif/conf

es_host=${ES:-localhost}
new_mark=/var/cif/.new_install

/etc/init.d/bind9 start

cd /var/cif
for path in "log" "conf"; do
    if [ ! -d "$path" ]; then
        (rm -f $path; mkdir $path)
    fi
done

# http://www.catonmat.net/blog/tcp-port-scanner-in-bash/
es_ready=0
while [  "$es_ready" -eq 0 ]; do
    echo >/dev/tcp/${es_host}/9200 &&
        es_ready=1 || es_ready=0
    if [ "$es_ready" -eq 1 ]; then
        echo "elasticsearch is ready."
    else
        echo "elasticsearch not ready..."
        sleep 2
    fi
done

cd /
url="http://${es_host}:9200/_template/cif_observables/"
num=$(curl -XGET ${url} 2>/dev/null|jq '.cif_observables|length')
if [ "$num" -eq 0 ]; then
    echo "Creating observables template..."
    curl -XPUT ${url} -d @observables.json
fi

url="http://${es_host}:9200/_template/cif_tokens/"
num=$(curl -XGET ${url} 2>/dev/null|jq '.cif_tokens|length')
if [ "$num" -eq 0 ]; then
    echo "Creating observables template..."
    curl -XPUT ${url} -d @tokens.json
    touch $new_mark
fi

conf=/var/cif/conf/cif-worker.yml
if [ ! -f "$conf" ] || [ -f "new_mark" ]; then
    /opt/cif/bin/cif-tokens --storage-host ${es_host}:9200 \
                            --username cif-worker --new --read --write \
                            --generate-config-remote tcp://localhost:4961 \
                            --generate-config-path $conf
fi

conf=/var/cif/conf/cif-smrt.yml
if [ ! -f "$conf" ] || [ -f "new_mark" ]; then
    /opt/cif/bin/cif-tokens --storage-host ${es_host}:9200 \
                            --username cif-smrt --new --read --write \
                            --generate-config-remote http://localhost:5000 \
                            --generate-config-path $conf
fi

conf=/var/cif/conf/user.yml
if [ ! -f "$conf" ] || [ -f "new_mark" ]; then
    /opt/cif/bin/cif-tokens --storage-host ${es_host}:9200 \
                            --username user@localhost --new --read --write \
                            --generate-config-remote http://localhost:5000 \
                            --generate-config-path $conf
fi

rm -f $new_mark

WORKERS=16
APP=/opt/cif/bin/cif.psgi
INTERVAL=5
PORT=5000
STARMAN_REQUESTS="1"

cat <<EOF >/supervisord.conf
[program:router]
command=/opt/cif/bin/cif-router --storage-host=${es_host}:9200 --logging --logfile=$LOG_DIR/router.log

[program:worker]
command=/opt/cif/bin/cif-worker -C $CONF_DIR/cif-worker.yml --logging --logfile=$LOG_DIR/worker.log

[program:smrt]
command=/opt/cif/bin/cif-smrt -C $CONF_DIR/cif-smrt.yml --logging --logfile=$LOG_DIR/smrt.log

[program:starman]
command=/usr/bin/starman --workers $WORKERS --port $PORT --error-log $LOG_DIR/starman.log --max-requests $STARMAN_REQUESTS --disable-keepalive $APP

[supervisord]
logfile = $LOG_DIR/supervisord.log
logfile_maxbytes = 50MB
logfile_backups=7
loglevel = info
pidfile = /var/run/supervisord.pid
nodaemon = true
EOF

supervisord -c /supervisord.conf
