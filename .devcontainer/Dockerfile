FROM debian:stable-slim
# Install any additional packages you need
RUN apt-get update && \
    apt install -y git curl mariadb-client
    # You'd also want sshd if not auto-installed.

# For VSCode
RUN adduser --disabled-password --gecos "" vscode && adduser vscode sudo && \
    # Not mandatory but conventional
    mkdir -p /workspace && chown vscode:vscode /workspace && \
    # Useful but not mandatory
    apt install -y sudo

# For Flutter
RUN apt install -y xz-utils zip unzip

# Tried using Chromium from VSCode for debugging. Doesn't work...
# RUN apt install chromium
    # Also consider `chromium`, or `chromium-l10n` for multi-language inputs
# ENV CHROME_EXECUTABLE="/usr/bin/chromium"

RUN mkdir -p /opt/app && chown vscode:vscode /opt/app

USER vscode

ARG FLUTTER_XZ=flutter_linux_3.29.0-stable.tar.xz

WORKDIR /opt/app

# Download the source and put it in the layer
# Extracts archive as /opt/app/flutter
RUN curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/"$FLUTTER_XZ" | tar -xJ -C ./

ENV PATH="/opt/app/flutter/bin:$PATH"

WORKDIR /workspace

RUN flutter doctor && flutter --disable-analytics

# Do this in the source folder
RUN  flutter build web