FROM python:3.13.0@sha256:c590a3669258c6b416f05e4d0ec54197ada40829ee213b1722c545614ea2427a

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
