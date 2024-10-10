############################
# Final container
############################

# Because we are using `asdf` to manage our tools, we can simply use the bash
# image from the cto.ai registry, as it provides the `sdk-daemon` runtime that
# we need to connect to the CTO.ai platform, and we don't need to worry about
# the version of Node.js that is installed in the image by default.
FROM registry.cto.ai/official_images/bash:2-bullseye-slim

# Download the Tailscale binaries and extract them to the `/usr/local/bin`
# directory, as well as create the `/var/run/tailscale` directory which the
# Tailscale daemon uses to store runtime information.
ARG TAILSCALE_VERSION
ENV TAILSCALE_VERSION=${TAILSCALE_VERSION:-1.74.1}
RUN curl -fsSL "https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz" --max-time 300 --fail \
        | tar -xz -C /usr/local/bin --strip-components=1 --no-anchored tailscale tailscaled \
    && mkdir -p /var/run/tailscale \
    && chown -R ops:9999 /usr/local/bin/tailscale* /var/run/tailscale

# Copy the `entrypoint.sh` script to the container and set the appropriate
# permissions to ensure that it can be executed by the `ops` user. We need to
# use an entrypoint script to ensure the Tailscale daemon is running before we
# run the code that defines our workflow.
COPY --chown=ops:9999 lib/entrypoint.sh /ops/entrypoint.sh
RUN chmod +x /ops/entrypoint.sh

# The base directory for our image is `/ops`, which is where all of the code
# that defines our workflow will live.
WORKDIR /ops

# Run the container as the `ops` user by default, and set the appropriate
# environment variables for the user. Because we're going to use `asdf` to
# manage our tools, we'll manually set the `ASDF_DIR` and `PATH` environment
# variables to point to the `/ops/.asdf` directory that will soon be installed.
ENV USER=ops HOME=/ops XDG_RUNTIME_DIR=/run/ops/9999 \
    PATH=/ops/.asdf/shims:/ops/.asdf/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Set the `ASDF_VERSION_TAG` and `ASDF_DIR` environment variables manually to
# ensure that the correct version of the tool is installed in `/ops/.asdf`.
ENV ASDF_VERSION_TAG=v0.14.1 \
    ASDF_DIR=/ops/.asdf

# Copy the contents of the `lib/` directory into the root of the image. This
# means, for example, that the `./lib/build/` directory will be at `/build/`.
COPY --chown=ops:9999 lib/build/ /build/

# Uncomment to install any additional packages needed to run the tools and code
# we will be using during the build process OR in our final container.
# RUN apt-get update \
#     && apt-get install -y \
#         build-essential \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# Run the script that will install the `asdf` tool, the plugins necessary to
# install the tools specified in the `.tool-versions` file, and then install
# the tools themselves. This is how a more recent version of Node.js will be
# installed and managed in our image.
RUN bash /build/install-asdf-tools.sh

# Copy the `package.json` file to the container and run `npm install` to ensure
# that all of the dependencies for our Node.js code are installed.
COPY --chown=ops:9999 package.json .
RUN npm install

# Copy the `index.js` file that defines the behavior of our workflow when the
# workflow is run using the `ops run` command or any other trigger.
COPY --chown=ops:9999 index.js /ops/

##############################################################################
# As a security best practice the container will always run as non-root user.
##############################################################################

# Finally, set the `ops` user as the default user for the container and set the
# `entrypoint.sh` script as the default command that will be run when the
# workflow container is run. The `entrypoint.sh` script will be passed the `run`
# value from the `ops.yml` file that defines this workflow.
USER ops
ENTRYPOINT [ "/ops/entrypoint.sh" ]
