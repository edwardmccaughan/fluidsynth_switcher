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

  FLUIDSYNTH_COMMAND = 'fluidsynth -s -o "shell.port=9988" -a alsa -g 1 -p fluidsynth /usr/share/sounds/sf2/FluidR3_GM.sf2'
  ACONNECT_COMMAND = "aconnect '#{SOUND_KEYBOARD_NAME}':0 'fluidsynth':0"


  attr_accessor :fluidsynth, :control_keyboard_input

  def initialize
    # @control_keyboard_input = get_control_keyboard

    Portmidi.start

    PTY.spawn(FLUIDSYNTH_COMMAND) do |reader, writer|
      @fluidsynth = writer 
      sleep 1 # fluidsynth needs some time to start up
      puts 'launched fluidsynth'

      listen_loop
    end
  end

  def listen_loop  
    loop do
      connect_to_sound_keyboard
      connect_to_control_keyboard

      check_for_midi_inputs
      # portmidi's read blocks the cpu and we don't need fast response times for changing instruments
      # so just sleep rather than waste cpu cycles that the gui will need
      sleep 0.5 
    end
  end

  def check_for_midi_inputs
    events = @control_keyboard_input.read(16)
    return if events.nil?

    events.each do |event|
      puts event.inspect
      key = event[:message][1]
      is_down = event[:message][2] != 0

      puts "key: #{key}, #{is_down}"
   
      change_instrument(key) if is_down
    end
  end


  def connect_to_control_keyboard
    return if control_keyboard_connected?

    if(control_keyboard_plugged_in?)
      @control_keyboard_input.close if @control_keyboard_input
      control_keyboard = Portmidi.input_devices.find{ |input| input.name.include?(CONTROL_KEYBOARD_NAME) }
      @control_keyboard_input = Portmidi::Input.new(control_keyboard.device_id)
      puts 'connected to control keyboard'
    else
      puts 'could not find control keyboard, is it plugged in?'
    end
    # binding.pry
  end

  def change_instrument(midi_key_pressed)
    instrument = MIDI_KEY_INSTRUMENTS[midi_key_pressed]
    puts "changing to instrument #{instrument}"
    @fluidsynth.puts("select 0 1 0 #{instrument}")
  end

  def check_for_control_keyboard_disconnect
    @control_keyboard = Portmidi.input_devices.find{ |input| input.name.include?(CONTROL_KEYBOARD_NAME) }
  end

  def control_keyboard_plugged_in?
    `aconnect -l | grep 'Keystation'`.include?('client')
  end

  def control_keyboard_connected?
    `aconnect -l | grep -A 1 'Keystation'`.include?('Connecting')
  end

  def sound_keyboard_plugged_in?
    `aconnect -l | grep 'Alesis'`.include?('client')
  end

  def sound_keyboard_connected?
    `aconnect -l | grep -A 1 'Alesis'`.include?('Connecting')
  end


  def connect_to_sound_keyboard
    return if sound_keyboard_connected?

    if(sound_keyboard_plugged_in?)
      system(ACONNECT_COMMAND)
      puts 'connected sound keyboard'
    else
      puts 'sound keyboard does not seem to be connected'
    end
  end
end



FluidSwitcher.new











