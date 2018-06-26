FROM python:3.5-alpine

WORKDIR /opt/app

COPY ./main.py ./
COPY ./requirements.txt ./

RUN pip3 install -r requirements.txt

EXPOSE 4444

CMD [ "python3", "./main.py" ]
