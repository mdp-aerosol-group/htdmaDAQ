using PyCall

const EI1050_FIO_PIN_STATE = 0 
const SDAP = 2
const SCLP = 3
const DATA_PIN_NUM = 6
const CLOCK_PIN_NUM = 7
const POWER_PIN_NUM = 5


function poll_EL1050()
    return (20.0, 50.0)
end

function ball_valve(pos)
end

function solenoid_valve(pos)
end

function calibrate(val)
end
        
