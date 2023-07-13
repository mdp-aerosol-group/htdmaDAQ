using PyCall

const EI1050_FIO_PIN_STATE = 0 
const SDAP = 2
const SCLP = 3
const DATA_PIN_NUM = 6
const CLOCK_PIN_NUM = 7
const POWER_PIN_NUM = 5

# Load and initialize labjack
u3 = pyimport("u3")                           
(@isdefined handle) || (handle = u3.U3())    
handle.configIO(EnableCounter0 = false, EnableCounter1 = false, NumberOfTimersEnabled = 0, FIOAnalog=EI1050_FIO_PIN_STATE)

# Setup EL-1050 probe
handle.getFeedback(u3.BitDirWrite(POWER_PIN_NUM, 1))
handle.getFeedback(u3.BitStateWrite(POWER_PIN_NUM, 1))

function poll_EL1050()
    ret = handle.sht1x(DATA_PIN_NUM, CLOCK_PIN_NUM, 0xc0)
    return (ret["Temperature"], ret["Humidity"])
end

function ball_valve(pos)
    if pos == true
        handle.getFeedback(u3.BitStateWrite(8, 0))
        handle.getFeedback(u3.BitStateWrite(9, 1))
    else
        handle.getFeedback(u3.BitStateWrite(8, 1))
        handle.getFeedback(u3.BitStateWrite(9, 0))
    end
end

function solenoid_valve(pos)
    if pos == true
        handle.getFeedback(u3.BitStateWrite(10, 0))
    else
        handle.getFeedback(u3.BitStateWrite(10, 1))
    end
end

function calibrate(val)
    solenoid_valve(val)
    ball_valve(~val)
end
        

