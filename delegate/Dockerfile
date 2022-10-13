FROM harness/delegate-immutable:22.10.77021

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

USER 1001
