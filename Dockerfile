FROM amd64/debian:trixie

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ARG GE_PROTON_VERSION=10-27

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      wget \
      xvfb \
      lib32gcc-s1 \
      winbind \
      locales \
      tzdata \
      python3 \
      procps \
      netbase \
      libc6-i386 \
 && rm -rf /var/lib/apt/lists/*

RUN echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8

RUN mkdir -p /opt/steamcmd /opt/ge-proton \
 && wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar zxf - -C /opt/steamcmd \
 && chmod +x /opt/steamcmd/steamcmd.sh

RUN curl -fsSL "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${GE_PROTON_VERSION}/GE-Proton${GE_PROTON_VERSION}.tar.gz" \
  | tar zxf - -C /opt/ge-proton --strip-components=1

COPY astroneer-start.sh /usr/local/bin/astroneer-start
RUN chmod +x /usr/local/bin/astroneer-start

WORKDIR /home/container
