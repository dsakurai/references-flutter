FROM debian:stable-slim
# Install any additional packages you need
RUN apt-get update && \
    apt install -y git curl mariadb-client vim-tiny sudo
    # You'd also want sshd if not auto-installed.

# For VSCode
RUN adduser --disabled-password --gecos "" vscode && adduser vscode sudo && \
    # Not mandatory but conventional
    mkdir -p /workspace && chown vscode:vscode /workspace && \
    # sudo without password
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER vscode
