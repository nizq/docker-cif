#!/bin/sh

es_host=${ES:-localhost}
new_mark=/etc/cif/.new_install

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

for service in "worker" "smrt"; do
    conf=/etc/cif/cif-${service}.yml
    if [ ! -f "$conf" ] || [ -f "new_mark" ]; then
        /opt/cif/bin/cif-tokens --storage-host ${es_host}:9200 \
                                --username cif-${service} --new --read --write \
                                --generate-config-remote tcp://localhost:4961 \
                                --generate-config-path $conf
    fi
done

rm -f $new_mark

unbound -c /unbound.conf

cat <<EOF >/supervisord.conf
[program:router]
command=/opt/cif/bin/cif-router --storage-host=${es_host}:9200 --logging --logfile=/var/log/cif/router.log

[program:worker]
command=/opt/cif/bin/cif-worker -C /etc/cif/bin/cif-worker.yml --logging --logfile=/var/log/cif/worker.log

[program:smrt]
command=/opt/cif/bin/cif-smrt -C /etc/cif/bin/cif-smrt.yml --logging --logfile=/var/log/cif/smrt.log

[supervisord]
logfile = /var/log/cif/supervisord.log
logfile_maxbytes = 50MB
logfile_backups=7
loglevel = info
pidfile = /var/run/supervisord.pid
nodaemon = true
EOF

supervisord -c /supervisord.conf
