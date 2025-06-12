FROM python:3.13.4@sha256:307a3e44b2a6c7d9c5fbb8c3a6c46c4c1535cde8eeb85a3ccb3513862f20aaad

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
