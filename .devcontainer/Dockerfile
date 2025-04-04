FROM python:3.13.1@sha256:7be9b757ea8fa90b43efd604dd5ef2923364230f00564b2ea7f0982d24b374c9

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
