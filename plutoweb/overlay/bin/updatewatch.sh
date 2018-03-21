#!/bin/sh
# Don't need to run this directly, its called on boot if autoupdate=y

# Our job is to loop and check for the existence of update.zip and update.zip.md5sum
# If we find update.zip, we'll assume its legit and use it.  This makes us very hackable.
# You could use any update.zip and we will blindly extract it right over the top of /
# The update.zip is simply the overlay folder zipped up.

# If we see an update.zip.md5sum first, we'll use it to verify the upload
# Again, this screams, "HACK ME!".  But for real, hack it better.
# Source current settings
. /bin/readsettings.sh >/dev/null

SLEEP=10s

while [ "$autoupdate" = "y" ]
do
	sleep $SLEEP
if [ "$updatesrunning" = "y" ]; then
	sleep $SLEEP
else
	for file in /root/update.zip
		do
	if [ -f $file.md5sum ]; then
		if diff -q $file.md5sum /root/.update.zip.md5sum; then
                        echo "*** Auto-updates enabled - already up to date as $file ***" >>/etc/motd
                        rm -f $file $file.md5sum
                        updatesrunning=n
                        sed -i 's/updatesrunning=y/updatesrunning=n/' /root/temp-settings
                else
		updatesrunning=y
		sed -i 's/updatesrunning=n/updatesrunning=y/' /root/temp-settings
		echo "Found $file.md5sum, checking for $file"
		sleep 3 
		if [ -f $file ]; then
			echo "Found $file"
			sleep 10
			if [ "$(md5sum -b $file | awk -F\\  '{ print $1 }')" = "$(cat $file.md5sum | awk -F\\  '{ print $1 }')" ]; then
				/etc/init.d/S95autostart stop
				cd / && unzip -o $file && echo "*** Auto-updates enabled and $file completed successfully with md5 ***" >>/etc/motd && echo "$file update complete!" && rm -f /root/temp-settings && /etc/init.d/S95autostart start
				rm -f $file $file.md5sum
			else
				echo "$file failed the md5sum."
				echo "*** Auto-updates enabled but $file failed the md5sum ***" >>/etc/motd
				rm -f $file $file.md5sum
				updatesrunning=n
				sed -i 's/updatesrunning=y/updatesrunning=n/' /root/temp-settings
			fi
		else
			echo "$file not found."
			rm -f $file $file.md5sum
			updatesrunning=n
			sed -i 's/updatesrunning=y/updatesrunning=n/' /root/temp-settings
		fi
		fi
	fi
	if [ -f $file ]; then
		updatesrunning=y
		sed -i 's/updatesrunning=n/updatesrunning=y/' /root/temp-settings
		echo "Found $file - Waiting 10 seconds before proceeding..."
		sleep 10
		/etc/init.d/S95autostart stop
		cd / && unzip -o $file && echo "*** Auto-updates enabled and $file completed successfully ***" >>/etc/motd && echo "$file update complete!" && rm -f /root/temp-settings && /etc/init.d/S95autostart start
		rm -f $file $file.md5sum
		sed -i 's/updatesrunning=y/updatesrunning=n/' /root/temp-settings
	fi
	done
fi
. /bin/readsettings.sh >/dev/null
done