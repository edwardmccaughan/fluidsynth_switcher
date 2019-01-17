require 'portmidi'
Portmidi.start

control_keyboard = Portmidi.input_devices.find{ |input| input.name.include?('Keystation Mini 32') }
control_keyboard_input = Portmidi::Input.new(control_keyboard.device_id)

loop do
  begin
    events = control_keyboard_input.read(16)
    if events
      events.each do |event|
        puts event[:message].inspect
      end
    end
  end
end