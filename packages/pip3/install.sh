#!/bin/bash -e
pip3 install setuptools --no-binary --upgrade
pip3 install "$@"
