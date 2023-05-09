# specify the base image:tag
FROM python:3.9-alpine3.13

# best practice to tell who maintains th code eg name, website etc.
LABEL maintainer="urekmazth"

# recommended for running python in containers. Tells python not to buffer the output
# output from python will be printed directly to the console without any delays
ENV PYTHONUNBUFFERED 1

# copy files from current folder into container (linux based alpine)
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app/ /app
# specify the working directory in which our commands will be ran
WORKDIR /app

# specify the port opened inside the container
EXPOSE 8000

# adds a build arg DEV with default value false
ARG DEV=false
# using a single RUN command to run multiple instructions broken down using && is better as it makes building light weight containers compared to multiple RUN commands which each add a layer
# create a virtual environment in /py and
# upgrade the version of pip and
# install postgresql adaptor (psycopg2) dependencies (for compilation in an alpine environment) since the adaptor compiles from source
# postgresql-client allows connection to our postgres db thus not deleted as the other dependencies (musl-dev and postgresql-dev)
# the --virtual option groups the dependencies in a virtual group called .tmp-build-deps thus easy to delete later
# install dependencies from /tmp/requirements.txt and
# if build arg DEV is true, install dev dependencies fron /tmp/requirements.dev.txt and
# delete recursively by force /tmp
# delete the psycopg2 dependencies (in .tmp-build-deps) as no more(musl-dev and postgresql-dev) needed after the installation of psycopg2 was completed
# create a user (linux) called django-user with np password and no home dir (keep the container lightweight as possible)
# its best practice to use the another user instead of the root user
RUN python -m venv /py && \
        /py/bin/pip install --upgrade pip && \
        apk add --update --no-cache postgresql-client && \
        apk add --update --no-cache --virtual .tmp-build-deps \
            build-base postgresql-dev musl-dev && \
        /py/bin/pip install -r /tmp/requirements.txt && \
        if [ $DEV = "true" ]; \
            then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
        fi && \
        rm -rf /tmp && \
        apk del .tmp-build-deps && \
        adduser \
            --disabled-password \
            --no-create-home \
            django-user

# updates the PATH environment var inside the container
# this adds /py/bin to the system path thus no need to write the full path each time in our commands
ENV PATH="/py/bin:$PATH"

# all the previous commands were ran by the root user
# switch user to django-user
USER django-user