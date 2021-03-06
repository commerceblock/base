FROM centos:8.2.2004

ENV GITHUB https://github.com
ENV GOSU_VERSION 1.12
ENV GOSU_ARCH amd64
ENV GOSU_URL ${GITHUB}/tianon/gosu/releases/download
ENV GOSU_APP ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}
ENV GOSU_ASC ${GOSU_URL}/${GOSU_VERSION}/gosu-${GOSU_ARCH}.asc
ENV RPM_URL https://rpmfind.net/linux/fedora/linux/releases/32/Everything/x86_64/os/Packages/c
ENV CURLPP_LIBS -L/usr/local/lib64 -lcurl -lcurlpp
ENV CURLPP_CFLAGS -Iinclude

# Setup required system packages
RUN set -x \
    && yum install -y epel-release \
    && yum install -y https://pkgs.dyn.su/el8/base/x86_64/raven-release-1.0-1.el8.noarch.rpm \
    && dnf install -y ${RPM_URL}/curlpp-0.8.1-10.fc32.x86_64.rpm \
    && dnf install -y ${RPM_URL}/curlpp-devel-0.8.1-10.fc32.x86_64.rpm \
    && dnf install -y 'dnf-command(config-manager)' \
    && dnf config-manager --set-enabled PowerTools \
    && yum clean all \
    && yum install -y \
        gcc \
        gcc-c++ \
        make \
        git \
        curl-devel \
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
        libdb4 \
        libdb4-cxx \
        libdb4-tcl \
        libdb4-devel \
        libdb4-cxx-devel \
        libdb4-tcl-devel \
        libdb4-utils \
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
        bc \
        python38 \
        cmake3 \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && pip3 install zmq

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
