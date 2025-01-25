FROM python:3.13.1@sha256:137ae4b9f85671bd912a82a19b6966e2655f73e13579b5d6ad4edbddaaf62a9c

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
