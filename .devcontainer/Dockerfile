# See https://aka.ms/devcontainer for more information.
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# [Optional] Uncomment this line to install additional OS packages.
RUN apt-get update \
    && apt-get install -y wget unzip gnupg software-properties-common curl \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && terraform -install-autocomplete \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# [Optional] Set up a non-root user. See https://aka.ms/vscode-remote/containers/non-root-user.
# ARG USERNAME=node
# ARG USER_UID=1000
# ARG USER_GID=$USER_UID
# RUN groupadd --gid $USER_GID $USERNAME \
#     && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
#     && apt-get update && apt-get install -y sudo \
#     && echo $USERNAME ALL=\"(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/$USERNAME \
#     && chmod 0440 /etc/sudoers.d/$USERNAME

# [Optional] Set the default user. Omit if you want to keep the default as root.
# USER $USERNAME
