#!/usr/bin/env bash

## ZEROmq related liberaries
git clone --branch=1.0.3 git://github.com/jedisct1/libsodium.git
git clone --branch=v4.1.2 git://github.com/zeromq/zeromq4-1.git
git clone --branch=v3.0.2 git://github.com/zeromq/czmq.git
git clone --branch=master git://github.com/zeromq/malamute.git

## Configure and Install
for project in libsodium zeromq4-1 czmq malamute; do
    cd $project && \
    ./autogen.sh && \
    ./configure &&
    make check && \
    make install && \
    ldconfig && \
    cd ..
done

## BPM related
git clone --branch=v0.1 git://github.com/lnls-dig/bpm-gw.git
git clone --branch=master git://github.com/lnls-dig/bpm-sw.git
git clone --branch=v0.1 git://github.com/lnls-dig/bpm-sw-cli.git
git clone --branch=master git://github.com/lnls-dig/bpm-ipmi.git

## Initialize all repositories
for project in bpm-gw bpm-sw bpm-sw-cli bpm-ipmi; do
    cd $project && \
    git submodule update --init --recursive && \
    cd ..
done
