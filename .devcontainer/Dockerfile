FROM python:3.13.0@sha256:4f3780acb8d126492a8890a1e1715d36773c0cc1865b5aa569ba857548d0f51f

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
