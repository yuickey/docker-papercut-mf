FROM ubuntu:xenial
LABEL maintainer="Thomas Stägemann <staegi@github>"
LABEL description="PaperCut MF Application Server"

# Creating 'papercut' user
RUN useradd -mUd /papercut -s /bin/bash papercut

# Installing necessary pacakges and cleaning up
#RUN apt-get update && apt-get install -y curl cpio cups && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
       cpio \
       cups \
       cups-daemon \
       curl \
       samba \
       wget \
       net-tools \
       iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PAPERCUT_MAJOR_VER 21.x
ENV PAPERCUT_VER 21.0.4.57587
ENV PAPERCUT_DOWNLOAD_URL https://cdn1.papercut.com/web/products/ng-mf/installers/mf/${PAPERCUT_MAJOR_VER}/pcmf-setup-${PAPERCUT_VER}.sh

# Downloading Papercut and ensuring it's executable
RUN curl -L "${PAPERCUT_DOWNLOAD_URL}" -o /pcmf-setup.sh && chmod a+rx /pcmf-setup.sh

# Running the installer as papercut user and running root tasks as root user
RUN runuser -l papercut -c "/pcmf-setup.sh --non-interactive" && rm -f /pcmf-setup.sh && /papercut/MUST-RUN-AS-ROOT

# Stopping Papercut services before capturing image
RUN /etc/init.d/papercut stop && /etc/init.d/papercut-web-print stop

WORKDIR /papercut
VOLUME /papercut/server/data/conf /papercut/server/custom /papercut/server/logs /papercut/server/data/backups /papercut/server/data/archive
EXPOSE 9191 9192 9193
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/backup-license.sh"]

# Downloading and installing MySQL connector
ENV MYSQL_CONNECTOR_VERSION 8.0.17
ENV MYSQL_CONNECTOR_DOWNLOAD_URL https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz

RUN curl -L "${MYSQL_CONNECTOR_DOWNLOAD_URL}" -o /mysql.tar.gz \
	&& tar -xvzf /mysql.tar.gz -C / \
    && mv /mysql-connector-java-${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar /papercut/server/lib-ext/ \
    && rm -r /mysql-connector-java-${MYSQL_CONNECTOR_VERSION} \
    && rm /mysql.tar.gz

# Downloading and installing envsubst
ENV ENVSUBST_DOWNLOAD_URL https://github.com/a8m/envsubst/releases/download/v1.1.0/envsubst-Linux-x86_64
RUN curl -L "${ENVSUBST_DOWNLOAD_URL}" -o /usr/local/bin/envsubst
RUN chmod +x /usr/local/bin/envsubst

COPY server.properties.template /
COPY backup-license.sh /
COPY entrypoint.sh /
RUN chmod +x /backup-license.sh /entrypoint.sh
