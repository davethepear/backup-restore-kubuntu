#!/bin/bash

myhome=/home/dave
mntpt=/nfs/nas # your mount point, if using network drive or external, may be in /media. comment out if saving locally
dest=/nfs/nas/BackUps/PrecisionPear # destination directory on drive or nfs
naslogin=dave@192.168.8.4:/volume1/Stuff # NAS login - if no nas, comment this out

bktime=$(date +"%F_%H-%M")
logfile="$myhome/BackUpErrors-$bktime".log
exec 19>> $logfile
BASH_XTRACEFD=19
set -x

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
    downloads=y
    mine=y
    pol=y
else
    read -p "Backup $HOME (non-recursive)" homebase
    read -p "Backup Chat Programs?" chat
    read -p "Backup Thunderbird?" mail
    read -p "Backup browsers?" browsers
    read -p "Backup network locations and logins?" networks
    read -p "Backup program settings?" settings
    read -p "Compress Documents & Desktop into a tgz on NAS?" squishdocs
    read -p "Copy Uncompressed Documents to NAS?" copydocs
    read -p "Copy Uncompressed Desktop to NAS?" copydesk
    read -p "Backup Downloads to NAS?" downloads
    read -p "Backup Videos to NAS?" copyvids
    read -p "Backup Minecraft Worlds?" mine
    read -p "Backup Wine (Play on Linux)" pol
fi
# Minecraft worlds... I use a lot of stuff in Wine (PoL)... and Hexchat (IRC)... and Thunderbird (email)
# These are pretty large saves, usually, so I grouped them into one spot.

if [ "$homebase" == "y" ]; then
    echo "Backing up $HOME, with no directories!"
    find . -maxdepth 1 -type f -name "*" -exec tar czfpP $dest/$HOSTNAME.home.tgz {} +
    if [ ! -f $dest/$HOSTNAME.home.tgz ]; then echo "#### $HOME not backed up! ####" >> $logfile ; fi
fi
if [ "$pol" == "y" ]; then
    tar czfpP - $myhome/.PlayOnLinux | (pv -N PoL -bpetr > $dest/$HOSTNAME.wine.tgz)
    if [ ! -f $dest/$HOSTNAME.wine.tgz ]; then echo " #### PoL not backed up! #### " >> $logfile ; fi
fi
if [ "$chat" == "y" ]; then
    tar czfpP - $myhome/.config/hexchat/ | (pv -N Hexchat -bpetr > $dest/$HOSTNAME.hexchat.tgz)
    if [ ! -f $dest/$HOSTNAME.hexchat.tgz ]; then echo " #### HexChat not backed up! #### " >> $logfile ; fi
fi
if [ "$mail" == "y" ]; then
    tar czfpP - $myhome/.thunderbird/ | (pv -N Email -bpetr > $dest/$HOSTNAME.email.tgz)
    if [ ! -f $dest/$HOSTNAME.email.tgz ]; then echo " #### Email not backed up! #### " >> $logfile ; fi
fi

# Browsers, I'm trying the --exclude-caches tag. I don't know how I feel about it yet.
# Otherwise, it's nice if you clear the caches first, otherwise it can get large
if [ "$browsers" == "y" ]; then
    tar czfpP - --exclude-caches $myhome/.mozilla | (pv -N Firefox -bpetr > $dest/$HOSTNAME.firefox.tgz)
    if [ ! -f $dest/$HOSTNAME.firefox.tgz ]; then echo " #### Firefox not backed up! #### " >> $logfile ; fi
    tar czfpP - --exclude-caches $myhome/.config/google-chrome/ | (pv -N Chromium -bpetr > $dest/$HOSTNAME.google-chrome.tgz)
    if [ ! -f $dest/$HOSTNAME.google-chrome.tgz ]; then echo " #### Google chrome not backed up! #### " >> $logfile ; fi
fi

