FROM python:3.13.1@sha256:220d07595f288567bbf07883576f6591dad77d824dce74f0c73850e129fa1f46

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
