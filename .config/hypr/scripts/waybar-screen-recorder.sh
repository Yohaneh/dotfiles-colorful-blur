#!/bin/bash 

pid=`pgrep wf-recorder`
status=$?

if [ $status != 0 ] 
then 
  wf-recorder -p b=8000M --audio=alsa_output.usb-Speed_Dragon_Fosi_Audio_SK02-01.iec958-stereo.monitor -f $(xdg-user-dir VIDEOS)/$(date +'recording_%Y-%m-%d-%H%M%S.mp4');
else 
  pkill --signal SIGINT wf-recorder
fi;
