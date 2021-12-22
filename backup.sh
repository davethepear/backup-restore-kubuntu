#!/bin/bash

myhome=/home/dave
mntpt=/nfs/nas # your mount point, if using network drive or external, may be in /media. comment out if saving locally
dest=/nfs/nas/BackUps/ # destination directory on drive or nfs
naslogin=dave@192.168.1.2:/volume1/Stuff # NAS login - if no nas, comment this out

bktime=$(date +"%F_%H-%M")
logfile="$myhome/BackUpErrors-$bktime".log
sudo -v
if [[ "$EUID" == 0 ]]; then
	echo "While you need sudo for a few things, mount and umount, and a couple of system files"
	echo "this shouldn't be run AS root, so now that you're verified as sudo you can run it"
	echo "again without sudo: ./backup.sh"
	exit 0
fi

mounted    () { findmnt -rno SOURCE,TARGET "$1" >/dev/null;} #path or device

# Mount a NAS
if [ ! -v $naslogin ]; then
    if mounted "$mntpt"; then
        echo "Drive is mounted, here we go!"
    else
        echo "Mounting the NAS... giggity."
        sudo mount -t nfs "${naslogin#*@}" $mntpt
    fi
fi

if [ ! -d $dest ]; then mkdir -p $dest ; fi

# Shut up and do it! I've got things to do...
read -p "Backup everything, hit enter... or 'n' for step-by-step (Enter/n)?" parse
if [ "$parse" == "" ]; then
    echo Backing up EVERYTHING!
    homebase=y
    chat=y
    mail=y
    browsers=y
    networks=y
    settings=y
    squishdocs=y
    copydocs=y
    copydesk=y
    copyvids=y
    mine=y
    pol=y
else
    read -p "Backup $HOME (non-recursive)" homebase
    read -p "Backup Chat Programs?" chat
    read -p "Backup Thunderbird?" mail
    read -p "Backup browsers?" browsers
    read -p "Backup network locations and logins?" networks
    read -p "Backup program settings?" settings
    read -p "Compress Documents & Desktop into a tar.gz on NAS?" squishdocs
    read -p "Copy Uncompressed Documents to NAS?" copydocs
    read -p "Copy Uncompressed Desktop to NAS?" copydesk
    read -p "Backup Videos to NAS?" copyvids
    read -p "Backup Minecraft Worlds?" mine
    read -p "Backup Wine (Play on Linux)" pol
fi
# Minecraft worlds... I use a lot of stuff in Wine (PoL)... and Hexchat (IRC)... and Thunderbird (email)
# These are pretty large saves, usually, so I grouped them into one spot.

if [ "$homebase" == "y" ]; then
    echo "Backing up $HOME, with no directories!"
    find . -maxdepth 1 -type f -name "*" -exec tar czfpP /nfs/nas/BackUps/PortablePear/$HOSTNAME.home.tar.gz {} +
    if [ ! -f $dest/$HOSTNAME.home.tar.gz ]; then echo "$HOME not backed up!" >> $logfile ; fi
fi
if [ "$mine" == "y" ]; then
    tar czfpP - $myhome/.minecraft/saves | (pv -N Minecraft -bpetr > $dest/$HOSTNAME.minecraft.tar.gz)
    if [ ! -f $dest/$HOSTNAME.minecraft.tar.gz ]; then echo "Minecraft not backed up!" >> $logfile ; fi
fi
if [ "$pol" == "y" ]; then
    tar czfpP - $myhome/.PlayOnLinux | (pv -N PoL -bpetr > $dest/$HOSTNAME.wine.tar.gz)
    if [ ! -f $dest/$HOSTNAME.wine.tar.gz ]; then echo "PoL not backed up!" >> $logfile ; fi
fi
if [ "$chat" == "y" ]; then
    tar czfpP - $myhome/.config/hexchat/ | (pv -N Hexchat -bpetr > $dest/$HOSTNAME.hexchat.tar.gz)
    if [ ! -f $dest/$HOSTNAME.hexchat.tar.gz ]; then echo "HexChat not backed up!" >> $logfile ; fi
fi
if [ "$mail" == "y" ]; then
    tar czfpP - $myhome/.thunderbird/ | (pv -N Email -bpetr > $dest/$HOSTNAME.email.tar.gz)
    if [ ! -f $dest/$HOSTNAME.email.tar.gz ]; then echo "Email not backed up!" >> $logfile ; fi
