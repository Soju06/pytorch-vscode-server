$VERSION = "1.0.2"

function PrintHelp {
    Write-Host "Usage: $args[0] [OPTIONS]"
    Write-Host "Options:"
    Write-Host "  -h, --help"
    Write-Host "  -p, --python PYTHON_VERSION"
    Write-Host "  -t, --pytorch PYTORCH_VERSION"
    Write-Host "  -c, --cuda CUDA_VERSION"
    Write-Host "  -m, --mirror UBUNTU_APT_MIRROR"
    Write-Host "  --restore_mirror_after_build"
}

$PYTHON_VERSION = "3.11.9"
$PYTORCH_VERSION = "2.2.2"
$CUDA_VERSION = "12.1"
$UBUNTU_APT_MIRROR = ""
$RESTORE_APT_MIRROR_AFTER_BUILD = "false"

while ($args.Count -gt 0) {
    switch ($args[0]) {
        { @("-p", "--python") -contains $_ } {
            $args = $args[1..$args.Count]
            $PYTHON_VERSION = $args[0]
        }
        { @("-t", "--pytorch") -contains $_ } {
            $args = $args[1..$args.Count]
            $PYTORCH_VERSION = $args[0]
        }
        { @("-c", "--cuda") -contains $_ } {
            $args = $args[1..$args.Count]
            $CUDA_VERSION = $args[0]
        }
        { @("-m", "--mirror") -contains $_ } {
            $args = $args[1..$args.Count]
            $UBUNTU_APT_MIRROR = $args[0]
        }
        { @("-h", "--help") -contains $_ } {
            PrintHelp
            Exit
        }
        { "--restore_mirror_after_build" -eq $_ } {
            $RESTORE_APT_MIRROR_AFTER_BUILD = "true"
        }
        default {
            PrintHelp
            Exit 1
        }
    }
    $args = $args[1..$args.Count]
}

$TAG_VERSION = "$VERSION-pytorch$PYTORCH_VERSION-cuda$CUDA_VERSION"
$IMAGE_NAME = "pytorch-vscode-server:$TAG_VERSION"
Write-Host "Building pytorch-vscode-server:$IMAGE_NAME"

docker build . `
    --tag "ghcr.io/soju06/$IMAGE_NAME" `
    --build-arg "PYTHON_VERSION=$PYTHON_VERSION" `
    --build-arg "PYTORCH_VERSION=$PYTORCH_VERSION" `
    --build-arg "CUDA_VERSION=$CUDA_VERSION" `
    --build-arg "UBUNTU_APT_MIRROR=$UBUNTU_APT_MIRROR" `
    --build-arg "RESTORE_APT_MIRROR_AFTER_BUILD=$RESTORE_APT_MIRROR_AFTER_BUILD" `
    --label "org.opencontainers.image.base.name=docker.io/pytorch/pytorch:$PYTORCH_VERSION-cuda$CUDA_VERSION-cudnn8-devel" `
    --label "org.opencontainers.image.ref.name=ghcr.io/soju06/$IMAGE_NAME" `
    --label "org.opencontainers.image.version=$TAG_VERSION" `
    --label "org.opencontainers.image.created=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')"