# Network saves
if [ "$networks" == "y" ]; then
    tar czfpP - $myhome/.local/share/networkmanagement/ | (pv -N NetworkCerts -bpetr > $dest/$HOSTNAME.networkcerts2.tgz)
    if [ ! -f $dest/$HOSTNAME.networkcerts2.tgz ]; then echo " #### Network Certs not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.local/share/remoteview/ | (pv -N Dolphin1 -bpetr > $dest/$HOSTNAME.remotedolphin1.tgz)
    if [ ! -f $dest/$HOSTNAME.remotedolphin1.tgz ]; then echo " #### Remote locations for Dolphin1 not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.local/share/*.xbel* | (pv -N Dolphin2 -bpetr > $dest/$HOSTNAME.remotedolphin2.tgz)
    if [ ! -f $dest/$HOSTNAME.remotedolphin2.tgz ]; then echo " #### Remote locations for Dolphin2  not backed up! #### " >> $logfile ; fi
    sudo tar czfpP - /etc/NetworkManager/system-connections/ | (pv -N NetworkManager -bpetr > $dest/$HOSTNAME.networkconnections.tgz)
    if [ ! -f $dest/$HOSTNAME.networkconnections.tgz ]; then echo " #### Network Connections not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.vnc | (pv -N VNC -bpetr > $dest/$HOSTNAME.vnc.tgz)
    if [ ! -f $dest/$HOSTNAME.vnc.tgz ]; then echo " #### VNC not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.ssh | (pv -N SSH -bpetr > $dest/$HOSTNAME.ssh.tgz)
    if [ ! -f $dest/$HOSTNAME.ssh.tgz ]; then echo " #### SSH not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/kdeconnect/ | (pv -N KDEConnect -bpetr > $dest/$HOSTNAME.kdeconn.tgz)
    if [ ! -f $dest/$HOSTNAME.kdeconn.tgz ]; then echo " #### KDE Connect not backed up! #### " >> $logfile ; fi
fi

# other programs I have a few settings I hate tracking down
if [ "$settings" == "y" ]; then
    tar czfpP - $myhome/.local/share/gnucash/ | (pv -N GnuCash -bpetr > $dest/$HOSTNAME.gnucash.tgz)
    if [ ! -f $dest/$HOSTNAME.gnucash.tgz ]; then echo " #### GnuCash not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/Webcamoid/ | (pv -N Webcamoid -bpetr > $dest/$HOSTNAME.webcamoid.tgz)
    if [ ! -f $dest/$HOSTNAME.webcamoid.tgz ]; then echo " #### Webcamoid not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/keepassxc/ | (pv -N KeePass -bpetr > $dest/$HOSTNAME.keepass.tgz)
    if [ ! -f $dest/$HOSTNAME.keepass.tgz ]; then echo " #### KeePass not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/katerc | (pv -N Kate -bpetr > $dest/$HOSTNAME.kate.tgz)
    if [ ! -f $dest/$HOSTNAME.kate.tgz ]; then echo " #### Kate not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/plasma-org.kde.plasma.desktop-appletsrc | (pv -N DesktopIcons -bpetr > $dest/$HOSTNAME.icons.tgz)
    if [ ! -f $dest/$HOSTNAME.icons.tgz ]; then echo " #### Desktop Icons not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/.config/kactivitymanagerdrc | (pv -N MenuFavorites -bpetr > $dest/$HOSTNAME.menufavs.tgz)
    if [ ! -f $dest/$HOSTNAME.menufavs.tgz ]; then echo " #### App menu not backed up! #### " >> $logfile ; fi
    tar czfpP - $myhome/scripts/ | (pv -N Scripts -bpetr > $dest/$HOSTNAME.scripts.tgz)
    if [ ! -f $dest/$HOSTNAME.scripts.tgz ]; then echo " #### Scripts directory not backed up! #### " >> $logfile ; fi
    cp $myhome/.config/kpatrc $myhome/Documents/System/BackUps/
    if [ ! -f $myhome/.config/kpatrc ]; then echo " #### Kpatience not backed up! #### " >> $logfile ; fi
