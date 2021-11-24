FROM public.ecr.aws/lambda/python:3.8

# Python3 doesn't recognize this package yet. https://forums.aws.amazon.com/thread.jspa?messageID=930259
RUN yum update -y && yum install amazon-linux-extras -y \
    && PYTHON=python2 amazon-linux-extras install epel -y \
    && yum install -y clamav clamd clamav-update \
    && yum clean all && rm -rf /var/cache/yum \
    && ln -s /etc/freshclam.conf /tmp/freshclam.conf

RUN python -m pip install --upgrade pip

COPY clamd.conf /etc/clamd.conf

COPY ./requirements.txt ${LAMBDA_TASK_ROOT}/requirements.txt

RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt -t ${LAMBDA_TASK_ROOT} \
    && rm -rf /root/.cache

# Force running freshclam everytime the image is being built, so new antivirus definitions are downloaded
ARG CACHEBUST=1
RUN echo $CACHEBUST && freshclam

COPY function/virus-scanner.py ${LAMBDA_TASK_ROOT}/

CMD [ "virus-scanner.lambda_handler" ]
