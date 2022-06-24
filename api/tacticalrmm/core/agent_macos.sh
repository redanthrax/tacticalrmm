#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
  echo "ERROR: Must be run as root"
  exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
    -a | --agent)
        shift
        agent=$1
        ;;
    -b | --api)
        shift
        api=$1
        ;;
    -c | --mesh)
        shift
        mesh=$1
        ;;
    -d | --token)
        shift
        token=$1
        ;;
    -e | --client)
        shift
        client=$1
        ;;
    -f | --site)
        shift
        site=$1
        ;;
    -g | --type)
        shift
        type=$1
        ;;
    -h | --proxy)
        shift
        proxy=$1
        ;;
    -i | --debug)
        debug=1
        ;;
    -j | --uninstall)
        uninstall=1
        ;;
    esac
    shift
done

agentBinPath='/opt/tactical'
binName='tacticalagent'
agentConf='/etc/tacticalagent'
agentSvcName='com.tactical'
agentSysD="/Library/LaunchDaemons/com.tactical.plist"
meshDir='/usr/local/mesh_services/meshagent'
meshSystemBin="${meshDir}/meshagent_osx64"

if [[ "${uninstall}" -eq 1 ]]; then
    echo "Uninstalling Tactical and Mesh Agent..."
    launchctl stop com.tactical.plist
    launchctl unload ${agentSysD}
    rm ${agentSysD}
    rm "${agentBinPath}/${binName}"
    rm /etc/tacticalagent
    #${meshSystemBin} -uninstall
    exit
fi

if test -z "$agent" || test -z "$api" || test -z "$token" || test -z "$client" || test -z "$site" || test -z "$type"
then
    printf '%s\n'\
            "Usage: agent_macos.sh"\
            "--agent \"https://macagentdownload\""\
            "--api \"https://api.company.com\""\
            "--token \"token generated by trmm\""\
            "--client 1 (client id)"\
            "--site 2 (site id)"\
            "--type workstation (server or workstation)"\
            "--proxy \"proxy\" (optional)"\
            "--debug (debug optional)"\
            "--uninstall (uninstall, only requirement when using)"
else
    #meshDL="https://mesh.${domain}/meshagents?id=10005"
    #echo "Downloading mesh agent..."

    #meshTmpDir="/tmp/mesh"
    #meshTmpBin="${meshTmpDir}/MeshAgent.mpkg"
    #mkdir -p ${meshTmpDir}
    #curl --insecure -k "${meshDL}" -Lo ${meshTmpBin}
    #installer -pkg ${meshTmpBin} -target /
    #sleep 5
    #rm -rf ${meshTmpDir}

    #echo "Getting mesh node id..."
    #MESH_NODE_ID=$(${agentBin} -m nixmeshnodeid)
    MESH_NODE_ID=''

    agentBin="${agentBinPath}/${binName}"
    mkdir -p ${agentBinPath}
    echo "Downloading tactical agent..."
    curl --insecure -k "${agent}" -Lo ${agentBin}
    chmod +x ${agentBin}
    if [ ! -d "${agentBinPath}" ]; then
        echo "Creating ${agentBinPath}"
        mkdir -p ${agentBinPath}
    fi

    if [[ "${debug}" -eq 1 ]]; then
        INSTALL_CMD="${agentBin} -m install -api ${api} -client-id ${client} -site-id ${site} -agent-type ${type} -auth ${token} -log debug"
    else
        INSTALL_CMD="${agentBin} -m install -api ${api} -client-id ${client} -site-id ${site} -agent-type ${type} -auth ${token}"
    fi

    if [ "${MESH_NODE_ID}" != '' ]; then
        INSTALL_CMD+=" -meshnodeid ${MESH_NODE_ID}"
    fi

    if [ "${proxy}" != '' ]; then
        INSTALL_CMD+=" -proxy ${proxy}"
    fi

    eval ${INSTALL_CMD}
    chmod +x ${agentBin}
    tacticalsvc="$(cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.tactical.plist</string>
        <key>ServiceDescription</key>
        <string>Tactical RMM Service</string>
        <key>ProgramArguments</key>
        <array>             
            <string>${agentBin}</string>
            <string>-m</string>
            <string>svc</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
</plist>
EOF
)"
    echo "${tacticalsvc}" | tee ${agentSysD} > /dev/null
    launchctl load ${agentSysD}
    launchctl start com.tactical.plist
    echo "Installation complete."
fi