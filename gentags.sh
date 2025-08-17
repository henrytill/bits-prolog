#!/bin/sh
set -e
git ls-files | grep -E ".*\.(pl)$" | xargs etags -l prolog
