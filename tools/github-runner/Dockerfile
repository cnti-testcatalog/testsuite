FROM myoung34/github-runner:latest 


RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN apt-get install apt-transport-https --yes && \
    curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install helm uuid-runtime

RUN curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.11.1/kind-$(uname)-amd64" && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin

    