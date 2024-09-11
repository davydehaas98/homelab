FROM python:3.12@sha256:73840b2eacd375e9ab38d65c5ccca1f98524cabccbdc4f9d0932a55d1967a1ab

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
