FROM python:3.13.3@sha256:19c3e9658c3bab523c6ddb025464f3707cf3b1297100827bdb6afbf0c937d99f

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
