#!/usr/bin/env bash

################################################################################
# This script is copied to the workdir of the Docker container and executed as
# the last instruction during the image build process.
################################################################################

DEBIAN_FRONTEND=noninteractive

# Set the script to fail if any commands fail.
set -e

# Install the `git` package using `apt-get`, then clean up the package manager
# cache to reduce the size of the Docker image.
apt-get update
apt-get install -y git
apt-get clean
rm -rf /var/lib/apt/lists/*

# Install the `asdf` package manager by cloning the repository from GitHub
# into our `/ops/.asdf` directory, which is acting as the home/working directory
# for the `ops` user.
git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR:="/ops/.asdf"} --branch ${ASDF_VERSION_TAG:-v0.14.1}
source "${ASDF_DIR}/asdf.sh"

echo '[[ -f "${ASDF_DIR}/asdf.sh" ]] && source "${ASDF_DIR}/asdf.sh"' >> /etc/profile

# For each line in the `/ops/.tool-versions` file, get the name of the tool from
# the first column, then use that name to add the appropriate plugin to `asdf`.
# Plugins are the component that `asdf` uses to install and manage each
# individual tool or runtime environment.
while read line ; do
    # Split the line into an array using whitespace as the delimiter.
    set $line

    # Skip empty lines and comments.
    if [[ -z $1 ]] || [[ $1 == \#* ]]; then continue; fi

    # Add the `asdf` plugin for whatever tool we want to install.
    asdf plugin add $1

    # Install the latest version of the tool we want to install. If the version
    # number set in the `asdf-installs` file is a full semver including the patch,
    # the `asdf` command will still accept it with the `latest:` prefix.
    asdf install $1 latest:$2

    # Set the tool we just installed as the global version for the `ops` user.
    asdf global $1 latest:$2
done </build/asdf-installs

# For good measure, change the ownership of our `/ops` directory to the `ops`
# user and the `9999` group, recursively.
chown -R ops:9999 /ops/
