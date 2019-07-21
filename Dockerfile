FROM centos:7

RUN yum -y install epel-release \
    && yum -y install \
        expect \
        less \
        libvirt-daemon-kvm \
        openssh-clients \
        openssh-server \
        rsync \
        socat \
        sudo \
        supervisor \
        virt-install \
    && yum clean all

COPY rootfs /

ENV SSH_USER=user
ENV SSH_UID=1000
ENV SSH_GID=1000

ENTRYPOINT ["/entrypoint.sh"]
