# backup-restore-linux

Backing up (and eventually auto restore) in Linux. It's taken me a long time to figure out what's important to me for backup. You will have to go through it and see what you have or don't have. I have 4 browsers installed, Play on Linux, Minecraft, Thunderbird, Hexchat, GnuCash, Webcamoid, and eww, Microshaft Edge.

## It works for me... try it at your own risk.

## Requirements
- rsync - because, yeah, it's what I used. it seems fast enough and is especially good at keeping things updated.
- PV - thought it made it easier to see what's happening, or that something is happening, rather than long flowing lists of files and missed errors.
- meld - nice comparationator thing to see what files are on one side and not the other. meld is GUI, so may cause problems in headless installs.
- a NAS or a place to put your stuff
- sudo - if you want to mount it with nfs, it seems faster... maybe. 
- - `sudo apt install nfs-common pv meld`
