require 'pty'
fluidsynth_command = 'fluidsynth -s -o "shell.port=9988" -a alsa -g 3 -p fluidsynth /usr/share/sounds/sf2/FluidR3_GM.sf2'
aconnect_command = "aconnect 'Alesis Recital':0 'fluidsynth':0"


PTY.spawn(fluidsynth_command) do |reader, writer|
  # reader.expect(/What is the application name/)
  puts 'probably running'
  writer.puts("select 0 1 0 5")
  sleep 1
  system(aconnect_command)
  # sleep 30
  while true do end
end