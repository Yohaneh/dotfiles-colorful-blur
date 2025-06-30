#!/bin/bash

tooltip="$(playerctl metadata title) - $(playerctl metadata artist) - $(playerctl metadata album)"
text="$(playerctl metadata title) - $(playerctl metadata artist)"

echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\"}"
