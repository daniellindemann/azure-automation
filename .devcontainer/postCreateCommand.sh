#!/bin/bash

IS_ARM=$(if [[ $(uname -m) == 'aarch64' || $(uname -m) == "amd64" ]]; then echo true; else echo false; fi)

echo "--- Install bicep ---"
if [[ $IS_ARM = true ]]; then
    echo "Yep, it's an arm64 machine"
    BICEP_VERSION=$(
        curl --silent "https://api.github.com/repos/Azure/bicep/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"v([^"]+)".*/\1/' \
    )
    curl -L -o bicep "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-arm64" \
        && chmod +x bicep \
        && sudo mv ./bicep /usr/local/bin
    # configure az cli to run bicep from path instead to install it when running 'az bicep' commands
    az config set bicep.check_version=false 2> /dev/null && az config set bicep.use_binary_from_path=true 2> /dev/null
fi

echo "--- Done ---"
