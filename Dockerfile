FROM debian:jessie

MAINTAINER maugin.thomas@gmail.com
 
RUN apt-get update && \
    apt-get install -y wget libusb-1.0-0-dev pkg-config ca-certificates git-core cmake build-essential --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 
WORKDIR /tmp
RUN echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/raspi-blacklist.conf && \
    git clone git://git.osmocom.org/rtl-sdr.git && \
    mkdir rtl-sdr/build && \
    cd rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
    make && \
    make install && \
    ldconfig && \
    rm -rf /tmp/rtl-sdr

# DUMP1090
WORKDIR /tmp
RUN git clone https://github.com/mutability/dump1090 && \
    cd dump1090 && \
    make && mkdir /usr/lib/fr24 && cp dump1090 /usr/lib/fr24/ && cp -r public_html /usr/lib/fr24/
COPY config.js /usr/lib/fr24/public_html/
RUN mkdir /usr/lib/fr24/public_html/data

# Uncomment if you want to add your upintheair.json file
#COPY upintheair.json /usr/lib/fr24/public_html/

# PIAWARE
WORKDIR /tmp
RUN apt-get update && \
    apt-get install sudo build-essential debhelper tcl8.6-dev autoconf python3-dev python-virtualenv libz-dev net-tools tclx8.4 tcllib tcl-tls itcl3 python3-venv dh-systemd init-system-helpers -y 
RUN git clone https://github.com/flightaware/piaware_builder.git piaware_builder
WORKDIR /tmp/piaware_builder
RUN ./sensible-build.sh jessie && cd package-jessie && dpkg-buildpackage -b && cd .. && dpkg -i piaware_*_*.deb
COPY piaware.conf /etc/

# FR24FEED
WORKDIR /fr24feed
RUN wget $(wget -qO- http://feed.flightradar24.com/raspberry-pi | egrep -Eo 'https?://[^"]+armhf.tgz' | grep -v _obj_ | head -n 1) \
    && tar -xvzf *armhf.tgz
COPY fr24feed.ini /etc/

RUN apt-get update && apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8754 8080 30001 30002 30003 30004 30005 30104 

CMD ["/usr/bin/supervisord"]