fi

# Browsers, I'm trying the --exclude-caches tag. I don't know how I feel about it yet.
# Otherwise, it's nice if you clear the caches first, otherwise it can get large
if [ "$browsers" == "y" ]; then
    tar czfpP - --exclude-caches $myhome/.mozilla | (pv -N Firefox -bpetr > $dest/$HOSTNAME.firefox.tar.gz)
    if [ ! -f $dest/$HOSTNAME.firefox.tar.gz ]; then echo "Firefox not backed up!" >> $logfile ; fi
    tar czfpP - --exclude-caches $myhome/.config/google-chrome/ | (pv -N Chromium -bpetr > $dest/$HOSTNAME.chromium.tar.gz)
    if [ ! -f $dest/$HOSTNAME.chromium.tar.gz ]; then echo "Chromium not backed up!" >> $logfile ; fi
    tar czfpP - --exclude-caches $myhome/.config/microsoft-edge-beta/Default/ | (pv -N EdgeBeta -bpetr > $dest/$HOSTNAME.edge-beta.tar.gz)
    if [ ! -f $dest/$HOSTNAME.edge-beta.tar.gz ]; then echo "Edge BETA not backed up!" >> $logfile ; fi
    tar czfpP - --exclude-caches $myhome/.config/microsoft-edge-dev/Default/ | (pv -N EdgeDev -bpetr > $dest/$HOSTNAME.edge-dev.tar.gz)
    if [ ! -f $dest/$HOSTNAME.edge-dev.tar.gz ]; then echo "Edge DEV not backed up!" >> $logfile ; fi
    tar czfpP - --exclude-caches $myhome/.config/BraveSoftware/ | (pv -N Brave -bpetr > $dest/$HOSTNAME.brave.tar.gz)
    if [ ! -f $dest/$HOSTNAME.brave.tar.gz ]; then echo "Brave not backed up!" >> $logfile ; fi
fi

# Network saves
if [ "$networks" == "y" ]; then
    tar czfpP - $myhome/.local/share/networkmanagement/ | (pv -N NetworkCerts -bpetr > $dest/$HOSTNAME.networkcerts2.tar.gz)
    if [ ! -f $dest/$HOSTNAME.networkcerts2.tar.gz ]; then echo "Network Certs not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.local/share/remoteview/ | (pv -N Dolphin1 -bpetr > $dest/$HOSTNAME.remotedolphin1.tar.gz)
    if [ ! -f $dest/$HOSTNAME.remotedolphin1.tar.gz ]; then echo "Remote locations for Dolphin1 not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.local/share/*.xbel* | (pv -N Dolphin2 -bpetr > $dest/$HOSTNAME.remotedolphin2.tar.gz)
    if [ ! -f $dest/$HOSTNAME.remotedolphin2.tar.gz ]; then echo "Remote locations for Dolphin2  not backed up!" >> $logfile ; fi
    sudo tar czfpP - /etc/NetworkManager/system-connections/ | (pv -N NetworkManager -bpetr > $dest/$HOSTNAME.networkconnections.tar.gz)
    if [ ! -f $dest/$HOSTNAME.networkconnections.tar.gz ]; then echo "Network Connections not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.vnc | (pv -N VNC -bpetr > $dest/$HOSTNAME.vnc.tar.gz)
    if [ ! -f $dest/$HOSTNAME.vnc.tar.gz ]; then echo "VNC not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.ssh | (pv -N SSH -bpetr > $dest/$HOSTNAME.ssh.tar.gz)
    if [ ! -f $dest/$HOSTNAME.ssh.tar.gz ]; then echo "SSH not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/kdeconnect/ | (pv -N KDEConnect -bpetr > $dest/$HOSTNAME.kdeconn.tar.gz)
    if [ ! -f $dest/$HOSTNAME.kdeconn.tar.gz ]; then echo "KDE Connect not backed up!" >> $logfile ; fi
fi

