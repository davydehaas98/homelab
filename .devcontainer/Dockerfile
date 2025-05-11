FROM python:3.13.3@sha256:3abe339a3bc81ffabcecf9393445594124de6420b3cfddf248c52b1115218f04

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
