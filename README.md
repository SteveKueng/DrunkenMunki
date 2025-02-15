# DrunkenMunki

## setup VM

./macosvm --disk disk.img,size=60g --aux aux.img --restore UniversalMac_15.3.1_24D70_Restore.ipsw vm.json

./macosvm -g vm.json --vol /tmp/test 


###
- Install git
- Autologin enalble
- SSH enable
- ScreenSharing enable
- ScreenSaver disable
- EnergySettings no sleep
- Install github-runner



sudo mkdir /Volumes/test
soudo mount_virtiofs macosvm /Volumes/test