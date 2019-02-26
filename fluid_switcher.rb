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

  SOUNDFONT_PATH='/usr/share/sounds/sf2/FluidR3_GM.sf2'
  FLUIDSYNTH_COMMAND = "fluidsynth -s -o 'shell.port=9988' -a alsa -g 1 -p fluidsynth '#{SOUNDFONT_PATH}'"
  ACONNECT_COMMAND = "aconnect '#{SOUND_KEYBOARD_NAME}':0 'fluidsynth':0"

  attr_accessor :fluidsynth, :control_keyboard_input

  def initialize
    Portmidi.start


    puts "starting fluidsynth with: #{FLUIDSYNTH_COMMAND}"
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

  def connect_to_control_keyboard
    return if keyboard_connected?(CONTROL_KEYBOARD_NAME)

    if(keyboard_plugged_in?(CONTROL_KEYBOARD_NAME))
      sleep 1 # sometimes it isn't recognised right away?
      @control_keyboard_input.close if @control_keyboard_input
      control_keyboard = Portmidi.input_devices.find{ |input| input.name.include?(CONTROL_KEYBOARD_NAME) }
      @control_keyboard_input = Portmidi::Input.new(control_keyboard.device_id)
      puts 'connected to control keyboard'
    else
      puts 'could not find control keyboard, is it plugged in?'
    end
    # binding.pry
  end

  def connect_to_sound_keyboard
    return if keyboard_connected?(SOUND_KEYBOARD_NAME)

    if(keyboard_plugged_in?(SOUND_KEYBOARD_NAME))
      system(ACONNECT_COMMAND)
      puts 'connected sound keyboard'
    else
      puts 'sound keyboard does not seem to be connected'
    end
  end

  def check_for_midi_inputs
    return unless keyboard_connected?(CONTROL_KEYBOARD_NAME)
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

  def change_instrument(midi_key_pressed)
    instrument = MIDI_KEY_INSTRUMENTS[midi_key_pressed]
    puts "changing to instrument #{instrument}"
    @fluidsynth.puts("select 0 1 0 #{instrument}")
  end

  def keyboard_plugged_in?(name)
    `aconnect -l | grep '#{name}'`.include?('client')
  end

  def keyboard_connected?(name)
    `aconnect -l | grep -A 1 '#{name}'`.include?('Connecting')
  end
end

FluidSwitcher.new











