FROM centos:7

RUN yum update -y \
    && yum install -y epel-release \
    && yum install -y \
        bash \
        expect \
        git \
        libvirt-client \
        make \
        openssh-clients \
        sshpass \
        virt-install \
    && yum clean all

ARG BATS_CORE_BRANCH=v1.2.1
ARG BATS_CORE_REPOSITORY=https://github.com/bats-core/bats-core

ARG BATS_ASSERT_BRANCH=v2.0.0
ARG BATS_ASSERT_REPOSITORY=https://github.com/bats-core/bats-assert

ARG BATS_FILE_BRANCH=v0.3.0
ARG BATS_FILE_REPOSITORY=https://github.com/bats-core/bats-file

ARG BATS_SUPPORT_BRANCH=v0.3.0
ARG BATS_SUPPORT_REPOSITORY=https://github.com/bats-core/bats-support

RUN git clone -b "${BATS_CORE_BRANCH}" --depth 1 "${BATS_CORE_REPOSITORY}" /opt/bats-core \
    && git clone -b "${BATS_ASSERT_BRANCH}" --depth 1 "${BATS_ASSERT_REPOSITORY}" /opt/bats-assert \
    && git clone -b "${BATS_FILE_BRANCH}" --depth 1 "${BATS_FILE_REPOSITORY}" /opt/bats-file \
    && git clone -b "${BATS_SUPPORT_BRANCH}" --depth 1 "${BATS_SUPPORT_REPOSITORY}" /opt/bats-support \
    && cd /opt/bats-core \
    && ./install.sh /usr/local

RUN useradd -m -s /bin/bash sut \
    && mkdir -m 755 -p /home/sut/.ssh \
    && chown -R sut:sut /home/sut

USER sut
