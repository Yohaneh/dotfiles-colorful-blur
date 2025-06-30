#!/bin/python3

# SETTINGS
TIME = 300 # seconds
FANCY = False # causes applications to lag on my machine
WALLPAPER_DIRECTORY = "~/.config/hypr/wallpapers"

# CODE
import os
import random
import subprocess
import threading

def command(cmd):
    return os.popen(cmd).read().strip()

# This is a workaround related to swww-daemon crashing randomly since 0.7.x
command("rm -rf  ~/.cache/swww/")

if command("pidof swww-daemon") == "":
    subprocess.Popen(["swww-daemon"])

wallpaperDir = os.path.expanduser(WALLPAPER_DIRECTORY)
wallpaperMemory = []

rawmonitors = command("wlr-randr | grep \\\"").split("\n")
monitors = []
for monitor in rawmonitors:
    monitors.append(monitor.split(" \"")[0])

def set_interval(func, sec):
    def func_wrapper():
        set_interval(func, sec)
        func()
    t = threading.Timer(sec, func_wrapper)
    t.start()
    return t

def set_wallpaper():
    if os.path.exists(os.path.expanduser("~/.disable-random-wallpaper")):
        print("~/.disable-random-wallpaper found: script disabled!")
        return

    global wallpaperDir
    global wallpaperMemory
    global monitors
    global FANCY

    print("changing wallpaper...")
    print("memory size: " + str(len(wallpaperMemory)))
    print("memory content: ")
    for string in wallpaperMemory:
        print(" - " + string)

    wallpapers = os.listdir(wallpaperDir)

    if len(wallpaperMemory) != 0:
        for entry in wallpaperMemory:
            try:
                wallpapers.remove(entry)
            except:
                # We need something here because python
                print("Could not find current wallpaper in wallpaper folder!")

    selectedWallpapers = []

    for output in monitors:
        wp = wallpapers.pop(random.randint(0, len(wallpapers)-1))
        if FANCY:
            command("swww img --transition-fps 172 --transition-type any --transition-duration 1 " + output + " " + wallpaperDir + "/" + wp)
        else:
            command("swww img --transition-fps 172 --transition-type any --transition-duration 1 -o " + output + " " + wallpaperDir + "/" + wp) # --transition-type simple --transition-step 30 
        selectedWallpapers.append(wp)

    wallpaperMemory = selectedWallpapers
    return

set_wallpaper()
set_interval(set_wallpaper,TIME)
