ARG DELEGATE_TAG=22.09.76822
FROM harness/delegate-immutable:$DELEGATE_TAG

USER 0

RUN microdnf update -y && microdnf install -y unzip git curl jq

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install TF
RUN curl -O -L  https://releases.hashicorp.com/terraform/1.3.1/terraform_1.3.1_linux_amd64.zip \
  && unzip terraform_1.3.1_linux_amd64.zip \
  && mv ./terraform /usr/bin/ \
  && terraform --version

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && aws --version

# Install GCP CLI
RUN echo -e "[google-cloud-cli] \n\
name=Google Cloud CLI \n\
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64 \n\
enabled=1 \n\
gpgcheck=1 \n\
repo_gpgcheck=0 \n\
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" | tee /etc/yum.repos.d/google-cloud-sdk.repo && microdnf install google-cloud-cli

# Install Azure CLI
# RUN echo -e "[azure-cli] \n\
# name=Azure CLI \n\
# baseurl=https://packages.microsoft.com/yumrepos/azure-cli \n\
# enabled=1 \n\
# gpgcheck=1 \n\
# gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo && microdnf install azure-cli

USER 1001