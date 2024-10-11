FROM python:3.13.0@sha256:45803c375b95ea33f482e53a461eca8f247617667d703660a06ccf5eb3d05326

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
