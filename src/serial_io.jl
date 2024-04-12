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

function readCPC(port, CPCType, flowRate)
    sp_drain(port)
    if CPCType == :TSI3762
        LibSerialPort.sp_nonblocking_write(port, "RB\r")
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 10)
        c = String(bytes)
        f = split(c, "\r")
        N = try
            parse(Float64, f[1]) / 60.0
        catch
            0.0
        end
        N = N * 3.0 / flowRate
        #N = 3*parse(Float64,f[1])
    end
    if CPCType == :TSI3771 || CPCType == :TSI3772
        LibSerialPort.sp_nonblocking_write(port, "RALL\r")
        sleep(0.5)
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 80)
        c = String(bytes)
        f = split(c, ",")
        N = try
            parse(Float64, f[1])
        catch
            0.0
        end
    end
    if CPCType == :TSI3776C
        sp_nonblocking_write(port, "RALL\r")
        nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 80)
        c = String(bytes)
        f = split(c, ",")
        N = try
            parse(Float64, f[1])
        catch
            0.0
        end
    end

    residual = try
        split(c, "\r")
    catch
        "NONE"
    end

    return N, residual
end
