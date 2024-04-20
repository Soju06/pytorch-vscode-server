FROM pytorch/pytorch:2.2.2-cuda12.1-cudnn8-devel

# ====================================
# Build Arguments
# ====================================
# Set the Python version (Default: 3.11.9)
ARG PYTHON_VERSION=3.11.9
# Set the user and group (Default: ubuntu)
ARG USER=ubuntu
ARG GROUP=ubuntu
# Set the user ID and group ID (Default: 1000)
ARG UID=1000
ARG GID=1000

# ====================================
# Environment Variables
# ====================================
# VSCode Server - Password
ENV PASSWORD=password
# SSH - Public Key (Optional - If you want to use the SSH)
ENV SSH_PUBLIC_KEY=""
# User home directory (Default: /home/ubuntu)
ENV HOME=/home/${USER}
# Workspace directory (Default: /workspace)
ENV WORKSPACE=/workspace
# VSCode Server directory (Default: /workspace/.code-server)
ENV VSCODE_HOME=${WORKSPACE}/.code-server

# Install dependencies
RUN apt update
RUN apt install -y \
    dumb-init \
    sudo \
    curl \
    htop \
    git \
    nano \
    wget \
    openssh-server \
    unzip \
    software-properties-common \
    build-essential

# Install Python3.11
RUN mkdir -p /tmp/python && curl -L https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz | tar -xJ -C /tmp/python
RUN cd /tmp/python/Python-${PYTHON_VERSION} && ./configure --enable-optimizations && make altinstall && rm -rf /tmp/python

# Install Python packages
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && pip install -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Create a non-root user
RUN groupadd -g ${GID} ${GROUP} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir -p ${HOME}/.ssh
RUN touch ${HOME}/.ssh/authorized_keys
RUN chown -R ${UID}:${GID} ${HOME}/.ssh
RUN chmod 700 ${HOME}/.ssh
RUN chmod 600 ${HOME}/.ssh/authorized_keys

# Disable password authentication
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Clean up
RUN apt clean && rm -rf /var/lib/apt/lists/*

# Set the workspace
RUN mkdir -p ${WORKSPACE}
RUN chown -R ${UID}:${GID} ${WORKSPACE} ${HOME}

USER ${USER}
WORKDIR ${WORKSPACE}

# Install VSCode server
RUN mkdir -p ${VSCODE_HOME}
RUN curl -fsSL https://code-server.dev/install.sh | sudo sh

COPY ./entrypoint.sh /entrypoint.sh

EXPOSE 22
EXPOSE 443

ENTRYPOINT [ \
    "/entrypoint.sh", \
    "code-server", \
    "--bind-addr", "0.0.0.0:443", \
    "--extensions-dir", "${VSCODE_HOME}/extensions", \
    "--user-data-dir", "${VSCODE_HOME}/data", \
    "--disable-telemetry", \
    "--disable-update-check", \
    "--disable-crash-reporter", \
    "." \
]