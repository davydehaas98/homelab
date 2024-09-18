FROM python:3.12.6@sha256:7859853e7607927aa1d1b1a5a2f9e580ac90c2b66feeb1b77da97fed03b1ccbe

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
