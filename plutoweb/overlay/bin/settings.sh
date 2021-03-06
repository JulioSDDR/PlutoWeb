#!/bin/sh

. /bin/readsettings.sh >/dev/null

# Help
if [ $# = 0 ]; then
echo "
Usage: settings.sh <-i> <-r prog> <-R Hrs> <-u y|n> <-c HZ> <-s HZ> <-S SPS>
                   <-d DEMOD> <-g DB> <-p PPM> <-E y|d> <-W y>

Make changes to the operations of the PlutoSDR.
General Options:
        -i      Interactive mode
        -r      Program to run (openwebrx,dump1090,SoapyRemote,none) [$autostart]
        -R      Enable/Disable auto-reboot (In hours, 0 to disable) [$autoreboot]
                (Auto-reboot doesn't take effect now, use with -W y and reboot)
        -u      Enable/Disable auto-updates (y/n) [$autoupdate]
OpenWebRX Options:
        -c      Center frequency in Hz (70000000-6000000000) [$center_freq]
        -s      Starting frequency in Hz (70000000-6000000000) [$start_freq]
        -S      Sample rate in SPS (samples/sec) (65105-10000000) [$samp_rate]
        -d      Demodulation (nfm,am,lsb,usb,cw) [$start_mod]
        -g      RF gain in dB (0-89) [$rf_gain]
        -p      PPM [$ppm]
NVRAM Options:
        -E y|d  Erase all settings from NVRAM (d to reset to defaults too)
        -W y    Write changes to NVRAM for persistence"
exit
fi

# Read args from command line
RESTARTNOW=0
while [[ $# -gt 0 ]]; do
i="$1"
case $i in
	-E)
	if [ "$2" == "y" ]; then
	echo "Erase command issued, ignoring all other options!"
	/bin/savenow.sh erase
	exit
	fi
        if [ "$2" == "d" ]; then
        echo "Erase and reset issued, ignoring all other options!"
        /bin/savenow.sh erase
	rm /root/plutoweb.conf
	/etc/init.d/S95autostart restart
	exit
	fi
	shift
	shift;;
	-W)
	if [ "$2" == "y" ]; then
	WRITE=y
	fi
	shift
	shift;;
	-r)
	sed -i "s/$autostart/$2/" /root/plutoweb.conf
	autostart=$2
	RESTARTNOW=1
	shift
	shift;;
	-R)
	sed -i "s/autoreboot=$autoreboot/autoreboot=$2/" /root/plutoweb.conf
	autoreboot=$2
        shift
        shift;;
	-u)
	sed -i "s/autoupdate=$autoupdate/autoupdate=$2/" /root/plutoweb.conf
	autoupdate=$2
	if [ "$2" = "y" ] || [ "$2" = "Y" ]; then
		/etc/init.d/S95autostart stop
		/bin/sh /etc/init.d/S97autoupdate restart
		/etc/init.d/S95autostart start
	fi
	if [ "$2" = "n" ] || [ "$2" = "N" ]; then
		/bin/sh /etc/init.d/S97autoupdate stop
	fi
        shift
        shift;;
	-c)
	sed -i "s/center_freq=$center_freq/center_freq=$2/" /root/plutoweb.conf
	center_freq=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -s)
	sed -i "s/start_freq=$start_freq/start_freq=$2/" /root/plutoweb.conf
	start_freq=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -S)
	sed -i "s/samp_rate=$samp_rate/samp_rate=$2/" /root/plutoweb.conf
	samp_rate=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -d)
	sed -i "s/$start_mod/$2/" /root/plutoweb.conf
	start_mod=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -g)
	sed -i "s/rf_gain=$rf_gain/rf_gain=$2/" /root/plutoweb.conf
	rf_gain=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -p)
	sed -i "s/ppm=$ppm/ppm=$2/" /root/plutoweb.conf
	ppm=$2
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
        shift
        shift;;
        -i)
. /bin/readsettings.sh
echo "Changes take effect now and reset to previous on reboot unless -W is used."
echo "This also means that if auto-reboot is enabled, they will be reset then!"
read -p "Do you want to change these settings? (y/n): " yn
case $yn in
	[Yy]* ) 
echo "If you make a mistake, CTRL+C to exit and then start over."
read -p "Auto-start anything? (openwebrx,dump1090,SoapyRemote,none): [$autostart] " autostart_new
read -p "Enable scheduled auto-reboot? (In hours, 0 to disable): [$autoreboot] " autoreboot_new
read -p "Enable automatic updates? (y/n): [$autoupdate] " autoupdate_new
read -p "Enter the new center frequency (70000000-6000000000): [$center_freq] " center_freq_new
read -p "Enter the new starting frequency (70000000-6000000000): [$start_freq] " start_freq_new
read -p "Enter the new sample rate (65105-10000000): [$samp_rate] " samp_rate_new
read -p "Enter the new starting demodulator (nfm,am,lsb,usb,cw): [$start_mod] " start_mod_new
read -p "Enter the new RF gain in dB (0-89): [$rf_gain] " rf_gain_new
read -p "Enter the new PPM adjustment: [$ppm] " ppm_new
read -p "Should these settings be saved to NVRAM now? (y/n): [n] " savenow_new
echo "Writting settings to temp file..."
if [ -n "$autostart_new" ]; then
	sed -i "s/$autostart/$autostart_new/" /root/plutoweb.conf
	RESTARTNOW=1
fi
if [ -n "$autoreboot_new" ]; then
	sed -i "s/autoreboot=$autoreboot/autoreboot=$autoreboot_new/" /root/plutoweb.conf
		
fi
if [ -n "$autoupdate_new" ]; then
	sed -i "s/autoupdate=$autoupdate/autoupdate=$autoupdate_new/" /root/plutoweb.conf
	if [ "$autoupdate_new" = "y" ] || [ "$autoupdate_new" = "Y" ]; then
		/bin/sh /etc/init.d/S97autoupdate restart
	fi
	if [ "$autoupdate_new" = "n" ] || [ "$autoupdate_new" = "N" ]; then
		/bin/sh /etc/init.d/S97autoupdate stop
	fi
fi
if [ -n "$center_freq_new" ]; then
	sed -i "s/center_freq=$center_freq/center_freq=$center_freq_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$start_freq_new" ]; then
	sed -i "s/start_freq=$start_freq/start_freq=$start_freq_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$samp_rate_new" ]; then
	sed -i "s/samp_rate=$samp_rate/samp_rate=$samp_rate_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$start_mod_new" ]; then
	sed -i "s/$start_mod/$start_mod_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$rf_gain_new" ]; then
	sed -i "s/rf_gain=$rf_gain/rf_gain=$rf_gain_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$ppm_new" ]; then
	sed -i "s/ppm=$ppm/ppm=$ppm_new/" /root/plutoweb.conf
	if [ "$autostart" = "openwebrx" ]; then
		RESTARTNOW=1
	fi
fi
if [ -n "$savenow_new" ]; then
case $savenow_new in
	[Yy]* )
	WRITE=y
	;;
esac
fi
shift;;
	* )
exit;;
esac;;
	* )
	echo "Wrong answer...try again."
	exit;;
esac
done

# Re-run readsettings.sh to re-write settings.txt for PlutoWeb
. /bin/readsettings.sh >/dev/null

if [ "$WRITE" = "y" ]; then
	/bin/savenow.sh yes
fi

echo "Done."
if [ "$RESTARTNOW" = "1" ]; then
	echo "One or more changes require (re)starting the running program, doing now..."
	/etc/init.d/S95autostart restart
fi
