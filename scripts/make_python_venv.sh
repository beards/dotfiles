#!/bin/bash

virtualenv --distribute .venv

echo 'source $( dirname "${BASH_SOURCE[0]}" )/.venv/bin/activate' > .env

