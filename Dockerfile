FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        dbus \
        libvirt-daemon-system \
        libvirt-daemon-driver-qemu \
        qemu-system-x86 \
        openssh-client \
        openssh-server \
        sudo \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /

ENV LIBVIRT_USER_GID=1000
ENV LIBVIRT_USER_UID=1000
ENV LIBVIRT_USER=libvirt-user

VOLUME /var/run/libvirt

HEALTHCHECK CMD /healthcheck.sh

ENTRYPOINT ["/entrypoint.sh"]
