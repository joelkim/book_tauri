#!/bin/bash
quarto render
ghp-import -c tauribook.madebykim.kr -f -n -o -p _site
