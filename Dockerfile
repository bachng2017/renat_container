# base information
FROM centos:7
LABEL maintainer="bachng@gmail.com"

# adjust yum to support all locale
RUN sed -i 's/\(override_install_langs.*\)/# \1/g' /etc/yum.conf

# parameters
ARG NTP_SERVER=10.128.3.103
ARG RENAT_PASS=password!secret
ARG HTTP_PROXY=http://10.128.3.103:4713
ARG HTTPS_PROXY=http://10.128.3.103:4713


# setting environment
ENV http_proxy="$HTTP_PROXY" https_proxy="$HTTPS_PROXY"
ENV HOME=/home/robot
ENV RENAT_PATH=$HOME/work/renat
RUN echo "LANG=en_US.utf-8" >> /etc/environment && \
echo "LC_ALL=en_US.utf-8" >> /etc/environment

# install packages
### update yum and install dev package
RUN yum update -y && \
yum -y groupinstall "Development Tools"

### install Python 3.x env
RUN yum clean all && rm -rf /var/cache/yum/*
RUN yum install -y epel-release && \
sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo && \
yum install -y python36 python36-libs python36-devel python36-pip && \
pip3.6 install --upgrade pip

## add ELK repository
ADD files/etc/yum.repos.d /etc/yum.repos.d/

### add neccesary packages by yum
RUN yum install -y numpy net-snmp net-snmp-devel net-snmp-utils czmq czmq-devel python36u-tkinter xorg-x11-server-Xvfb  vim httpd xorg-x11-fonts-75dpi  nfs samba4 samba-client samba-winbind cifs-utils tcpdump hping3 telnet nmap wireshark java-1.8.0-openjdk firefox telnet ld-linux.so.2 ghostscript ImageMagick vlgothic-fonts vlgothic-p-fonts ntp openssl sudo openssh-server sshpass filebeat rsyslog wkhtmltopdf
ADD files/requirements.txt /tmp/
RUN pip3.6 install -r /tmp/requirements.txt

### add more packages by rpm
RUN mkdir -p /root/work/download 
WORKDIR /root/work/download
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.21.0/geckodriver-v0.21.0-linux64.tar.gz && \
tar xzvf /root/work/download/geckodriver-v0.21.0-linux64.tar.gz -C /usr/local/bin

### install jenkins
RUN wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo && \
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key

### change sudo setting
RUN echo $'\n\
Defaults    env_keep += "PATH PYTHONPATH LD_LIBRARY_PATH MANPATH XDG_DATA_DIRS PKG_CONFIG_PATH RENAT_PATH"\n\
Cmnd_Alias CMD_ROBOT_ALLOW  = /bin/chown,/bin/kill,/usr/local/bin/nmap,/usr/sbin/hping3,/usr/sbin/tcpdump\n\
%renat ALL=NOPASSWD: CMD_ROBOT_ALLOW\n\
%jenkins ALL=NOPASSWD: CMD_ROBOT_ALLOW' > /etc/sudoers.d/renat
RUN chmod 0440 /etc/sudoers.d/renat
RUN sed -i 's/Defaults    secure_path/# &/' /etc/sudoers

### change skeleton setting
ADD files/skel/ /etc/skel/
RUN \
mkdir -p /etc/skel/work && \
chmod 0775 /etc/skel/work && \
sed -i 's/UMASK           077/UMASK           002/' /etc/login.defs

### add a robot account
RUN \
echo "### add the robot account ..." && \
umask 0002 && \
groupadd renat -o -g 5000 && \
useradd robot -u 5000 -g renat && \
echo  "robot:$RENAT_PASS" | chpasswd

### httpd setting
RUN \
gpasswd -a apache renat && \
sed -i -e 's/UserDir disabled/UserDir enabled/' \
       -e 's/\#UserDir public_html/UserDir work/' \
       -e 's/<Directory "\/home\/\*\/public_html">/<Directory "\/home\/\*\/work">/'  /etc/httpd/conf.d/userdir.conf
RUN sed -i 's/text\/plain            txt asc text pm el c h cc hh cxx hxx f90 conf log/text\/plain            txt asc text pm el c h cc hh cxx hxx f90 conf log robot/' /etc/mime.types && \
mkdir -p /var/www/html/renat-doc && \
chown apache:renat /var/www/html/renat-doc/ && \
chmod 0775 /var/www/html/renat-doc/ && \
systemctl enable httpd

### other setting 
RUN \
systemctl enable filebeat && \
systemctl enable ntpd 
ADD files/etc/ /etc/

RUN \
mkdir /var/log/renat && \
chown root:renat /var/log/renat && \
chmod 0775 /var/log/renat && \
mkdir /var/log/filebeat && \
chmod 0775 /var/log/filebeat


### checkout RENAT and customize env
RUN \
echo "### checkout and customize renat..." && \
chmod -R 0775 /home/robot && \
mkdir /opt/renat && \
chmod 0777 /opt/renat && \
usermod -aG wheel robot

# USER robot
# WORKDIR /home/robot/work
ADD --chown=robot:renat renat /home/robot/work/renat
RUN \
chown -R robot:renat /home/robot && \
chmod -R 0775 /home/robot

RUN \ 
echo "### enviroment" && \
/usr/bin/printenv && \
ls -la $HOME/work && \
echo "---" && \
sed -i "s/robot-server: .*/robot-server: 127.0.0.1/g" $RENAT_PATH/config/config.yaml && \
sed -i "s/working-folder: .*/working-folder: \$HOME\/work/g" $RENAT_PATH/config/config.yaml && \
sed -i "s/robot-password: .*/robot-password: password!secret/g" $RENAT_PATH/config/config.yaml && \
sed -i "s/renat-master-folder: .*/renat-master-folder: \$RENAT_PATH\/config/g" /$RENAT_PATH/config/config.yaml && \
sed -i "s/calient-master-path: .*/calient-master-path: /g" $RENAT_PATH/config/config.yaml && \
sed -i "s/ntm-master-path: .*/ntm-master-path: /g" $RENAT_PATH/config/config.yaml && \
sed -i "s/slack-proxy: .*/slack-proxy: 127.0.0.1:8080/g" $RENAT_PATH/config/config.yaml && \
sed -i "/- OpticalSwitch\|- Samurai\|- Tester\|- Arbor\|- Fic/d" $RENAT_PATH/config/config.yaml


### jenkins
USER root
RUN groupadd jenkins -o -g 1000 && \
useradd jenkins -u 1000 -g jenkins && \
usermod -a -G jenkins robot && \
mkdir -p /opt/work/workspace && \
chmod -R 0775 /opt/work && \
chown -R jenkins:jenkins /opt/work 

# cleanup
ENV http_proxy="" https_proxy=""


# startup cmds
USER root
COPY files/tmp/entry.sh /tmp
ENTRYPOINT ["/tmp/entry.sh"]


