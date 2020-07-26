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

RUN rm /usr/share/dbus-1/system-services/org.freedesktop.{hostname1,import1,locale1,login1,machine1,systemd1,timedate1}.service

COPY rootfs /

ENV LIBVIRT_USER_GID=1000
ENV LIBVIRT_USER_UID=1000
ENV LIBVIRT_USER=libvirt-user

HEALTHCHECK CMD /healthcheck.sh

ENTRYPOINT ["/entrypoint.sh"]
