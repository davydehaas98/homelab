FROM python:3.13.2@sha256:8c55c44b9e81d537f8404d0000b7331863d134db87c1385dd0ec7fefff656495

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
