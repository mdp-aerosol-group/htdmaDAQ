# Main Labjack 
(@isdefined HANDLE) || (HANDLE = openUSBConnection(-1))
caliInfo = getCalibrationInformation(HANDLE)
caliInfoTdac = getTdacCalibrationInformation(HANDLE,2)

CPCType1, flowRate1, port1 = configure_serial_port(1)
CPCType2, flowRate2, port2 = configure_serial_port(2)
CPCType3, flowRate3, port3 = configure_serial_port(3)

portTE1 = TETechTC3625RS232.configure_port(get_gtk_property(gui["TESerialPort1"], "text", String))
portTE2 = TETechTC3625RS232.configure_port(get_gtk_property(gui["TESerialPort2"], "text", String))
portPS = configure_polyscience_port(get_gtk_property(gui["BathSerialPort1"], "text", String))
portOpti = GEOptiSonde.configure_port("/dev/ttyUSB5")
portTE3 = TETechTC3625RS232.configure_port("/dev/ttyUSB6")
TETechTC3625RS232.turn_power_on(portTE3)

TETechTC3625RS232.write_proportional_bandwidth(portTE1, 2.2)
TETechTC3625RS232.write_proportional_bandwidth(portTE2, 5.0)
TETechTC3625RS232.write_integral_gain(portTE1, 0.11)
TETechTC3625RS232.write_integral_gain(portTE2, 0.11)

#TETechTC3625RS232.turn_power_on(portTE1)
#TETechTC3625RS232.turn_power_on(portTE2)

TETechTC3625RS232.turn_power_off(portTE1)
TETechTC3625RS232.turn_power_off(portTE2)
