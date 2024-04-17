
module PrintedOpticalParticleSpectrometer

using LibSerialPort
using Dates
using DataStructures
using Chain

const dataBuffer = CircularBuffer{UInt8}(14400)

function config(portname::String)
    baudRate = 115200
    dataBits = 8
    stopBits = 1
    parity = SP_PARITY_NONE

    port = LibSerialPort.sp_get_port_by_name(portname)
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

    return port
end

function stream(port::Ptr{LibSerialPort.Lib.SPPort}, file::String)
    Godot = @task _ -> false

    function read(port, file)
        try
            nbytes_read, bytes = LibSerialPort.sp_nonblocking_read(port, 12512)
            str = String(bytes[1:nbytes_read])
            filter(x -> x .== "\n", str)
            tc = Dates.format(now(), "yyyymmdd")
            open(file * "_" * tc * ".txt", "a") do io
                write(io, str)
            end
            append!(dataBuffer, bytes[1:nbytes_read])
        catch
            println("I fail")
        end
    end

    while (true)
        read(port, file)
        sleep(1)
    end

    wait(Godot)
end

function is_valid(x)
    try
        @chain x String (_[1:4] == "POPS") & (_[end] == '\r')
    catch
        false
    end
end

function testline(x)
    try
       x[end]
    catch
        missing
    end
end

function get_current_record()
    x = deepcopy(PrintedOpticalParticleSpectrometer.dataBuffer[1:end])
    @chain x begin
        String(_)
        split(_, '\n')
        filter(is_valid, _)
        testline(_)
    end
end

end
