using PyCall

const u3 = pyimport("u3")
const U3HANDLE = u3.U3()

U3HANDLE.configIO(EnableCounter0 = false, EnableCounter1 = false, NumberOfTimersEnabled = 0, FIOAnalog = 0)

function valve(pos)
    if pos == :SMPS
        U3HANDLE.getFeedback(u3.BitStateWrite(8, 0))
        U3HANDLE.getFeedback(u3.BitStateWrite(9, 1))
    elseif pos == :HTDMA
        U3HANDLE.getFeedback(u3.BitStateWrite(8, 1))
        U3HANDLE.getFeedback(u3.BitStateWrite(9, 0))
    end
end
