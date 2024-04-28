FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        swig \
        vim \
        gdb \
        valgrind \
        cmake && \
    apt-get clean
