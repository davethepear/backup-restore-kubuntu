#!/bin/bash

myhome=/home/dave
mntpt=/nfs/nas # your mount point, if using network drive or external, may be in /media. comment out if saving locally
bkup=/nfs/nas/BackUps/PortablePear # destination directory on drive or nfs
naslogin=dave@192.168.100.34:/volume1/Stuff # NAS login - if no nas, comment this out

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

if [ ! -d $bkup ]; then mkdir -p $bkup ; fi

# Shut up and do it! I've got things to do...
read -p "Restore everything, hit enter... or 'n' for step-by-step (Enter/n)?" parse
if [ "$parse" == "" ]; then
    echo Restoring EVERYTHING!
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
    read -p "Restore $HOME (non-recursive)" homebase
    read -p "Restore Chat Programs?" chat
    read -p "Restore Thunderbird?" mail
    read -p "Restore browsers?" browsers
    read -p "Restore network locations and logins?" networks
    read -p "Restore program settings?" settings
    read -p "Copy Compressed Documents & Desktop from NAS to $HOME?" squishdocs
    read -p "Copy Uncompressed Documents from NAS?" copydocs
    read -p "Copy Uncompressed Desktop from NAS?" copydesk
    read -p "Restore Videos from NAS?" copyvids
    read -p "Restore Minecraft Worlds?" mine
    read -p "Restore Wine (Play on Linux)" pol
fi
# Minecraft worlds... I use a lot of stuff in Wine (PoL)... and Hexchat (IRC)... and Thunderbird (email)
# These are pretty large saves, usually, so I grouped them into one spot.

if [ "$homebase" == "y" ]; then
    echo "Restoring $HOME, with no directories!"
    pv -N Home $bkup/$HOSTNAME.home.tar.gz | tar xzf - -C $myhome
    if [ ! -f $bkup/$HOSTNAME.home.tar.gz ]; then echo "$HOME not restored!" >> $logfile ; fi
fi
if [ "$mine" == "y" ]; then
    pv -N Minecraft $bkup/$HOSTNAME.minecraft.tar.gz | tar xzf - -C $myhome/.minecraft/saves/
    if [ ! -f $bkup/$HOSTNAME.minecraft.tar.gz ]; then echo "Minecraft not restored!" >> $logfile ; fi
fi
if [ "$pol" == "y" ]; then
    pv -N PoL $bkup/$HOSTNAME.wine.tar.gz | tar xzf - -C $myhome/.PlayOnLinux/
    if [ ! -f $bkup/$HOSTNAME.wine.tar.gz ]; then echo "PoL not restored!" >> $logfile ; fi
fi
if [ "$chat" == "y" ]; then
    pv -N Hexchat $bkup/$HOSTNAME.hexchat.tar.gz | tar xzf - -C $myhome/.config/hexchat/
    if [ ! -f $bkup/$HOSTNAME.hexchat.tar.gz ]; then echo "HexChat not restored!" >> $logfile ; fi
fi
if [ "$mail" == "y" ]; then
    pv -N Email $bkup/$HOSTNAME.email.tar.gz | tar xzf - -C $myhome/.thunderbird/
    if [ ! -f $bkup/$HOSTNAME.email.tar.gz ]; then echo "Email not restored!" >> $logfile ; fi
fi

