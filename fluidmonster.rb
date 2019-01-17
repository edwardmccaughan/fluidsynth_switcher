

fluidsynth_command = 'fluidsynth -s -o "shell.port=9988" -a alsa -g 3 -p fluidsynth /usr/share/sounds/sf2/FluidR3_GM.sf2'
aconnect_command = "aconnect 'Alesis Recital':0 'fluidsynth':0"

fluidsynth = spawn(fluidsynth_command)
Process.detach(pid)

system(aconnect_command)



# ensure
# kill fluidsynth
# aconnect -x