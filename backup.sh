#!/bin/bash

myhome=/home/dave/
dest=/nfs/nas/BackUps/PortablePear/ # destination directory on drive or nfs
nas=dave@192.168.100.34:/volume1/Stuff/ # if no nas, comment this out
mntpt=/nfs/nas # your mount point, if using network drive or external, may be in /media. blank if saving locally

# Mount a NAS
if [ -v $nas ]; then
    sudo mount 192.168.100.34:/volume1/Stuff /nfs/nas
fi

# Shut up and do it! I've got things to do...
read -p "Backup everything, hit enter... or 'n' for step-by-step (Enter/n)?" parse
if [ "$parse" == "" ]; then
    echo Backing up EVERYTHING!
    minechatmail=y
    browsers=y
    networks=y
    settings=y
    squishdocs=y
    copydocs=y
    copyvids=y
else
    read -p "Backup Minecrap, Chats, & Email?" minechatmail
    read -p "Backup browsers?" browsers
    read -p "Backup network locations and logins?" networks
    read -p "Backup program settings?" settings
    read -p "Compress Documents & Desktop into a tar.gz on NAS?" squishdocs
    read -p "Backup Documents & Desktop to NAS?" copydocs
    read -p "Backup Videos to NAS?" copyvids
fi

# Minecraft worlds... I use a lot of stuff in Wine (PoL)... and Hexchat (IRC)... and Thunderbird (email)
# These are pretty large saves, usually, so I grouped them into one spot.
if [ "$minechatmail" == "y" ]; then
    tar czfvp $dest/bkup.minecraft.tar.gz $myhome/.minecraft/saves
    tar czfvp $dest/bkup.wine.tar.gz $myhome/.PlayOnLinux
    tar czfvp $dest/bkup.hexchat.tar.gz $myhome/.config/hexchat/
    tar czfvp $dest/bkup.email.tar.gz $myhome/.thunderbird/
fi

# Browsers, it's nice if you clear the caches first, otherwise it can get large
if [ "$browsers" == "y" ]; then
    tar czfvp $dest/bkup.mozilla.tar.gz $myhome/.mozilla
    tar czfvp $dest/bkup.chromium.tar.gz $myhome/.config/google-chrome/
    tar czfvp $dest/bkup.edge-beta.tar.gz $myhome/.config/microsoft-edge-beta/Default/
    tar czfvp $dest/bkup.edge-dev.tar.gz $myhome/.config/microsoft-edge-dev/Default/
    tar czfvp $dest/bkup.brave.tar.gz $myhome/.config/BraveSoftware/
fi

# Network saves
if [ "$networks" == "y" ]; then
    tar czfvp $dest/bkup.networkcerts2.tar.gz  $myhome/.local/share/networkmanagement/
    tar czfvp $dest/bkup.remotedolphin1.tar.gz $myhome/.local/share/remoteview/ 
    tar czfvp $dest/bkup.remotedolphin2.tar.gz $myhome/.local/share/*.xbel*
    tar czfvp $dest/bkup.vnc.tar.gz $myhome/.vnc
    tar czfvp $dest/bkup.ssh.tar.gz $myhome/.ssh
    tar czfvp $dest/bkup.kdeconn.tar.gz $myhome/.config/kdeconnect/
fi

# other programs
if [ "$settins" == "y" ]; then
    tar czfvp $dest/bkup.gnucash.tar.gz $myhome/.local/share/gnucash/
    tar czfvp $dest/bkup.webcamoid.tar.gz $myhome/.config/Webcamoid/
    tar czfvp $dest/bkup.keepass.tar.gz $myhome/.config/keepassxc/
    tar czfvp $dest/bkup.kate.tar.gz $myhome/.config/katerc
    tar czfvp $dest/bkup.icons.tar.gz $myhome/.config/plasma-org.kde.plasma.desktop-appletsrc
    tar czfvp $dest/bkup.menufavs.tar.gz $myhome/.config/kactivitymanagerdrc
    tar czfvp $dest/bkup.scripts.tar.gz $myhome/scripts/
    cp $myhome/.config/kpatrc $myhome/Documents/System/BackUps/
fi

# Squish Documents
if [ "$squishdocs" == "y" ]; then
    tar czfvp $dest/bkup.documents.tar.gz $myhome/Documents/
    tar czfvp $dest/bkup.desktop.tar.gz $myhome/Desktop/
fi

# Copy docs to other location
if [ "$copydocs" == "y" ]; then
    rsync -ulrvzh --progress $myhome/Documents/ $nas/Documents/
    rsync -ulrvzh --progress $myhome/Desktop/ $nas/Desktop/
fi

# Copy videos, porn, whatever
if [ "$copyvids" == "y" ]; then
    # This one is special due to a space in the directory name
    rsync -ulrvzh --progress $myhome/Videos/ dave@192.168.100.34:"/volume1/Stuff/My\ Videos/2021"
fi

# unmount NAS, or USB, or whatever... 
if [ -v $nas ]; then
    read -p "Unmount NAS?" umount
    if [ "$umount" == "y" ]; then
        sudo umount $mntpt
    fi
fi
