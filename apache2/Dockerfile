# Debian wheezy mit x2go

FROM debian:wheezy
MAINTAINER Niklaus Giger "niklaus.giger@member.fsf.org"

# Set correct environment variables.
ENV HOME /root

RUN apt-get update && apt-get  upgrade -y

ENV DEBIAN_FRONTEND noninteractive

# Proxy problems
# need somewhere a squid-deb-proxy running on the local network
# but squid-deb-proxy-client needs avahi-daemon which does not work easily inside a container
# Upgrading to apt-cacher-ng (0.7.26-2) on the server side helped!

#----------------------------------------------------------------

RUN echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" > /etc/apt/sources.list.d/backports.list

RUN echo 'Acquire::http::Proxy "http://172.25.1.70:3142";' >  /etc/apt/apt.conf.d/proxy
RUN apt-get update && apt-get  upgrade -y

RUN apt-get install -y syslog-ng apt-utils
# Set locale (fix the locale warnings)
RUN apt-get install -y openssh-server sudo vim wget unzip apache2

RUN apt-key adv --recv-keys --keyserver keys.gnupg.net E1F958385BFE2B6E
RUN mkdir -p /etc/apt/sources.list.d && echo deb http://packages.x2go.org/debian wheezy main > /etc/apt/sources.list.d/x2go.list
RUN apt-get update && apt-get install -y x2go-keyring && apt-get update
RUN apt-get install x2goplugin -y

ADD x2goplugin.html /var/www/
RUN chown -R www-data:www-data /var/www

# Fix running sshd daemon under Debian
# ------------------------------------
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
RUN sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN sed -i "s/#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config

# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www

EXPOSE 80
CMD /usr/sbin/apache2 -D FOREGROUND

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

