FROM python:3

COPY ./ /usr/local/aws_batch_tutorial

WORKDIR /usr/local/aws_batch_tutorial

RUN pip install -r requirements.txt