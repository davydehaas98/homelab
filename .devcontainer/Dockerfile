FROM python:3.13.3@sha256:884da97271696864c2eca77c6362b1c501196d6377115c81bb9dd8d538033ec3

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
