FROM python:3.13.1@sha256:08371fabbdb8fd1c1256fa96492a27339bf60cba3cb26af7a2e5a56bc5060af4

RUN pip install --upgrade pip

COPY requirements.txt /requirements.txt
RUN pip install -r requirements.txt

COPY requirements.yaml /requirements.yaml
RUN ansible-galaxy install -r requirements.yaml

WORKDIR /ansible
