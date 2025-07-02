FROM python:3.13.5@sha256:9a4c72e547e3e21c5325a53289a52a21cd6f737358b2f83035c860647547051b

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
