FROM centos:centos7.6.1810

ENV GITHUB https://github.com
ENV GOSU_VERSION 1.10
ENV GOSU_ARCH amd64
ENV GOSU_URL ${GITHUB}/tianon/gosu/releases/download
ENV GOSU_APP ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}
ENV GOSU_ASC ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}.asc
ENV DB4_VERSION 4.8.30.NC
ENV DB4_HASH 12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef
ENV DB4_URL http://download.oracle.com/berkeley-db/db-${DB4_VERSION}.tar.gz
ENV MONGOC 1.13.0
ENV MONGOC_URL ${GITHUB}/mongodb/mongo-c-driver/releases/download/${MONGOC}/\
mongo-c-driver-${MONGOC}.tar.gz
ENV MONGOCXX r3.4.0
ENV MONGOCXX_URL ${GITHUB}/mongodb/mongo-cxx-driver/archive/${MONGOCXX}.tar.gz

# Setup required system packages
RUN set -x \
    && yum install -y epel-release \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN set -x \
    && yum install -y \
        gcc \
        gcc-c++ \
        make \
        git \
        curl-devel \
        libevent-devel \
        tcl-devel \
        tk-devel \
        curl-devel \
        zlib-devel \
        bzip2-devel \
        openssl-devel \
        ncurses-devel \
        readline-devel \
        gdbm-devel \
        file \
        libpcap-devel \
        xz-devel \
        expat-devel \
        snappy-devel \
        libevent-devel \
        libdb4-devel \
        libdb4-cxx-devel \
        zeromq-devel \
        gmp-devel \
        mpfr-devel \
        libmpc-devel \
        which \
        autoconf \
        automake \
        libtool \
        boost-devel \
        zeromq-devel \
        iproute \
        jq \
        python36 \
        cmake3 \
    && ln -s -f /usr/bin/python36 /usr/bin/python3 \
    && yum clean all \
    && rm -rf /var/cache/yum

# Python packages
RUN set -x \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && pip3 install zmq \
    && rm -f get-pip.py

# gosu
RUN set -x \
    && adduser -m bitcoin \
    && chown bitcoin:bitcoin /home/bitcoin \
	&& curl -o /usr/local/bin/gosu -SL ${GOSU_APP} \
	&& curl -o /usr/local/bin/gosu.asc -SL ${GOSU_ASC} \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
        B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Build Berkeley DB
RUN set -x \
    && cd /usr/src \
    && curl -OL ${DB4_URL} \
    && echo "${DB4_HASH} db-${DB4_VERSION}.tar.gz" | sha256sum -c || exit 1 \
    && tar zxvf db-${DB4_VERSION}.tar.gz \
    && cd db-${DB4_VERSION}/build_unix \
    && ../dist/configure --prefix=/usr --enable-compat185 \
        --enable-dbm --disable-static --enable-cxx --with-pic \
    && make -j$(nproc) \
    && make install \
    && make clean \
    && cd /usr/src \
    && rm -rf /usr/src/db-${DB4_VERSION}*

# Build MongoDB C driver
RUN set -x \
    && cd /usr/src \
    && curl -LO ${MONGOC_URL} \
    && tar zxvf mongo-c-driver-${MONGOC}.tar.gz \
    && cd mongo-c-driver-${MONGOC}/build \
    && cmake3 -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j$(nproc) \
    && make install \
    && cd /usr/src \
    && rm -rf /usr/src/mongo-c-driver*

# Build Mongo C++ driver
RUN set -x \
    && cd /usr/src \
    && curl -LO ${MONGOCXX_URL} \
    && tar zxvf ${MONGOCXX}.tar.gz \
    && cd mongo-cxx-driver-${MONGOCXX}/build \
    && cmake3 -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_PREFIX_PATH=/usr/local .. \
    && make -j$(nproc) \
    && make install \
    && cd /usr/src \
    && rm -rf /usr/src/mongo-cxx-driver*
