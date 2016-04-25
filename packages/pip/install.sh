#!/bin/bash -e
pip install setuptools --no-binary --upgrade
pip install "$@"
