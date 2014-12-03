# docker-xbmc-server
#
# Setup: Clone repo then checkout appropriate version
# For stable (Gotham)
# $ git checkout master
# For experimental (Helix/Kodi)
# $ git checkout experimental
#
# Create your own Build:
# $ docker build --rm=true -t $(whoami)/docker-xbmc-server .
#
# Run your build:
# There are two choices
# - UPnP server and webserver in the background: (replace ip and xbmc data location)
# $ docker run -d --net=host --privileged -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data $(whoami)/docker-xbmc-server
#
# - Run only the libraryscan and quit:
# $ docker run -v /directory/with/xbmcdata:/opt/xbmc-server/portable_data --entrypoint=/opt/xbmc-server/xbmcVideoLibraryScan $(whoami)/docker-xbmc-server --no-test --nolirc -p
#
# See README.md.
# Source: https://github.com/wernerb/docker-xbmc-server
from ubuntu:14.04
maintainer Werner Buck "email@wernerbuck.nl"
# Set locale to UTF8
RUN locale-gen --no-purge en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
# Set Terminal to non interactive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
# Install java, git wget and supervisor
RUN apt-get update && \
apt-get -y install git openjdk-7-jre-headless supervisor
# Download XBMC, pick version from github
RUN git clone https://github.com/escoand/xbmc-server.git -b Gotham --depth=1 xbmc && \
cd xbmc && \
git remote add upstream git://github.com/xbmc/xbmc.git && \
git checkout -b Gotham origin/Gotham && \
git checkout Gotham && \
ADD src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Installs xbmc dependencies, configure, make, clean.
# Taken out of the list of dependencies: libbluetooth3. Put in the list: libssh-4 libtag1c2a libcurl3-gnutls libnfs1
RUN apt-get install -y build-essential gawk pmount libtool nasm yasm automake cmake gperf zip unzip bison libsdl-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-mixer1.2-dev libfribidi-dev liblzo2-dev libfreetype6-dev libsqlite3-dev libogg-dev libasound2-dev python-sqlite libglew-dev libcurl3 libcurl4-gnutls-dev libxrandr-dev libxrender-dev libmad0-dev libogg-dev libvorbisenc2 libsmbclient-dev libmysqlclient-dev libpcre3-dev libdbus-1-dev libjasper-dev libfontconfig-dev libbz2-dev libboost-dev libenca-dev libxt-dev libxmu-dev libpng-dev libjpeg-dev libpulse-dev mesa-utils libcdio-dev libsamplerate-dev libmpeg3-dev libflac-dev libiso9660-dev libass-dev libssl-dev fp-compiler gdc libmpeg2-4-dev libmicrohttpd-dev libmodplug-dev libssh-dev gettext cvs python-dev libyajl-dev libboost-thread-dev libplist-dev libusb-dev libudev-dev libtinyxml-dev libcap-dev autopoint libltdl-dev swig libgtk2.0-bin libtag1-dev libtiff-dev libnfs1 libnfs-dev libxslt-dev libbluray-dev && \
cd xbmc && \
./bootstrap && \
./configure \
--enable-nfs \
--enable-upnp \
--enable-shared-lib \
--enable-ssh \
--enable-libbluray \
--disable-debug \
--disable-vdpau \
--disable-vaapi \
--disable-crystalhd \
--disable-vdadecoder \
--disable-vtbdecoder \
--disable-openmax \
--disable-joystick \
--disable-xrandr \
--disable-rsxs \
--disable-projectm \
--disable-rtmp \
--disable-airplay \
--disable-airtunes \
--disable-dvdcss \
--disable-optical-drive \
--disable-libusb \
--disable-libcec \
--disable-libmp3lame \
--disable-libcap \
--disable-udev \
--disable-libvorbisenc \
--disable-asap-codec \
--disable-afpclient \
--disable-goom \
--disable-fishbmc \
--disable-spectrum \
--disable-waveform \
--disable-avahi \
--disable-non-free \
--disable-texturepacker \
--disable-pulse \
--disable-dbus \
--disable-alsa \
--disable-hal && \
make -j2 && \
cp libxbmc.so /lib && \
ldconfig && \
cd xbmc && \
make -f make_xbmc-server all && \
make -f make_xbmcVideoLibraryScan all && \
mkdir -p /opt/xbmc-server/portable_data/ && \
cp xbmc-server xbmcVideoLibraryScan /opt/xbmc-server && \
cd .. && \
cp -R addons language media sounds system userdata /opt/xbmc-server/
#Eventserver and webserver respectively.
EXPOSE 9777/udp 8089/tcp
ENTRYPOINT ["/usr/bin/supervisord"]
