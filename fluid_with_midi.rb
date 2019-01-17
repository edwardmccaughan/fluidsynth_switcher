require 'pty'
require 'portmidi'

fluidsynth_command = 'fluidsynth -s -o "shell.port=9988" -a alsa -g 3 -p fluidsynth /usr/share/sounds/sf2/FluidR3_GM.sf2'
aconnect_command = "aconnect 'Alesis Recital':0 'fluidsynth':0"

$midi_key_instruments = {
  48 => 0,
  50 => 9,  # glockenspiel
  52 => 22, # harmonica
  53 => 52, # ah choir 
  55 => 56, # trumpet
  57 => 49  # slow strings
}


def check_for_midi_inputs
  events = $control_keyboard_input.read(16)
    if events
      events.each do |event|
        key = event[:message][1]
        is_down = event[:message][2] != 0

        puts "key: #{key}, #{is_down}"

        if is_down
          change_instrument(key)
        end
      end
    end
end


def get_control_keyboard
  Portmidi.start

  keystation = Portmidi.input_devices.find{ |input| input.name.include?('Keystation Mini 32') }
  Portmidi::Input.new(keystation.device_id)
end

def change_instrument(midi_key_pressed)
  instrument = $midi_key_instruments[midi_key_pressed]
  puts "changing to instrument"
  $fluidsynth.puts("select 0 1 0 #{instrument}")
end





PTY.spawn(fluidsynth_command) do |reader, writer|
  puts 'probably running'

  $fluidsynth = writer 
  sleep 1
  system(aconnect_command)
  
  $control_keyboard_input = get_control_keyboard
  
  loop do
    check_for_midi_inputs
    # portmidi's read blocks the cpu and we don't need fast response times for changing instruments
    # so just sleep rather than waste cpu cycles that the gui will need
    sleep 0.5 
  end
end


