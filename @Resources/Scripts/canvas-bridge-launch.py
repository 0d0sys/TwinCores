# canvas-bridge-launch.py - spawns the bridge server fully detached
# (DETACHED_PROCESS: no console window, survives the parent's exit),
# then exits immediately so RunCommand returns right away.
# NOTE: cmd /c start and wscript/.vbs both failed on this system
# (quote mangling / VBScript disabled on newer Win11 builds).
import subprocess

DETACHED_PROCESS = 0x00000008
CREATE_NEW_PROCESS_GROUP = 0x00000200
CREATE_NO_WINDOW = 0x08000000

subprocess.Popen(
    [
        r"C:\Python315\pythonw.exe",
        r"C:\Users\might\Documents\Rainmeter\Skins\TwinCores"
        r"\@Resources\Scripts\canvas-bridge.py",
    ],
    creationflags=DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP | CREATE_NO_WINDOW,
    stdin=subprocess.DEVNULL,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
    close_fds=True,
)
