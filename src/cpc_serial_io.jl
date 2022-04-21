# -
# cpc_serial.io
#
# Configuration and read routines for seria communication with 
# condensation particle counters. Currently supported models
# TSI 3022 (Precursor of the ultrafine CPC)
# TSI 3762 (a low cost version of TSI 3010)
# TSI 3771/3772 (follow model of TSI 3010)
# TSI 3776C (nano particle counter)
#
# Functions: 
#  (1) configure_serial_port - Read config from GUI and setup port
#  (2) read_cpc - query CPC and return concentration
#
#

# Author: Markus Petters
#         NC State University
#         Raleigh, NC 27695-8208
# -

# This function polls the gui for port information.
# Opens and configures port

using LibSerialPort

function port_requirements(CPCType)
	if (CPCType == :TSI3771) || (CPCType == :TSI3772) || (CPCType == :TSI3776C)
		return 115200, 8, 1, SP_PARITY_NONE
	elseif (CPCType == :TSI3010)
		return 9600, 7, 1, SP_PARITY_EVEN
	else
		throw("Error: CPC Type not defined")
	end
end

function configure_serial_port(n)
    CPC = get_gtk_property(gui["CPCType$n"], "active-id", String)
    q = get_gtk_property(gui["CPCSampleFlow$n"], "text", String)
    serialPort = get_gtk_property(gui["SerialPort$n"], "text", String)

    flowRate = parse(Float64, q)
    CPCType = Symbol(CPC)
	baudRate, dataBits, stopBits, parity = port_requirements(CPCType)

    port = LibSerialPort.sp_get_port_by_name(serialPort)
    LibSerialPort.sp_open(port, SP_MODE_READ_WRITE)
    config = LibSerialPort.sp_get_config(port)
    LibSerialPort.sp_set_config_baudrate(config, baudRate)
    LibSerialPort.sp_set_config_parity(config, parity)
    LibSerialPort.sp_set_config_bits(config, dataBits)
    LibSerialPort.sp_set_config_stopbits(config, stopBits)
    LibSerialPort.sp_set_config_rts(config, SP_RTS_OFF)
    LibSerialPort.sp_set_config_cts(config, SP_CTS_IGNORE)
    LibSerialPort.sp_set_config_dtr(config, SP_DTR_OFF)
    LibSerialPort.sp_set_config_dsr(config, SP_DSR_IGNORE)

    LibSerialPort.sp_set_config(port, config)

    return CPCType, flowRate, port
end

# Query CPC and return concentration
# Note that flowrate is only iunvoced for 3762
function readWriteCPC(port, CPCType, flowRate, sigV)
    
	LibSerialPort.sp_drain(port)
    LibSerialPort.sp_flush(port, SP_BUF_OUTPUT)

    if CPCType == :TSI3022
        c = String(bytes)
        f = split(c, "\r")
        N = try
            parse(Float64, f[1])
        catch
            missing
        end
    end

	if (CPCType == :TSI3762) || (CPCType == :TSI3010)
		str = @sprintf("%05i", sigV*1000) 
        LibSerialPort.sp_nonblocking_write(port, "RD\r")
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 10)
        c = String(bytes)
        f = split(c, "\r")
        N = try
            parse(Float64, f[1]) 
        catch
            0.0
        end
        N = N 
		sleep(0.5)
		LibSerialPort.sp_nonblocking_write(port, "V"*str*"\r")
    end

    if (CPCType == :TSI3771) || (CPCType == :TSI3772) || (CPCType == :TSI3776C)
		str = @sprintf("%5.3f", sigV) 
        LibSerialPort.sp_nonblocking_write(port, "RALL\r")
		sleep(0.5)
		LibSerialPort.sp_nonblocking_write(port, "SVO,"*str*"\r")
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 100)
        c = String(bytes)
        f = split(c, ",")
        N = try
			parse(Float64, f[1][3:end])
        catch
            0.0
        end
    end
	return N
end
