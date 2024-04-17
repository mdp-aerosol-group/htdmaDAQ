# POPS DAQ Logic

include("PrintedOpticalParticleSpectrometer.jl")

const bp = "/home/aerosol/Data/"      # Base path for data saving
const portName = "/dev/ttyUSB0"       # Serial port name for POPS
const nbins = get_gtk_property(gui["nbins"], :text, String) |> x -> parse(Int, x)
const logmin = get_gtk_property(gui["logmin"], :text, String) |> x -> parse(Float64, x)
const logmax = get_gtk_property(gui["logmax"], :text, String) |> x -> parse(Float64, x)
const BUFFLEN = 1000
const BUFFAV = 300

function channel(ph)
    logdelta = (logmax - logmin) / nbins
    return (log10(ph) - logmin) / logdelta |> floor |> Int
end

function ph(i)
    logdelta = (logmax - logmin) / nbins
    return Int.(round.(exp10(i * logdelta + logmin), digits = 0))
end

function calibrate(ph)
    df = CSV.read("phcalibration.csv", DataFrame)
    nitp = interpolate((df[!, :Dp],), df[!, :ph], Gridded(Linear()))
    Ds = 110:1:6990
    Dp = map(x -> Ds[argmin((nitp.(Ds) .- x) .^ 2)], ph)
    return Dp
end

const digitizerPH = ph.(1:nbins)
const Dps = calibrate(digitizerPH)
const portPOPS = PrintedOpticalParticleSpectrometer.config(portName)
@async PrintedOpticalParticleSpectrometer.stream(portPOPS, bp * "pops/pops")

function get_packet()
    pops = PrintedOpticalParticleSpectrometer.get_current_record()
    tc = Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    mapfoldl(x -> string(x) * ";", *, [tc, pops])[1:end-1]
end

const dataBufferdt = CircularBuffer{DateTime}(BUFFLEN)
const dataBufferQ = CircularBuffer{Float64}(BUFFLEN)
const dataBufferRH = CircularBuffer{Float64}(BUFFLEN)
const dataBufferN = CircularBuffer{Float64}(BUFFLEN)
const dataBufferCounts = CircularBuffer{Vector{Float64}}(BUFFAV)
const dataBufferPSD = CircularBuffer{Vector{Float64}}(BUFFAV)

for i = 1:BUFFLEN
    t = now()
    push!(dataBufferdt, t)
    push!(dataBufferQ, 0.0)
    push!(dataBufferN, 0.0)
    push!(dataBufferRH, 0.0)
end

for i = 1:BUFFAV
    push!(dataBufferCounts, zeros(nbins))
    push!(dataBufferPSD, zeros(nbins))
end

extract(x, i) = @chain split(x, ",") getindex(_, i) parse.(Float64, _)

function acquire()
    x = get_packet()
    filter(x -> x != '\r', x)
    tc = Dates.format(now(), "yyyymmdd")
    open(bp * "pops" * "_" * tc * ".txt", "a") do io
        return write(io, x)
    end
end

function accumulate()
    x = get_packet()
    a = split(x, ";")
    t = DateTime(a[1])

    Q = try
        extract(a[2], 8) * 60.0 ./ 1000.0
    catch
        0.0
    end

    N = try
        b = split(a[2], "\r")
        c = split(b[1], ",")
        psd = extract(b[1], 12:length(c))
        N = sum(psd) ./ (Q .* 1000.0 ./ 60.0)
    catch
        0.0
    end

    psd = try
        b = split(a[2], "\r")
        c = split(b[1], ",")
        psd = extract(b[1], 12:length(c))
    catch
        zeros(nbins)
    end
    dlnD = log.(Dps[2:end] ./ Dps[1:end-1])
    dlnD = [dlnD; dlnD[end]]
    push!(dataBufferdt, t)
    push!(dataBufferQ, Q)
    push!(dataBufferN, N)
    push!(dataBufferCounts, psd)
    push!(dataBufferPSD, psd ./ Q ./ dlnD)
end
