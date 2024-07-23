# Main Labjack 
# Retain Potential Labjack support
(@isdefined HANDLE) || (HANDLE = openUSBConnection(0))
caliInfo = getCalibrationInformation(HANDLE)
(@isdefined HANDLE1) || (HANDLE1 = openUSBConnection(1))
caliInfo1 = getCalibrationInformation(HANDLE1)
caliInfoTdac1 = getTdacCalibrationInformation(HANDLE1,0)


portCPC = CondensationParticleCounters.config(:MAGIC, "/dev/ttyUSB1")
# CPCType1, flowRate1, port1 = configure_serial_port(2)
# CPCType2, flowRate2, port2 = configure_serial_port(1)
portTE1 = TETechTC3625RS232.configure_port(get_gtk_property(gui["TESerialPort1"], "text", String))

function start_acquisition_loops()
    @async CondensationParticleCounters.stream(
        portCPC,
        :MAGIC,
        "/home/aerosol/Data/magic/cpc",
    )
end

start_acquisition_loops()