fi

# Squish Documents
if [ "$squishdocs" == "y" ]; then
    tar czfpP - $myhome/Documents/ | (pv -N Documents -bpetr > $dest/$HOSTNAME.documents.tgz)
    if [ ! -f $dest/$HOSTNAME.documents.tgz ]; then echo "Documents (squished) not backed up!" >> $logfile ; fi
    tar czfpP - $myhome/Desktop/ | (pv -N Desktop -bpetr > $dest/$HOSTNAME.desktop.tgz)
    if [ ! -f $dest/$HOSTNAME.desktop.tgz ]; then echo " #### Desktop (squished) not backed up! #### " >> $logfile ; fi
fi

# Copy docs to other location
if [ "$mine" == "y" ]; then
    rsync -ulrzh --delete-before --info=progress2 $myhome/.minecraft/saves $dest/minecraft/saves
    tar czfpP - $myhome/.minecraft/ --exclude=saves | (pv -N Minecraft -bpetr > $dest/$HOSTNAME.minecraft.tgz)
    if [ ! -f $dest/$HOSTNAME.minecraft.tgz ]; then echo " #### Minecraft not backed up! #### " >> $logfile ; fi
fi
if [ "$copydocs" == "y" ]; then
    echo "Documents"
    rsync -ulrzh --delete-before --info=progress2 $myhome/Documents/ $dest/Documents/
    doccopy=$(diff -qr $myhome/Documents/ $dest/Documents/)
    if [ ! -z "$doccopy" ]; then
        echo " #### Problems with Documents Copying #### " >> $logfile
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
        echo " #### Problems with Desktop Copying #### " >> $logfile
        read -p "Would you like to open Meld to see the differences in Desktops? (y/n)" melddesk
        if [ "$melddesk" == "y" ]; then meld $myhome/Desktop/ $dest/Desktop/ & disown ; fi
    fi
fi

# Copy Downloads to other location
if [ "$downloads" == "y" ]; then
    echo "Downloads"
    rsync -ulrzh --delete-before --info=progress2 $myhome/Downloads/ $mntpt/BackUps/Downloads/PrecisionPear/
    doccopy=$(diff -qr $myhome/Downloads/ $dest/Downloads/)
    if [ ! -z "$downloads" ]; then
        echo " #### Problems with Downloads Copying #### " >> $logfile
        read -p "Would you like to open Meld to see the differences in Downloads? (y/n)" melddown
        if [ "$melddown" == "y" ]; then meld $myhome/Downloads/ $dest/Downloads/ & disown ; fi
    fi
fi

# Copy videos, porn, whatever
if [ "$copyvids" == "y" ]; then
    # This one is special due to a space in the directory name
    echo "Videos"
 #   rsync -ulrzh $myhome/Videos/ $dest/Videos/
    rsync -ulrzh /home/dave/Videos/Webcam/ /nfs/nas/My\ Videos/vlogs/2023/
    vidcopy=$(diff -qr /home/dave/Videos/Webcam/ /nfs/nas/My\ Videos/vlogs/2023/)
 #   vidcopy=$(diff -qr $myhome/Videos/ $dest/Videos/)
    if [ ! -z "$vidcopy" ]; then
        echo " #### Problems with Video Copying #### " >> $logfile
        read -p "Would you like to open Meld to see the differences in Videos? (y/n)" meldvid
#        if [ "$meldvid" == "y" ]; then meld $myhome/Videos/ $dest/Videos/ & disown ; fi
        if [ "$meldvid" == "y" ]; then meld /home/dave/Videos/Webcam/ /nfs/nas/My\ Videos/vlogs/2023/ & disown ; fi
    fi
fi

# Are there errors?
if [ -f $logfile ]; then
    echo "There were issues with this backup!"
    echo "See $logfile"
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
