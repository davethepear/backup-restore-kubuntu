#!/bin/bash
myhome=/home/dave
dest=/nfs/nas/BackUps # destination directory on drive or nfs
nas=dave@192.168.100.34:/volume1/Stuff # if no nas, comment this out
mntpt=/nfs/nas # your mount point, if using network drive or external, may be in /media. blank if saving locally

if [[ "$EUID" -ne 0 ]] && [[ ! -v $nas ]]; then
	echo "use sudo ./backup.sh"
	echo "it's for mounting external drives or network drives."
	echo "If you don't have such things, comment out the nas variable"
	exit 2
fi

mounted    () { findmnt -rno SOURCE,TARGET "$1" >/dev/null;}

# Mount a NAS
if [ ! -v $nas ]; then
    if mounted "$mntpt"; then
        echo "Drive is mounted, here we go!"
    else
        echo "Mounting the NAS... giggity."
        sudo mount 192.168.100.34:/volume1/Stuff /nfs/nas
    fi
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
    tar czfvp $dest/$HOSTNAME.minecraft.tar.gz $myhome/.minecraft/saves
    tar czfvp $dest/$HOSTNAME.wine.tar.gz $myhome/.PlayOnLinux
    tar czfvp $dest/$HOSTNAME.hexchat.tar.gz $myhome/.config/hexchat/
    tar czfvp $dest/$HOSTNAME.email.tar.gz $myhome/.thunderbird/
fi

# Browsers, I'm trying the --exclude-caches tag. I don't know how I feel about it yet.
# Otherwise, it's nice if you clear the caches first, otherwise it can get large
if [ "$browsers" == "y" ]; then
    tar czfvp $dest/$HOSTNAME.mozilla.tar.gz --exclude-caches $myhome/.mozilla
    tar czfvp $dest/$HOSTNAME.chromium.tar.gz --exclude-caches $myhome/.config/google-chrome/
    tar czfvp $dest/$HOSTNAME.edge-beta.tar.gz --exclude-caches $myhome/.config/microsoft-edge-beta/Default/
    tar czfvp $dest/$HOSTNAME.edge-dev.tar.gz --exclude-caches $myhome/.config/microsoft-edge-dev/Default/
    tar czfvp $dest/$HOSTNAME.brave.tar.gz --exclude-caches $myhome/.config/BraveSoftware/
fi

# Network saves
if [ "$networks" == "y" ]; then
    tar czfvp $dest/$HOSTNAME.networkcerts2.tar.gz  $myhome/.local/share/networkmanagement/
    tar czfvp $dest/$HOSTNAME.remotedolphin1.tar.gz $myhome/.local/share/remoteview/ 
    tar czfvp $dest/$HOSTNAME.remotedolphin2.tar.gz $myhome/.local/share/*.xbel*
    tar czfvp $dest/$HOSTNAME.vnc.tar.gz $myhome/.vnc
    tar czfvp $dest/$HOSTNAME.ssh.tar.gz $myhome/.ssh
    tar czfvp $dest/$HOSTNAME.kdeconn.tar.gz $myhome/.config/kdeconnect/
fi

# other programs
if [ "$settins" == "y" ]; then
    tar czfvp $dest/$HOSTNAME.gnucash.tar.gz $myhome/.local/share/gnucash/
    tar czfvp $dest/$HOSTNAME.webcamoid.tar.gz $myhome/.config/Webcamoid/
    tar czfvp $dest/$HOSTNAME.keepass.tar.gz $myhome/.config/keepassxc/
    tar czfvp $dest/$HOSTNAME.kate.tar.gz $myhome/.config/katerc
    tar czfvp $dest/$HOSTNAME.icons.tar.gz $myhome/.config/plasma-org.kde.plasma.desktop-appletsrc
    tar czfvp $dest/$HOSTNAME.menufavs.tar.gz $myhome/.config/kactivitymanagerdrc
    tar czfvp $dest/$HOSTNAME.scripts.tar.gz $myhome/scripts/
    cp $myhome/.config/kpatrc $myhome/Documents/System/BackUps/
fi

# Squish Documents
if [ "$squishdocs" == "y" ]; then
    tar czfvp $dest/$HOSTNAME.documents.tar.gz $myhome/Documents/
    tar czfvp $dest/$HOSTNAME.desktop.tar.gz $myhome/Desktop/
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
