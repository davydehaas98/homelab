FROM python:3.13.3@sha256:34dc8eb488136014caf530ec03a3a2403473a92d67a01a26256c365b5b2fc0d4

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
