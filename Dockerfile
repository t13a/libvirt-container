FROM debian:trixie

RUN apt-get update && apt-get install -y \
    libvirt-daemon-system \
    qemu-system-x86 \
    openssh-server \
    sudo \
    virt-install \
    libvirt-clients \
    qemu-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-entrypoint.d/ /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.sh

HEALTHCHECK CMD su healthcheck -c 'virsh connect'

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/docker-entrypoint.sh"]
