#!/bin/bash -e
wget http://peak.telecommunity.com/dist/ez_setup.py
python ez_setup.py && rm -f ez_setup.py
easy_install pip
