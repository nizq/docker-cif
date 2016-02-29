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

supervisord -c /etc/cif/supervisord.conf
