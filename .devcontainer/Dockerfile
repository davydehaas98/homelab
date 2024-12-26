FROM python:3.13.1@sha256:cea505b81701dd9e46b8dde96eaa8054c4bd2035dbb660edeb7af947ed38a0ad

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
