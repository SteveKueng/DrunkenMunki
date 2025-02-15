#!/bin/zsh

# parameters
# $: path to the ipsw file
ipswFile=$1

# check if ipsw not empty
if [ -z "$ipswFile" ]; then
    echo "Please provide the path to the ipsw file"
    exit 1
fi

# create vm folder
mkdir -p drunkenMunkiVM

# create vm
./macosvm --disk drunkenMunkiVM/drunkenMunki.img,size=60g --aux drunkenMunkiVM/aux.img --restore $ipswFile drunkenMunkiVM/drunkenMunki.json

# mount the drunkenMunki.img
HDITOOL_OUTPUT=$(hdiutil attach -nomount drunkenMunkiVM/drunkenMunki.img)
DISK_MAIN=$(echo "$HDITOOL_OUTPUT" | awk '/GUID_partition_scheme/ {print $1; exit}')

# get the mounted volume
IFS=$'\n' set -A DISK_LIST $(echo "$HDITOOL_OUTPUT" | awk '{print $1}' | grep "/dev/disk")
if [[ ${#DISK_LIST[@]} -eq 0 ]]; then
    echo "No disk found"
    exit 1
fi

for DISK in "${DISK_LIST[@]}"; do
    DATA_VOLUME=$(diskutil list $DISK | awk '/APFS Volume Data/ {print $NF}')
done

# mount the volume
mountPoint=$(mktemp -d)
mount -t apfs $DATA_VOLUME $mountPoint

# copy files to the mounted image
sudo cp -r ./createVM/LaunchDaemons/com.github.stevekueng.drunkenmunki.firstbeer.plist "$mountPoint/Library/LaunchDaemons"
sudo cp -r ./createVM/var/DrunkenMunkiFirstBeer.sh "$mountPoint/private/var"

# permissions
sudo chown root:wheel "$mountPoint/Library/LaunchDaemons/com.github.stevekueng.drunkenmunki.firstbeer.plist"
chmod 644 "$mountPoint/Library/LaunchDaemons/com.github.stevekueng.drunkenmunki.firstbeer.plist"

chmod 755 "$mountPoint/private/var/DrunkenMunkiFirstBeer.sh"
sudo chown root:wheel "$mountPoint/private/var/DrunkenMunkiFirstBeer.sh"

# AppleSetupDone
sudo touch "$mountPoint/private/var/db/.AppleSetupDone"

# unmount the drunkenMunki.img
umount "$mountPoint"

# detach the disk
hdiutil detach $DISK_MAIN > /dev/null

# start the VM
./macosvm -g drunkenMunkiVM/drunkenMunki.json
