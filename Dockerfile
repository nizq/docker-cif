FROM alpine:3.3

MAINTAINER nizq <ni.zhiqiang@gmail.com>

RUN echo "===> Building..." \
    && sed -i "s/dl-4\.alpinelinux\.org/repos\.lax-noc\.com/g" /etc/apk/repositories \
    && apk add --update libffi libzmq perl perl openssl expat gettext libxml2 \
           make libffi-dev gcc libc-dev perl-dev jq wget \
           curl openssl-dev autoconf automake libtool bash \
           expat-dev libxml2-dev git unbound supervisor \
    && curl -L https://cpanmin.us | perl - App::cpanminus \
    && cpanm --notest Regexp::Common Moo@1.007000 Mouse@2.4.1 ZMQ::FFI@0.17 \
        Log::Log4perl@1.44 Test::Exception@0.32 MaxMind::DB::Reader@0.050005 \
        GeoIP2@0.040005 Hijk@0.19 Crypt::Random::Source Compress::Snappy Starman \
        Carp::Assert DateTime::Format::DateParse Daemon::Control XML::RSS \
        XML::LibXML File::Slurp HTML::TableExtract String::Tokenizer File::Type \
        Search::Elasticsearch@1.19 Net::Abuse::Utils Net::Abuse::Utils::Spamhaus Encoding::FixLatin \
    && cpanm --notest https://github.com/csirtgadgets/ZMQx-Class/archive/master.tar.gz \
    && cpanm --notest https://github.com/csirtgadgets/p5-cif-sdk/archive/2.00_33.tar.gz \
    && cpanm --notest https://github.com/kraih/mojo/archive/v5.82.tar.gz \
    && cpanm --notest http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/local-lib-2.000015.tar.gz \
    && cd /root \
    && git clone https://github.com/csirtgadgets/massive-octo-spice.git mos \
    && cd mos/contrib \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz \
    && gunzip GeoLite2-City.mmdb.gz \
    && cd /root/mos \
    && ./autogen.sh \
    && ./configure --enable-geoip --sysconfdir=/etc/cif --localstatedir=/var/cif --prefix=/opt/cif \
    && ln -sf /usr/lib/libzmq.so.5 /usr/lib/libzmq.so \
    && mkdir -p /var/cif/cache \
    && make && make install \
    && apk del openssl-dev libc-dev perl-dev expat-dev libxml2-dev autoconf automake libtool git \
    && cp /root/mos/elasticsearch/*.json / \
    && rm -rf /var/cache/apk/* /root/mos

ENV CIF_HOME=/opt/cif PATH=$CIF_HOME/bin:$PATH PERL5LIB=/opt/cif/lib/perl5 DATA_DIR=/var/cif LOG_DIR=/var/cif/log CONF_DIR=/etc/cif
VOLUME ["/var/cif"]
COPY ["entrypoint.sh", "unbound.conf", "supervisord.conf", "/" ]
CMD ["/entrypoint.sh"]
