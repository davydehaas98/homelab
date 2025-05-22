FROM python:3.13.3@sha256:e3424acce37cdb1d7f885b2d13c14a550a0b6b96ff8a58d2a08883f3f865fd1e

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
