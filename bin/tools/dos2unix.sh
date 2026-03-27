#!/bin/bash

while [ ! -f "$APP_HOME/VERSION" ]; do
  APP_HOME=$(realpath "$APP_HOME/..")
done

cd "$APP_HOME" || exit 1

find . -name "*.sh" -exec dos2unix {} \;
find . -name VERSION -exec dos2unix {} \;
