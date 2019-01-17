require 'pty'
require 'portmidi'
require 'pry'

class FluidSwitcher
  MIDI_KEY_INSTRUMENTS = {
    71 => 0,  # piano
    72 => 9,  # glockenspiel
    74 => 22, # harmonica
    76 => 52, # ah choir 
    77 => 56, # trumpet
    79 => 49  # slow strings
  }

  CONTROL_KEYBOARD_NAME = 'Keystation Mini 32'
  SOUND_KEYBOARD_NAME = 'Alesis Recital'

  FLUIDSYNTH_COMMAND = 'fluidsynth -s -o "shell.port=9988" -a alsa -g 3 -p fluidsynth /usr/share/sounds/sf2/FluidR3_GM.sf2'
  ACONNECT_COMMAND = "aconnect '#{SOUND_KEYBOARD_NAME}':0 'fluidsynth':0"

  def initialize
    @control_keyboard_input = get_control_keyboard

    listen_loop
  end

  def listen_loop
    PTY.spawn(FLUIDSYNTH_COMMAND) do |reader, writer|
      puts 'launched fluidsynth'

      $fluidsynth = writer 
      sleep 1
      puts ACONNECT_COMMAND
      system(ACONNECT_COMMAND)
      

      loop do
        check_for_midi_inputs
        # portmidi's read blocks the cpu and we don't need fast response times for changing instruments
        # so just sleep rather than waste cpu cycles that the gui will need
        sleep 0.5 
      end
    end
  end

  def check_for_midi_inputs
    events = @control_keyboard_input.read(16)
      if events # maybe don't need this line
        events.each do |event|
          key = event[:message][1]
          is_down = event[:message][2] != 0

          puts "key: #{key}, #{is_down}"
       
          change_instrument(key) if is_down
        end
      end
  end


  def get_control_keyboard
    Portmidi.start
    control_keyboard = Portmidi.input_devices.find{ |input| input.name.include?(CONTROL_KEYBOARD_NAME) }
    raise 'could not find control keyboard, is it plugged in?' if control_keyboard.nil?
    # binding.pry
    Portmidi::Input.new(control_keyboard.device_id)
  end

  def change_instrument(midi_key_pressed)
    instrument = MIDI_KEY_INSTRUMENTS[midi_key_pressed]
    puts "changing to instrument"
    $fluidsynth.puts("select 0 1 0 #{instrument}")
  end
end



FluidSwitcher.new











