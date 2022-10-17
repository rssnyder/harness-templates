ARG DELEGATE_TAG=22.09.76822
FROM harness/delegate-immutable:$DELEGATE_TAG

USER 0

RUN microdnf update -y

RUN microdnf install -y unzip git curl jq

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN aws --version

# Install TF
RUN curl -O -L  https://releases.hashicorp.com/terraform/1.3.1/terraform_1.3.1_linux_amd64.zip
RUN unzip terraform_1.3.1_linux_amd64.zip
RUN mv ./terraform /usr/bin/
RUN terraform --version

# Install Azure CLI
RUN echo -e "[azure-cli] \n\
name=Azure CLI \n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo
RUN microdnf install azure-cli

USER 1001
