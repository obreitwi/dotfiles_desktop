#!/bin/bash

# Taken from: http://askubuntu.com/questions/17791/can-i-downmix-stereo-audio-to-mono

# create sink using:
# pacmd load-module module-remap-sink sink_name=mono master=$(pacmd list-sinks | grep -m 1 -oP 'name:\s<\K.*(?=>)') channels=2 channel_map=mono,mono

 #!/bin/bash

if [ "* index: 0" == "$(pacmd list-sinks | grep "*" | sed 's/^ *//')" ];
   then pacmd set-default-sink 1 && echo "Mono";
   SINK=1;
else
   pacmd set-default-sink 0 && echo "Stereo";
   SINK=0; 
fi;
pacmd list-sink-inputs | grep index | grep -o '[0-9]*' | while read -r line; 
   do pacmd move-sink-input $line $SINK;
done;

