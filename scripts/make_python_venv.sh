#!/usr/bin/env bash

python -m venv .venv

echo 'source $( dirname "${BASH_SOURCE[0]}" )/.venv/bin/activate' > .env

