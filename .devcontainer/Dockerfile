FROM python:3.12.6@sha256:14f073695854184b65a82808ea2baa352d49c1a86442f06a90d9c236861c7a8f

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
