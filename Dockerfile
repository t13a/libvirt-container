FROM centos:7

# @ref https://hub.docker.com/r/centos/systemd
RUN rm -f /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup.service \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

RUN yum -y install \
        libvirt-daemon-kvm \
        openssh-server \
        rsync \
        socat \
        sudo \
        virt-install \
    && yum clean all \
    && systemctl enable libvirtd.service sshd.service

COPY rootfs /

ENV SSH_USER=user
ENV SSH_UID=1000
ENV SSH_GID=1000

VOLUME /sys/fs/cgroup

ENTRYPOINT ["/entrypoint.sh"]
