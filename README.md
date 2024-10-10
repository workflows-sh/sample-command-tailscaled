# Example Workflow: Command with Tailscale Integration

This repository contains an example workflow that demonstrates how to use the Tailscale CLI to connect the running [Command](https://cto.ai/docs/commands/overview/) to a Tailscale network.

It also uses the [asdf](https://asdf-vm.com/) CLI—an all-in-one runtime version manager akin to nvm or pyenv—to manage the version of Node.js that is used to run the business logic of the Command.

<p align="center">
<img src="https://github.com/user-attachments/assets/a6b1f44f-d8c2-4183-939c-9b7cc4071804" alt="Example of the sample command being run as-is" width="75%" />
</p>

## Getting Started

### Using this Template

To start using this template to build your own Command workflow integrated with the CTO.ai platform that connects to a Tailscale network, you can initialize the workflow locally using the CTO.ai [ops CLI](https://cto.ai/docs/usage-reference/ops-cli/) with this repository specified as the template:

```bash
ops init workflows-sh/sample-command-tailscaled
```

Alternatively, you can initialize a new repository by clicking the **Use this template** button at the top of this repository (or by [clicking here](https://github.com/new?template_name=sample-command-tailscaled&template_owner=workflows-sh)).

### Prerequisites

To use this Command, you will need to have accounts with the following services:

- [CTO.ai](https://cto.ai/home)
- [Tailscale](https://tailscale.com/)

<img src="https://github.com/user-attachments/assets/0c85bf1c-882b-4276-82dd-c8900787f314" alt="Screenshot of the Tailscale admin dashboard showing the proper settings to configure for your auth key" width="60%" align="right" style="padding-left: 50px;" />

#### Generate Tailscale key

You will also need to obtain an auth key for Tailscale from the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys):

1. Click on **Generate auth key...**
2. Configure the auth key to be *Reusable*, ensuring that it can be used to connect multiple instances of our ephemeral Command workflow.
3. Set the key to be *Ephemeral*, ensuring that containers using the key will not be able to access the Tailscale network after the Command has completed.

### Configuration

The default place this Command looks for the Tailscale authentication key is in a Secret registered [in your team's Secret Store on the CTO.ai platform](https://cto.ai/docs/configs-and-secrets/configs-and-secrets/) named <code>TAILSCALE_AUTHKEY_<strong><em><TS_HOSTNAME></em></strong></code>.

Thus, for the default value of `TS_HOSTNAME` in the `ops.yml` file, the Secret in the Secrets Store would be named `TAILSCALE_AUTHKEY_SAMPLE_COMMAND_TAILSCALED`. To run this Command as-is, you can add you Tailscale authentication key to a Secret with that name in the Secrets Store associated with your team on the CTO.ai platform.

> [!NOTE]
> If a Tailscale auth key is not added to the appropriate Secret name in the CTO.ai Secret Store associated with your team, you will be prompted to provide a value for that Secret the first time this Command is run.

Alternatively, set a value for `AUTHKEY_SECRET_NAME` as a [static environment variable](https://cto.ai/docs/configs-and-secrets/managing-variables/#managing-workflow-behavior-with-environment-variables) in the `ops.yml` file, and the Command will look for the Tailscale authentication key in a Secret with the name specified by that value.

## Creating Your Own Workflow

Once you have this template initialized locally as a new Command workflow, you can modify the code in [index.js](./index.js) to define how the workflow should behave when it is run (see the [Workflow Architecture](#workflow-architecture) section below for more information).

When you are ready to test your changes, you can [build and run the Command](https://cto.ai/docs/workflows/using-workflows/) locally using the `ops run` command with the `-b` flag:

```bash
ops run -b .
```

When you are ready to deploy your Command to the CTO.ai platform to make it available to your team via the `ops` CLI or our [Slack integration](https://cto.ai/docs/slackops/overview/), you can use the `ops publish` command:

```bash
ops publish .
```

## Workflow Architecture

The five main components described below define this example Command workflow.

### Runtime container definition: `Dockerfile`

The [Dockerfile](./Dockerfile) defines the build stage for the container image that executes the workflow. This is where dependencies are installed, including the `tailscale` and `tailscaled` binaries, as well as the dependencies managed by `asdf`.

### Build dependencies: `lib/build/`

Contains the scripts that are executed by the Dockerfile to install the dependencies managed by `asdf`. Within this directory, the [`install-asdf-tools.sh`](./lib/build/install-asdf-tools.sh) script installs the asdf-managed dependency versions defined in the [`asdf-installs`](./lib/build/asdf-installs) file.

### Container entrypoint: `lib/entrypoint.sh`

The [`entrypoint.sh`](./lib/entrypoint.sh) script that is executed when the container starts. This script starts the `tailscaled` service, which will allow the client to connect to a Tailscale network when the Command is run. After the script starts the daemon, it uses the `exec` command to replace the current process (that is, the `entrypoint.sh` script) with the process specified in the `ops.yml` file.

### Workflow definition(s): `ops.yml`

The [`ops.yml`](./ops.yml) defines the configuration for this Command. The script to execute as the [business logic of the workflow](https://cto.ai/docs/usage-reference/ops-yml/) is passed as the value of the `run` key, which is passed to the entrypoint of the final container.

### Workflow business logic: `index.js`

The business logic of the workflow. The [`index.js`](./index.js) script is executed by the Command when it is run.

There is where connection to a Tailscale network is initiated using the `tailscale up` command, which connects to the socket created by the `tailscaled` daemon started by the `entrypoint.sh` script.