# Browsers, I'm trying the --exclude-caches tag. I don't know how I feel about it yet.
# Otherwise, it's nice if you clear the caches first, otherwise it can get large
if [ "$browsers" == "y" ]; then
    pv -N Firefox $bkup/$HOSTNAME.firefox.tar.gz | tar xzf - -C $myhome/.mozilla/
    if [ ! -f $bkup/$HOSTNAME.firefox.tar.gz ]; then echo "Firefox not restored!" >> $logfile ; fi
    pv -N Chromium $bkup/$HOSTNAME.chromium.tar.gz | tar xzf - -C $myhome/.config/google-chrome/
    if [ ! -f $bkup/$HOSTNAME.chromium.tar.gz ]; then echo "Chromium not restored!" >> $logfile ; fi
    pv -N EdgeBeta $bkup/$HOSTNAME.edge-beta.tar.gz | tar xzf - -C $myhome/.config/microsoft-edge-beta/Default/
    if [ ! -f $bkup/$HOSTNAME.edge-beta.tar.gz ]; then echo "Edge BETA not restored!" >> $logfile ; fi
    pv -N EdgeDev $bkup/$HOSTNAME.edge-dev.tar.gz | tar xzf - -C $myhome/.config/microsoft-edge-dev/Default/
    if [ ! -f $bkup/$HOSTNAME.edge-dev.tar.gz ]; then echo "Edge DEV not restored!" >> $logfile ; fi
    pv -N Brave $bkup/$HOSTNAME.brave.tar.gz | tar xzf - -C $myhome/.config/BraveSoftware/
    if [ ! -f $bkup/$HOSTNAME.brave.tar.gz ]; then echo "Brave not restored!" >> $logfile ; fi
fi

# Network saves
if [ "$networks" == "y" ]; then
    pv -N NetworkCerts $bkup/$HOSTNAME.networkcerts2.tar.gz | tar xzf - -C $myhome/.local/share/networkmanagement/
    if [ ! -f $bkup/$HOSTNAME.networkcerts2.tar.gz ]; then echo "Network Certs not restored!" >> $logfile ; fi
    pv -N Dolphin1 $bkup/$HOSTNAME.remotedolphin1.tar.gz | tar xzf - -C $myhome/.local/share/remoteview/
    if [ ! -f $bkup/$HOSTNAME.remotedolphin1.tar.gz ]; then echo "Remote locations for Dolphin1 not restored!" >> $logfile ; fi
    pv -N Dolphin2 $bkup/$HOSTNAME.remotedolphin2.tar.gz | tar xzf - -C $myhome/.local/share/
    if [ ! -f $bkup/$HOSTNAME.remotedolphin2.tar.gz ]; then echo "Remote locations for Dolphin2  not restored!" >> $logfile ; fi
    pv -N NetworkManager $bkup/$HOSTNAME.networkconnections.tar.gz | tar xzf - -C /etc/NetworkManager/system-connections/
    if [ ! -f $bkup/$HOSTNAME.networkconnections.tar.gz ]; then echo "Network Connections not restored!" >> $logfile ; fi
    pv -N VNC $bkup/$HOSTNAME.vnc.tar.gz | tar xzf - -C $myhome/.vnc/
    if [ ! -f $bkup/$HOSTNAME.vnc.tar.gz ]; then echo "VNC not restored!" >> $logfile ; fi
    pv -N SSH $bkup/$HOSTNAME.ssh.tar.gz | tar xzf - -C $myhome/.ssh/
    if [ ! -f $bkup/$HOSTNAME.ssh.tar.gz ]; then echo "SSH not restored!" >> $logfile ; fi
    pv -N KDEConnect $bkup/$HOSTNAME.kdeconn.tar.gz | tar xzf - -C $myhome/.config/kdeconnect/
    if [ ! -f $bkup/$HOSTNAME.kdeconn.tar.gz ]; then echo "KDE Connect not restored!" >> $logfile ; fi
fi

