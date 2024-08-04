const fs = require('fs');
const { exec } = require('child_process');
const { log } = require('./logger');

// Read private keys and addresses from files
const privateKeys = fs.readFileSync('private-key.txt', 'utf8').split('\n').filter(Boolean);
const addresses = fs.readFileSync('address.txt', 'utf8').split('\n').filter(Boolean);

if (privateKeys.length !== addresses.length) {
    log('ERROR', 'The number of private keys and addresses must be the same.');
    process.exit(1);
}

// Amount to bridge
const amount = '0.002';
const network = '--sepolia';

// Function to execute the CLI command
function bridge(privateKey, address, callback) {
    const command = `node eclipse-deposit/bin/cli.js -k ${privateKey} -d ${address} -a ${amount} ${network}`;
    exec(command, (error, stdout, stderr) => {
        if (error) {
            log('ERROR', `Error executing command for address ${address}: ${error.message}`);
        } else {
            log('SUCCESS', `Success for address ${address}:\n${stdout}`);
        }
        callback();
    });
}

// Loop through each private key and address pair and execute the bridge command
function bridgeAll(index) {
    if (index < privateKeys.length) {
        const privateKey = privateKeys[index];
        const address = addresses[index];
        log('INFO', `Executing bridge for address ${address} with private key ${privateKey}`);
        bridge(privateKey, address, () => {
            bridgeAll(index + 1);
        });
    } else {
        log('INFO', 'All bridge operations completed.');
    }
}

// Start the bridging process
bridgeAll(0);
