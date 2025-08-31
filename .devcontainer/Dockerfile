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


# For Flutter
RUN apt install -y xz-utils zip unzip

RUN mkdir -p /opt/app && chown vscode:vscode /opt/app

USER vscode

ARG FLUTTER_XZ=flutter_linux_3.35.2-stable.tar.xz

WORKDIR /opt/app

# Download the source and put it in the layer
# Extracts archive as /opt/app/flutter
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/"$FLUTTER_XZ" | tar -xJ -C ./

ENV PATH="/opt/app/flutter/bin:$PATH"
ENV EDITOR="vi"

WORKDIR /workspace

RUN flutter doctor && flutter --disable-analytics 
