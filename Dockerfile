FROM centos:7

#ARG http_proxy=http://proxyapps.gsnet.corp:80/
#ARG https_proxy=http://proxyapps.gsnet.corp:80/
#ARG no_proxy=localhost,127.0.0.1,*.corp
#ARG USER_ID=1000
#ARG GROUP_ID=1000

LABEL ALM_IMAGEOWNER="ALM MultiCloud" \
      ALM_DESCRIPTION="Fluentd daemon to run as a sidecar inside the Jenkins pod" \
      ALM_COMPONENTS="vsftpd" \
      ALM_IMAGE_VERSION="v1" \
      maintainer="ALM Multicloud <alm-multicloud@gruposantander.com>"

RUN yum -y update \
        && yum clean all \
        && yum install -y \
        vsftpd \
        db4-utils \
        db4 \
        iproute \
        && yum clean all

ENV FTP_USER **String**
ENV FTP_PASS **Random**

COPY run-vsftpd.sh /usr/sbin/

RUN chmod +x /usr/sbin/run-vsftpd.sh
RUN mkdir -p /home/vsftpd/
RUN chown -R ftp:ftp /home/vsftpd/

# Log to docker stdout (vsftpd must be run as PID 1)
RUN ln -sf /proc/1/fd/1 /var/log/vsftpd.log

VOLUME /home/vsftpd

EXPOSE 20-21 21100-21102

CMD ["/usr/sbin/run-vsftpd.sh"]