# other programs I have a few settings I hate tracking down
if [ "$settings" == "y" ]; then
    pv -N GnuCash $bkup/$HOSTNAME.gnucash.tar.gz | tar xzf - -C $myhome/.local/share/gnucash/
    if [ ! -f $bkup/$HOSTNAME.gnucash.tar.gz ]; then echo "GnuCash not restored!" >> $logfile ; fi
    pv -N Webcamoid $bkup/$HOSTNAME.webcamoid.tar.gz | tar xzf - -C $myhome/.config/Webcamoid/
    if [ ! -f $bkup/$HOSTNAME.webcamoid.tar.gz ]; then echo "Webcamoid not restored!" >> $logfile ; fi
    pv -N KeePass $bkup/$HOSTNAME.keepass.tar.gz | tar xzf - -C $myhome/.config/keepassxc/
    if [ ! -f $bkup/$HOSTNAME.keepass.tar.gz ]; then echo "KeePass not restored!" >> $logfile ; fi
    pv -N Kate $bkup/$HOSTNAME.kate.tar.gz | tar xzf - -C $myhome/.config/katerc/
    if [ ! -f $bkup/$HOSTNAME.kate.tar.gz ]; then echo "Kate not restored!" >> $logfile ; fi
    pv -N DesktopIcons $bkup/$HOSTNAME.icons.tar.gz | tar xzf - -C $myhome/.config/plasma-org.kde.plasma.desktop-appletsrc/
    if [ ! -f $bkup/$HOSTNAME.icons.tar.gz ]; then echo "Desktop Icons not restored!" >> $logfile ; fi
    pv -N MenuFavorites $bkup/$HOSTNAME.menufavs.tar.gz | tar xzf - -C $myhome/.config/kactivitymanagerdrc/
    if [ ! -f $bkup/$HOSTNAME.menufavs.tar.gz ]; then echo "App menu not restored!" >> $logfile ; fi
    pv -N Scripts $bkup/$HOSTNAME.scripts.tar.gz | tar xzf - -C $myhome/scripts/
    if [ ! -f $bkup/$HOSTNAME.scripts.tar.gz ]; then echo "Scripts directory not restored!" >> $logfile ; fi
    cp  $myhome/Documents/System/BackUps/kpatrc $myhome/.config/kpatrc
    if [ ! -f $myhome/.config/kpatrc ]; then echo "Kpatience not restored!" >> $logfile ; fi
fi

# Squish Documents
if [ "$squishdocs" == "y" ]; then
    cp $bkup/$HOSTNAME.documents.tar.gz $myhome/
    if [ ! -f $bkup/$HOSTNAME.documents.tar.gz ]; then echo "Documents (squished) not restored!" >> $logfile ; fi
    cp $bkup/$HOSTNAME.desktop.tar.gz $myhome/
    if [ ! -f $bkup/$HOSTNAME.desktop.tar.gz ]; then echo "Desktop (squished) not restored!" >> $logfile ; fi
fi

# Copy docs from nas
if [ "$copydocs" == "y" ]; then
    echo "Documents"
    rsync -ulrzh --info=progress2 $bkup/Documents/ $myhome/Documents/
    doccopy=$(diff -qr $myhome/Documents/ $bkup/Documents/)
    if [ ! -z "$doccopy" ]; then
        echo "Problems with Documents Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Documents? (y/n)" melddoc
        if [ "$melddoc" == "y" ]; then meld $myhome/Documents/ $bkup/Documents/ & disown ; fi
    fi
fi
# Copy Desktop to NAS
if [ "$copydesk" == "y" ]; then
    echo "Desktop"
    rsync -ulrzh --info=progress2 $bkup/Desktop/ $myhome/Desktop/
    deskcopy=$(diff -qr $myhome/Desktop/ $bkup/Desktop/)
    if [ ! -z "$deskcopy" ]; then
        echo "Problems with Desktop Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Desktops? (y/n)" melddesk
        if [ "$melddesk" == "y" ]; then meld $myhome/Desktop/ $bkup/Desktop/ & disown ; fi
    fi
fi

# Copy videos, porn, whatever
if [ "$copyvids" == "y" ]; then
    echo "Videos"
    rsync -ulrzh $bkup/Videos/ $myhome/Videos/
    vidcopy=$(diff -qr $myhome/Videos/ $bkup/Videos/)
    if [ ! -z "$vidcopy" ]; then
        echo "Problems with Video Copying" >> $logfile
        read -p "Would you like to open Meld to see the differences in Videos? (y/n)" meldvid
        if [ "$meldvid" == "y" ]; then meld $myhome/Videos/ $bkup/Videos/ & disown ; fi
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
