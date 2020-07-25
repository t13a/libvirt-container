FROM centos:7

RUN yum update -y \
    && yum install -y epel-release \
    && yum install -y \
        libvirt-daemon-kvm \
        openssh-clients \
        openssh-server \
        sudo \
        supervisor \
        virt-install \
    && yum clean all

COPY rootfs /

ENV LIBVIRT_USER_GID=1000
ENV LIBVIRT_USER_UID=1000
ENV LIBVIRT_USER=libvirt-user

HEALTHCHECK CMD healthcheck.sh

ENTRYPOINT ["entrypoint.sh"]
