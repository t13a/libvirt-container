FROM debian:trixie

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
    sshpass \
    libvirt-clients \
    virt-install \
    qemu-utils \
    genisoimage \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir \
    ansible \
    molecule

RUN useradd --uid 1000 --create-home --shell /bin/bash testrunner

USER testrunner
WORKDIR /home/testrunner
