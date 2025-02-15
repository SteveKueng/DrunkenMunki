#!/bin/bash

GITHUB_TOKEN="" # This is the GitHub token for the repo

scriptname="DrunkenMunkiFirstBeer"
logandmetadir="/var/log"
log="$logandmetadir/$scriptname.log"

#function to log only to file
log() {
    echo "$(date) | $1" >> $log
}

# Begin Script Body
log "#### Drinking $scriptname"

adminaccountname="drunkenmunki"       # This is the accountname of the new admin
adminaccountfullname="DrunkenMunki"  # This is the full name of the new admin user
password="DrunkenMunki" # This is the password of the new admin user

curl mkuser.sh | sh
/usr/local/bin/mkuser -qaAn $adminaccountname -f $adminaccountfullname -p $password -S


# install xcode command line tools
/usr/bin/touch "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
xcodeCommandLineTools=$(/usr/sbin/softwareupdate --list 2>&1 | \
    /usr/bin/awk -F: '/Label: Command Line Tools for Xcode/ {print $NF}' | \
    /usr/bin/sed 's/^ *//' | \
    /usr/bin/tail -1)

/usr/sbin/softwareupdate --install "$xcodeCommandLineTools"


# github runner setup
log "Setting up GitHub Runner"
cd /Users/$adminaccountname
mkdir actions-runner
cd actions-runner
curl -o actions-runner-osx-arm64.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-osx-arm64-2.322.0.tar.gz
tar xzf ./actions-runner-osx-arm64.tar.gz
rm actions-runner-osx-arm64.tar.gz 
chown -R $adminaccountname /Users/$adminaccountname/actions-runner

cat <<EOF > /Library/LaunchAgents/com.github.stevekueng.drunkenmunki.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.github.stevekueng.drunkenmunki</string>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/Users/$adminaccountname/stderr.log</string>
    <key>StandardOutPath</key>
    <string>/Users/$adminaccountname/stdout.log</string>
    <key>EnableGlobbing</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/$adminaccountname/drunkenMunki.sh</string>
    </array>
  </dict>
</plist>
EOF

chmod 644 /Library/LaunchAgents/com.github.stevekueng.drunkenmunki.plist
chown root:wheel /Library/LaunchAgents/com.github.stevekueng.drunkenmunki.plist

cat <<EOF > /Users/$adminaccountname/drunkenMunki.sh
#!/bin/bash

GTHUB_TOKEN="$GITHUB_TOKEN"
GITHUB_REPO="stevekueng/DrunkenMunki"

GITHUB_RUNNER_TOKEN=$(curl -sL \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer \$GTHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/\$GITHUB_REPO/actions/runners/registration-token | jq -r '.token')

sleep 2

# register the runner
/Users/drunkenmunki/actions-runner/config.sh --url https://github.com/\$GITHUB_REPO --token \$GITHUB_RUNNER_TOKEN --ephemeral --unattended

sleep 5

# start the runner
/Users/drunkenmunki/actions-runner/run.sh

sleep 2

# shutdown the mac
osascript -e 'tell app "System Events" to shut down'
EOF

chmod 755 /Users/$adminaccountname/drunkenMunki.sh
chown $adminaccountname /Users/$adminaccountname/drunkenMunki.sh

# clearup
log "#### Finished $scriptname"
#rm /var/DrunkenMunkiFirstBeer.sh
rm /Library/LaunchDaemons/com.github.stevekueng.drunkenmunki.firstbeer.plist
rm /Library/LauchAgents/com.github.stevekueng.drunkenmunki.terminal.plist

# shutdown the mac
shutdown -h now