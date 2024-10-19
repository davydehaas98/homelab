FROM python:3.13.0@sha256:b25527835f75e24162a1277d05f128a53868f34e2c16fa0c645eae18a0590dc8

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
