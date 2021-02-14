FROM debian:buster
LABEL version="1.0" description="OwnTracks Recorder"
LABEL authors="Jan-Piet Mens <jpmens@gmail.com>, Giovanni Angoli <juzam76@gmail.com>, Amy Nagle <kabili@zyrenth.com>, Malte Deiseroth <mdeiseroth88@gmail.com>"

# build with `docker build --build-arg recorder_version=x.y.z '
ARG recorder_version=0.8.6

COPY entrypoint.sh /entrypoint.sh
COPY config.mk /config.mk
COPY recorder.conf /etc/default/recorder.conf
COPY recorder-health.sh /usr/local/sbin/recorder-health.sh

ENV VERSION=$recorder_version
ENV EUID=9999

RUN apt-get update \
    && apt-get install -y wget curl jq build-essential libcurl4-openssl-dev libmosquitto-dev \
                          liblua5.2-dev libsodium-dev libconfig-dev liblmdb-dev \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g $EUID appuser \
    && useradd -r -u $EUID -s "/bin/sh" -g appuser appuser \
    && mkdir -p /usr/local/source \
    && cd /usr/local/source \
    && wget https://github.com/owntracks/recorder/archive/$VERSION.tar.gz \
    && tar xzf $VERSION.tar.gz \
    && cd recorder-$VERSION \
    # dirty hack for 32bit memory limit # https://github.com/owntracks/recorder/issues/348
    && sed -i 's/^#define LMDB_DB_SIZE.*$/#define LMDB_DB_SIZE    ((size_t)150 * (size_t)(1024 * 1024))/' gcache.h \
    && mv /config.mk ./ \
    && make \
    && make install \
    && chown appuser:appuser /usr/bin/ocat /usr/sbin/ot-recorder /etc/default/recorder.conf \
    && cd / \
    && chmod 755 /entrypoint.sh \
    && rm -rf /usr/local/source \
    && chmod 755 /usr/local/sbin/recorder-health.sh

VOLUME ["/store", "/config"]

COPY recorder.conf /config/recorder.conf
COPY JSON.lua /config/JSON.lua

# If you absolutely need health-checking, enable the option below.  Keep in
# mind that until https://github.com/systemd/systemd/issues/6432 is resolved,
# using the HEALTHCHECK feature will cause systemd to generate a significant
# amount of spam in the system logs.
# HEALTHCHECK CMD /usr/local/sbin/recorder-health.sh

EXPOSE 8083

ENTRYPOINT ["/entrypoint.sh"]
