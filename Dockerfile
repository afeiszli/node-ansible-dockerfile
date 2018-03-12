FROM rhel7

ENV NODE_VERSION 6.11.0

RUN groupadd -g 1001 node 
#    && adduser -u 1001 -G node -s /bin/sh -D node \
#    && yum -y install epel-release && yum repolist \
#    && curl --silent --location https://rpm.nodesource.com/setup_6.11 | sudo bash - \
#    && sudo yum -y install nodejs
RUN adduser -u 1001 -g node -s /bin/sh node
#RUN yum -y install epel-release 
RUN yum-config-manager --enable epel-release
RUN yum repolist
RUN curl --silent --location https://rpm.nodesource.com/setup_6.11 | sudo bash -
RUN sudo yum -y install nodejs


ENV ANSIBLE_VERSION 2.3.0.0
 
ENV BUILD_PACKAGES \
  bash \
  curl \
  tar \
  openssh-client \
  sshpass \
  git \
  python \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-setuptools \
  py-yaml \
  ca-certificates
 
RUN apk --update add --virtual build-dependencies \
  gcc \
  musl-dev \
  libffi-dev \
  openssl-dev \
  python-dev
 
RUN set -x && \
  apk update && apk upgrade && \
  apk add --no-cache ${BUILD_PACKAGES} && \
  pip install --upgrade pip && \
  pip install python-keyczar docker-py && \
  apk del build-dependencies && \
  rm -rf /var/cache/apk/*
 
RUN mkdir -p /etc/ansible/ /ansible
 
RUN echo "[local]" >> /etc/ansible/hosts && \
  echo "localhost" >> /etc/ansible/hosts
 
RUN curl -fsSL https://releases.ansible.com/ansible/ansible-${ANSIBLE_VERSION}.tar.gz -o ansible.tar.gz && \
  tar -xzf ansible.tar.gz -C /ansible --strip-components 1 && \
  rm -fr ansible.tar.gz /ansible/docs /ansible/examples /ansible/packaging
 
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_REMOTE_TEMP ~/ansible/.ansible/tmp
ENV ANSIBLE_LOCAL_TEMP ~/ansible/.ansible/tmp
ENV ANSIBLE_SSH_PIPELINING True
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library

WORKDIR /usr/src/app
 
RUN chown -R 1001 /ansible/
RUN chown -R 1001 /etc/ansible/
RUN chown -R 1001 /usr/src/app
RUN chgrp -R 0 /ansible && \
    chmod -R g=u /ansible
RUN chgrp -R 0 /etc/ansible && \
    chmod -R g=u /etc/ansible
RUN chgrp -R 0 /usr/src/app && \
    chmod -R g=u /usr/src/app

EXPOSE 8080

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

USER 1001

#need to enter vars for app in below line
#RUN touch .env && echo "MASTER_KEY=masterkey" >> .env

CMD [ "npm", "start" ]
