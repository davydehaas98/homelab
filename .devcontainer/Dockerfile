FROM python:3.13.4@sha256:b89c8a45626cd670f81e0504084362c7e88dd432090b08f6de1b7b047fcf6c4a

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
