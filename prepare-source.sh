#!/bin/bash

# This script prepares a development environment for DevShop,
# cloning the source code you need.
#

DEVMASTER_VERSION=1.x

if [ ! -d source ]; then
  mkdir source
fi

cd source

# Build a full devshop frontend on the host with drush make, with working-copy option.
if [ ! -d devmaster-$DEVMASTER_VERSION ]; then
   drush make ../../build-devmaster.make devmaster-$DEVMASTER_VERSION --working-copy --no-gitinfofile
   cp devmaster-$DEVMASTER_VERSION/sites/default/default.settings.php devmaster-$DEVMASTER_VERSION/sites/default/settings.php
   mkdir devmaster-$DEVMASTER_VERSION/sites/devshop.local.computer
   chmod 777 devmaster-$DEVMASTER_VERSION/sites -R
fi

# Clone drush packages.
if [ ! -d drush ]; then
    mkdir drush
    cd drush
    git clone git@git.drupal.org:project/provision.git --branch 7.x-3.x
    git clone git@git.drupal.org:project/registry_rebuild.git --branch 7.x-2.x
fi
