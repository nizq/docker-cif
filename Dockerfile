FROM debian:jessie

MAINTAINER nizq <ni.zhiqiang@gmail.com>

RUN echo "===> Building..." \
    && sed -i "s/httpredir/ftp.cn/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y vim htop git git-core curl pkg-config rng-tools geoip-bin starman python-dev \
       build-essential automake autoconf libmodule-build-perl libssl-dev libtool wget \
       libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl libxml2-dev \
       libexpat1-dev libgeoip-dev libzmq3-dev gcc jq curl supervisor libperl-dev bind9 \
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
    && ln -sf /usr/lib/x86_64-linux-gnu/libzmq.so.3 /usr/lib/x86_64-linux-gnu/libzmq.so \
    && mkdir -p /var/cif/cache \
    && make && make install \
    && apt-get remove -y build-essential automake autoconf libssl-dev libtool libxml2-dev \
       libexpat1-dev libgeoip-dev libzmq3-dev gcc libperl-dev \
    && cp /root/mos/elasticsearch/*.json / \
    && rm -rf /root/mos

COPY ["named.conf.options", "named.conf.local", "/"]
RUN cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig \
    && cp /named.conf.options /etc/bind/named.conf.options \
    && cat /named.conf.local >> /etc/bind/named.conf.local \
    && echo "nameserver 127.0.0.1" > /etc/resolv.conf \
    && rm /named.conf.options /named.conf.local

VOLUME ["/var/cif"]
COPY ["entrypoint.sh", "/" ]
CMD ["/entrypoint.sh"]
