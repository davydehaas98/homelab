FROM python:3.13.3@sha256:f3210a082bd093de885875de43a3338f4089860806d78a74de7ed4e58d12630c

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
