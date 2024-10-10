const { ux, sdk } = require('@cto.ai/sdk');

/**
 * Return the hostname depending on which environment variables are set
 * @returns {string} hostname
 */
function getWorkflowHostname() {
    return process.env.TS_HOSTNAME || process.env.OPS_OP_NAME
}

/**
 * Determine the name of the environment variable that contains the Tailscale
 * auth key for the current hostname.
 * @returns {string} authkeySecretName
 */
function getAuthKeySecretName() {
    // If the the `AUTHKEY_SECRET_NAME` static environment variable has been set
    // in the `ops.yml` for the workflow, use the value of that variable as the
    // name of the secret containing the Tailscale auth key.
    if (process.env.AUTHKEY_SECRET_NAME) {
        return process.env.AUTHKEY_SECRET_NAME
    } else {
        // Otherwise, generate the name of the secret based on the hostname
        const hostkey = getWorkflowHostname().toUpperCase().replace(/-/g, '_').trim()
        return `TAILSCALE_AUTHKEY_${hostkey}`
    }
}

/**
 * Retrieve the Tailscale auth key from the Secrets Store using the name of the
 * secret that contains the key. The name of the secret to retrieve is determined
 * by the string passed as the `authkeyName` parameter.
 * @param {string} authkeyName
 * @returns {Promise<string>} tailscaleAuthkey
 */
async function getAuthKey(authkeyName) {
    const authkeyResponse = await sdk.getSecret(authkeyName)
    return authkeyResponse[authkeyName]
}

async function main() {
    // Determine the hostname for the Tailscale node, and get the auth key
    const hostname = getWorkflowHostname()
    const authkeyName = getAuthKeySecretName()
    const tailscaleAuthkey = await getAuthKey(authkeyName)

    // Connect to the Tailscale network using the auth key
    sdk.log(`Connecting to Tailscale network using auth key for hostname '${hostname}'...`)
    const tsResponse = await sdk.exec(`tailscale up --authkey=${tailscaleAuthkey} --accept-routes --timeout 60s --hostname ${hostname}`)
    if (tsResponse.stdout) {
        sdk.log(tsResponse.stdout)
    }
    sdk.log('Successfully connected to Tailscale network.')

    /**
     * Modify the code below to implement your workflow logic
     * ------------------------------------------------------
     */

    // Prompt the user to choose a Tailscale command to execute
    // TODO: Modify this prompt with the options appropriate for the new Command
    const {action} = await ux.prompt({
        type: 'list',
        name: 'action',
        message: 'Which tailscale command would you like to execute?',
        default: 'logout',
        choices: ['logout', 'status', 'netcheck', 'whois'],
    });

    // Execute the selected Tailscale command
    // TODO: Modify the business logic defined here that controls how the
    //       workflow behaves when it is run.
    if (action === 'logout') {
        await sdk.exec(`tailscale logout`)
        sdk.log('Tailscale disconnected. Exiting...')
        process.exit(0)
    } else if (action === 'status') {
        sdk.log('Fetching status of the current Tailscale node...')
        const statusResponse = await sdk.exec(`tailscale status --peers=false`)
        sdk.log(statusResponse.stdout)
    } else if (action === 'netcheck') {
        sdk.log('Running diagnostics on the local network for the current Tailscale node...')
        const netcheckResponse = await sdk.exec(`tailscale netcheck`)
        sdk.log(netcheckResponse.stdout)
    } else if (action === 'whois') {
        sdk.log('Fetching whois information for the current Tailscale node...')
        const whoisResponse = await sdk.exec(`tailscale whois $(tailscale ip --4)`)
        sdk.log(whoisResponse.stdout)
    }

    /**
     * ------------------------------------------------------
     * Modify the code above to implement your workflow logic
     */

    // Disconnect from the Tailscale network
    sdk.log('Disconnecting from Tailscale network...')
    await sdk.exec(`tailscale logout`)
    sdk.log('Tailscale disconnected. Exiting...')

    // Exit cleanly
    process.exit(0)
}

main().catch(async (err) => {
    sdk.log(err);
    await sdk.exec(`tailscale logout`)
    process.exit(1);
});
