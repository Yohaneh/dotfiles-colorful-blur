sed -i 's/monitor = HDMI-A-1,modeline 421.20 1920 1968 2000 2080 1080 1083 1088 1125 +HSync +VSync, auto, 1,vrr,1/monitor = HDMI-A-1,1920x1080@60.00, auto, 1,vrr,1/' /home/jveju/.config/hypr/hyprland.conf
sleep 0.1
sed -i 's/monitor = HDMI-A-1,1920x1080@60.00, auto, 1,vrr,1/monitor = HDMI-A-1,modeline 421.20 1920 1968 2000 2080 1080 1083 1088 1125 +HSync +VSync, auto, 1,vrr,1/' /home/jveju/.config/hypr/hyprland.conf
