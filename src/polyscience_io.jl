# +
# polyscience_io.jl
# I/O functions for Polyscience Programmable Temperature Controller
#
# -

## Configures Serial Port (pg. 40 manual)
function configure_polyscience_port(name)
    port = LibSerialPort.sp_get_port_by_name(name)
    LibSerialPort.sp_open(port, SP_MODE_READ_WRITE)
    config = LibSerialPort.sp_get_config(port)
    LibSerialPort.sp_set_config_baudrate(config, 9600)
    LibSerialPort.sp_set_config_parity(config, SP_PARITY_NONE)
    LibSerialPort.sp_set_config_bits(config, 8)
    LibSerialPort.sp_set_config_stopbits(config, 1)
    LibSerialPort.sp_set_config_rts(config, SP_RTS_OFF)
    LibSerialPort.sp_set_config_cts(config, SP_CTS_IGNORE)
    LibSerialPort.sp_set_config_dtr(config, SP_DTR_OFF)
    LibSerialPort.sp_set_config_dsr(config, SP_DSR_IGNORE)
    LibSerialPort.sp_set_config(port, config)
    return port
end

function read_polyscience_temperature(port)
    LibSerialPort.sp_flush(port,SPBuffer(3))
    LibSerialPort.sp_nonblocking_write(port, "RT\r")
    sleep(0.1)
    nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port,  20)
    read = String(bytes)
    f = split(read, "\r")
    T = try 
        parse(Float64,f[1])
    catch 
        missing
    end
end

function set_polyscience_temperature(port, T::Union{Missing,Float64})
    (typeof(T) == Missing) || LibSerialPort.sp_nonblocking_write(port, "SS"*@sprintf("%3.2f",T)*"\r")
end
