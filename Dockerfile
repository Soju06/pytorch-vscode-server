FROM pytorch/pytorch:2.2.2-cuda12.1-cudnn8-devel

# ====================================
# Build Arguments
# ====================================
# Set the Ubuntu APT mirror (Default: "")
ARG UBUNTU_APT_MIRROR=""
# Set the Python version (Default: 3.11.9)
ARG PYTHON_VERSION=3.11.9
# Set the Conda environment name (Default: pt311)
ARG CONDA_ENVIRONMENT_NAME=pt311
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

# Change the apt source
RUN if [ -n "${UBUNTU_APT_MIRROR}" ]; then sed -i "s|http://.*.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g" /etc/apt/sources.list; fi
RUN apt update

# Install dependencies
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
    
# Clean up
RUN apt clean && rm -rf /var/lib/apt/lists/*

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

# Set the workspace
RUN mkdir -p ${WORKSPACE}
RUN chown -R ${UID}:${GID} ${WORKSPACE} ${HOME}

USER ${USER}
WORKDIR ${WORKSPACE}

# Install VSCode server
RUN mkdir -p $VSCODE_HOME
RUN curl -fsSL https://code-server.dev/install.sh | sudo sh

# Install Python
RUN conda create -n ${CONDA_ENVIRONMENT_NAME} pytorch torchvision torchaudio pytorch-cuda=12.1 python==${PYTHON_VERSION} -c pytorch -c nvidia --yes
COPY ./requirements.txt requirements.txt
RUN conda init bash
RUN bash -c "source activate ${CONDA_ENVIRONMENT_NAME} && pip install -r requirements.txt"
RUN conda clean --all --yes && rm -rf ${HOME}/.cache/pip requirements.txt
RUN echo "conda activate ${CONDA_ENVIRONMENT_NAME}" >> ${HOME}/.bashrc

COPY ./entrypoint.sh /entrypoint.sh

EXPOSE 22
EXPOSE 443

ENTRYPOINT /entrypoint.sh \
    code-server \
    --bind-addr 0.0.0.0:443 \
    --extensions-dir ${VSCODE_HOME}/extensions \
    --user-data-dir ${VSCODE_HOME}/data \
    --disable-telemetry \
    .