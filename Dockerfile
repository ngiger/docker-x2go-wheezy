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
RUN apt-get install locales locales-all
# ENV LANG de_CH.UTF-8
# RUN export export LANG=de_CH.UTF-8 && dpkg-reconfigure -phigh locales

RUN apt-get install -y openssh-server sudo vim wget unzip awesome

RUN apt-key adv --recv-keys --keyserver keys.gnupg.net E1F958385BFE2B6E
RUN mkdir -p /etc/apt/sources.list.d && echo deb http://packages.x2go.org/debian wheezy main > /etc/apt/sources.list.d/x2go.list
RUN apt-get update && apt-get install -y x2go-keyring && apt-get update
RUN apt-get install x2goserver x2goserver-xsession pwgen -y
RUN apt-get install -y kde-l10n-de kde-l10n-fr kde-plasma-desktop
RUN apt-get -qqy install openjdk-7-jdk libreoffice iceweasel chromium-browser
# pulseaudio
RUN chmod -R 0777 /var/lib/x2go

# Install Elexis opensource
#--------------------------
# First idea
# RUN mkdir -p /opt/downloads && cd /opt/downloads && wget --quiet --no-check-certificate https://srv.elexis.info/jenkins/view/3.0/job/Elexis-3.0-Core/lastSuccessfulBuild/artifact/ch.elexis.core.p2site/target/products/ch.elexis.core.application.ElexisApp-linux.gtk.x86_64.zip
# RUN mkdir /usr/local/Elexis3 && cd /usr/local/Elexis3 && unzip /opt/downloads/ch.elexis.core.application.ElexisApp-linux.gtk.x86_64.zip
# Second idea: using director to add some more useful plugins
ADD install_elexis_snapshot.sh /
RUN chmod +x /install_elexis_snapshot.sh && /bin/bash -v /install_elexis_snapshot.sh

# add username/password for automatic login into demoDB
RUN echo -Dch.elexis.username test >> /usr/local/Elexis3/Elexis3.ini && echo -Dch.elexis.password test >> /usr/local/Elexis3/Elexis3.ini

# Add menu entry for Elexis 3
ADD Elexis3.desktop  /usr/share/applications/Elexis3.desktop

# Install demoDB for user docker
RUN mkdir -p /opt/downloads && pwd && cd opt/downloads  && wget --quiet http://download.elexis.info/demoDB/demoDB_2_1_7_mit_Administrator.zip
RUN mkdir -p /home/dockerx/elexis && cd /home/dockerx/elexis  && pwd && unzip /opt/downloads/demoDB_2_1_7_mit_Administrator.zip
RUN mkdir -p /root/elexis         && cd /root/elexis          && pwd && unzip /opt/downloads/demoDB_2_1_7_mit_Administrator.zip


# Fix running sshd daemon under Debian
# ------------------------------------
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
RUN sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN sed -i "s/#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config

# Somehow Java6 got installed. Remove it.
RUN apt-get remove --purge openjdk-6-jre openjdk-6-jdk openjdk-6-jre-headless --yes

# configure x2go 
ADD x2go_restart.sh /etc/cron.daily/
ADD run_x2go_elexis.sh /
ADD set_root_pw.sh /
RUN chmod +x /run_x2go_elexis.sh /set_root_pw.sh /etc/cron.daily/x2go_restart.sh
EXPOSE 22
CMD /run_x2go_elexis.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

