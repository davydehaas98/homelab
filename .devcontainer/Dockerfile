FROM python:3.12.7@sha256:785fef11f44b7393c03d77032fd72e56af8b05442b051a151229145e5fbbcb29

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
