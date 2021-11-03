FROM ubi8/ubi
MAINTAINER Oren Oichman <Back to Root>

RUN dnf install -y nc httpd mod_ssl jq && \
        dnf clean all

COPY run-httpd.sh /usr/sbin/run-httpd.sh
RUN echo "PidFile /tmp/http.pid" >> /etc/httpd/conf/httpd.conf
RUN sed -i "s/Listen\ 80/Listen\ 8080/g"  /etc/httpd/conf/httpd.conf
RUN sed -i "s/\"logs\/error_log\"/\/dev\/stderr/g" /etc/httpd/conf/httpd.conf
RUN sed -i "s/CustomLog \"logs\/access_log\"/CustomLog \/dev\/stdout/g" /etc/httpd/conf/httpd.conf
RUN echo 'ScriptSock /tmp/cgid.sock' >> /etc/httpd/conf/httpd.conf
RUN echo 'IncludeOptional /opt/app-root/*.conf' >> /etc/httpd/conf/httpd.conf && \
         rm -f /etc/httpd/conf.d/ssl.conf && \
         mkdir /opt/app-root/ && \
         chown apache:apache /opt/app-root/ && \
         chmod 777 /opt/app-root/

COPY cgi.conf /opt/app-root/
RUN mkdir /opt/app-root/cgi-bin && \
          chown apache:apache /opt/app-root/cgi-bin && \
          chmod 777 /opt/app-root/cgi-bin

COPY index.sh /opt/app-root/cgi-bin/
USER apache

EXPOSE 8080
CMD ["/usr/sbin/run-httpd.sh"]
ENTRYPOINT ["/usr/sbin/run-httpd.sh"]