# other programs I have a few settings I hate tracking down
if [ "$settings" == "y" ]; then
    tar czfpP - $myhome/.local/share/gnucash/ | (pv -N GnuCash -bpetr > $dest/$HOSTNAME.gnucash.tar.gz)
    if [ ! -f $dest/$HOSTNAME.gnucash.tar.gz ]; then echo "GnuCash not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/Webcamoid/ | (pv -N Webcamoid -bpetr > $dest/$HOSTNAME.webcamoid.tar.gz)
    if [ ! -f $dest/$HOSTNAME.webcamoid.tar.gz ]; then echo "Webcamoid not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/keepassxc/ | (pv -N KeePass -bpetr > $dest/$HOSTNAME.keepass.tar.gz)
    if [ ! -f $dest/$HOSTNAME.keepass.tar.gz ]; then echo "KeePass not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/katerc | (pv -N Kate -bpetr > $dest/$HOSTNAME.kate.tar.gz)
    if [ ! -f $dest/$HOSTNAME.kate.tar.gz ]; then echo "Kate not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/plasma-org.kde.plasma.desktop-appletsrc | (pv -N DesktopIcons -bpetr > $dest/$HOSTNAME.icons.tar.gz)
    if [ ! -f $dest/$HOSTNAME.icons.tar.gz ]; then echo "Desktop Icons not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/.config/kactivitymanagerdrc | (pv -N MenuFavorites -bpetr > $dest/$HOSTNAME.menufavs.tar.gz)
    if [ ! -f $dest/$HOSTNAME.menufavs.tar.gz ]; then echo "App menu not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/scripts/ | (pv -bpetr > $dest/$HOSTNAME.scripts.tar.gz)
    if [ ! -f $dest/$HOSTNAME.scripts.tar.gz ]; then echo "Scripts directory not backed up!" >> $logfile ; fi
    cp $myhome/.config/kpatrc $myhome/Documents/System/BackUps/
    if [ ! -f $myhome/.config/kpatrc ]; then echo "Kpatience not backed up!" >> $logfile ; fi
fi

# Squish Documents
if [ "$squishdocs" == "y" ]; then
    tar czfpP - $myhome/Documents/ | (pv -N Documents -bpetr > $dest/$HOSTNAME.documents.tar.gz)
    if [ ! -f $dest/$HOSTNAME.documents.tar.gz ]; then echo "Documents (squished) not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/Desktop/ | (pv -N Desktop -bpetr > $dest/$HOSTNAME.desktop.tar.gz)
    if [ ! -f $dest/$HOSTNAME.desktop.tar.gz ]; then echo "Desktop (squished) not backed up!" >> $logfile ; fi
fi

# Copy docs to other location
if [ "$copydocs" == "y" ]; then
    echo "Documents"
    rsync -ulrzh --delete-before --info=progress2 $myhome/Documents/ $dest/Documents/
    doccopy=$(diff -qr $myhome/Documents/ $dest/Documents/)
    if [ ! -z "$doccopy" ]; then
        echo "Problems with Documents Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Documents? (y/n)" melddoc
        if [ "$melddoc" == "y" ]; then meld $myhome/Documents/ $dest/Documents/ & disown ; fi
    fi
fi
# Copy Desktop to NAS
if [ "$copydesk" == "y" ]; then
    echo "Desktop"
    rsync -ulrzh --delete-before --info=progress2 $myhome/Desktop/ $dest/Desktop/
    deskcopy=$(diff -qr $myhome/Desktop/ $dest/Desktop/)
    if [ ! -z "$deskcopy" ]; then
        echo "Problems with Desktop Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Desktops? (y/n)" melddesk
        if [ "$melddesk" == "y" ]; then meld $myhome/Desktop/ $dest/Desktop/ & disown ; fi
    fi
fi

# Copy videos, porn, whatever
if [ "$copyvids" == "y" ]; then
    # This one is special due to a space in the directory name
    echo "Videos"
    rsync -ulrzh $myhome/Videos/ $dest/Videos/
    vidcopy=$(diff -qr $myhome/Videos/ $dest/Videos/)
    if [ ! -z "$vidcopy" ]; then
        echo "Problems with Video Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Videos? (y/n)" meldvid
        if [ "$meldvid" == "y" ]; then meld $myhome/Videos/ $dest/Videos/ & disown ; fi
    fi
fi

# Are there errors?
if [ -f $logfile ]; then
    echo "There were issues with this backup!"
    echo "See $logfile"
    cat $logfile 
fi

# unmount NAS, or USB, or whatever... 
if mounted "$mntpt"; then
    read -p "Unmount NAS?" umount
    if [ "$umount" == "y" ]; then
        sudo umount $mntpt
	echo unmounted $mntpt
	exit 0
    fi
fi
