#!/bin/bash -e
pip install setuptools --no-use-wheel --upgrade
pip install "$@"
