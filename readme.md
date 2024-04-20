# PyTorch VSCode Server with CUDA

Docker images for machine learning development environments using CUDA and PyTorch and for remote development via VSCode and SSH server

## Features

- CUDA 12.1
- Python 3.11.9
- PyTorch 2.2.2
- Code Server
- SSH Server
- \+ Other tools (e.g. git, wget, curl, unzip, etc.)
- \+ Python packages (e.g. numpy, pandas, matplotlib, tensorboard, etc.)

## Usage

```bash
docker run -d \
  -p 5443:443 \
  -p 5022:22 \
  --gpus '"device=0"' \
  -e PASSWORD="your_vscode_password" \
  --name pytorch-vscode-server \
  ghcr.io/Soju06/pytorch-vscode-server:2.2.2-cuda12.1
```

- Access VSCode Server: `https://localhost:5443`
- SSH: `ssh ubuntu@localhost -p 5022 -i ~/.ssh/id_rsa` (only key-based authentication, If you do not set up `SSH_PUBLIC_KEY`, SSH Server will not run.)

If you want to use SSH Server, you need to set `SSH_PUBLIC_KEY` environment variable.

```bash
docker run -d \
  -p 5443:443 \
  -p 5022:22 \
  --gpus '"device=0"' \
  -e PASSWORD="your_vscode_password" \
  -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" \
  --name pytorch-vscode-server \
  ghcr.io/Soju06/pytorch-vscode-server:2.2.2-cuda12.1
```

### Build Arguments

- `PYTHON_VERSION`: Set the Python version. Default is `3.11.9`
- `USER`: Set the user name. Default is `ubuntu`
- `GROUP`: Set the group name. Default is `ubuntu`
- `UID`: Set the user id. Default is `1000`
- `GID`: Set the group id. Default is `1000`

### Environment Variables

- `PASSWORD`: Set the password for VSCode Server. Default is `password`
- `SSH_PUBLIC_KEY`: Set the public key for SSH Server. Default is empty
- `HOME`: Set the home directory. Default is `/home/ubuntu`
- `WORKSPACE`: Set the workspace directory. Default is `/workspace`
- `VSCODE_HOME`: Set the VSCode Server home directory. Default is `/workspace/.code-server`
