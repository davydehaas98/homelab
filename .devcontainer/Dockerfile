FROM python:3.13.3@sha256:1f7ef1e8f35bc8629b05f4df943175f2851ba05f4a509f72304ebffde78178ee

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
