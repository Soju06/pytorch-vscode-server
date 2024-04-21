# ====================================
# Build Arguments
# ====================================
# Set the Ubuntu APT mirror (Default: "")
ARG UBUNTU_APT_MIRROR=""
# Set the Python version (Default: 3.11.9)
ARG PYTHON_VERSION=3.11.9
# Set the PyTorch version (Default: 2.2.2)
ARG PYTORCH_VERSION=2.2.2
# Set the CUDA version (Default: 12.1)
ARG CUDA_VERSION=12.1
# Set the Conda environment name (Default: pytorch)
ARG CONDA_ENVIRONMENT_NAME=pytorch
# Set the user and group (Default: ubuntu)
ARG USER=ubuntu
ARG GROUP=ubuntu
# Set the user ID and group ID (Default: 1000)
ARG UID=1000
ARG GID=1000

# Restore the original apt mirror after build. (Default: false)
ARG RESTORE_MIRROR_AFTER_BUILD=false

FROM pytorch/pytorch:${PYTORCH_VERSION}-cuda${CUDA_VERSION}-cudnn8-devel
ARG UBUNTU_APT_MIRROR PYTHON_VERSION PYTORCH_VERSION CUDA_VERSION CONDA_ENVIRONMENT_NAME USER GROUP UID GID RESTORE_APT_MIRROR_AFTER_BUILD

LABEL org.opencontainers.image.title="VSCode Server with PyTorch and CUDA"
LABEL org.opencontainers.image.description="Docker images for machine learning development environments using CUDA and PyTorch and for remote development via VSCode and SSH server"
LABEL org.opencontainers.image.authors="Soju06"
LABEL org.opencontainers.image.vendor="Soju06"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/Soju06/docker-vscode-server"
LABEL org.opencontainers.image.documentation="https://github.com/Soju06/docker-vscode-server"
LABEL org.opencontainers.image.source="https://github.com/Soju06/docker-vscode-server"

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
RUN if [ -n "${UBUNTU_APT_MIRROR}" ]; then sed -i "s|http://archive.ubuntu.com/ubuntu/|${UBUNTU_APT_MIRROR}|g" /etc/apt/sources.list; fi
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
RUN if [ "${RESTORE_APT_MIRROR_AFTER_BUILD}" = "true" ]; then sed -i "s|${UBUNTU_APT_MIRROR}|http://archive.ubuntu.com/ubuntu/|g" /etc/apt/sources.list; fi

# Create a non-root user
RUN groupadd -g ${GID} ${GROUP} && \
    useradd -m -s /bin/bash -u ${UID} -g ${GID} ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir -p ${HOME}/.ssh
RUN chown -R ${UID}:${GID} ${HOME}/.ssh
RUN chmod 700 ${HOME}/.ssh
RUN touch ${HOME}/.ssh/authorized_keys
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