FROM ruby:2.7.0-alpine

ARG PUPPET="7.0"
ARG R10K="4"
ARG PUPPET_LINT="4"
# ARG PUPPET_CHECK="2" Too old
ARG PUPPET_SYNTAX="0"
ARG PUPPET_GHOSTBUSTER="0"
ARG OCTOCATALOG_DIFF="0"

RUN apk add --update \
    bash \
    cmake \
    gcc \
    git \
    heimdal-dev \
    make \
    musl-dev \
    vim \
 && rm -rf /var/cache/apk/*

RUN adduser -u 5555 -D puppet
ADD Rakefile /build/Rakefile
RUN rake install -f /build/Rakefile

WORKDIR /build
COPY scripts/ /usr/local/bin
