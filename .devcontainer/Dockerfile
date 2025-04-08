FROM python:3.13.2@sha256:0293f851d58c726748c9f5d7dca65528ac2d38887b18a48e5689f6c59ef77ea9

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
