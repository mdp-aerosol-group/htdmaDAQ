const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const mblue = RGBA(0, 0, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const bufferlength = 400
const datestr = Reactive.Signal(Dates.format(now(), "yyyymmdd"))

a = pwd() |> x -> split(x, "/")
global path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/Raw 10 Hz/"
global outfile = path * Dates.format(now(), "yyyymmdd_HHMM") * ".csv"
global TEsetT = Reactive.Signal(22.0)
global instrumentStateChanged = Reactive.Signal(0)
global CalibrationSwitch = Reactive.Signal(false)
global cFluxRH = Reactive.Signal(30.0)

# 10Hz data file
global tenHz_df = DataFrame(
    Timestamp = DateTime[],
    Unixtime = Float64[],
    Int64time = Int64[],
    LapseTime = String[],
    stateDMA1 = Symbol[],
    voltageSetDMA1 = Float64[],
    currentDiameterDMA1 = Float64[],
    stateDMA2 = Symbol[],
    voltageSetDMA2 = Float64[],
    currentDiameterDMA2 = Float64[],
    RH1 = Float64[],
    RH2 = Float64[],
    RH3 = Float64[],
    RH4 = Float64[],
    T1 = Float64[],
    T2 = Float64[],
    T3 = Float64[],
    T4 = Float64[],
    TESet = Float64[],
    TE1ReadT1 = Float64[],
    TE1ReadT2 = Float64[],
    TE2ReadT1 = Float64[],
    TE2ReadT2 = Float64[],
    Tdsh2 = Float64[],
    Tdsa2 = Float64[],
    InletTd = Float64[],
    ColumnAverageT = Float64[],
    ColumnAverageTd = Float64[],
    BathSetT = Float64[],
    BathReadT1 = Float64[],
    N1cpcCount = Float64[],
    N2cpcCount = Float64[],
    N1cpcSerial = Union{Float64,Missing}[],
    N2cpcSerial = Union{Float64,Missing}[],
    Calibrate = Bool[]
)



global SizeDistribution_df = DataFrame(
    Timestamp = DateTime[],
    useCounts = Bool[],
    Response = SizeDistribution[],
    Inverted = SizeDistribution[],
)


global HTDMA_df = DataFrame(
    Timestamp = Array{DateTime}[],
    useCounts = [],
    Response = Array{SizeDistribution,1}[],
    CPC1 = Array{Array{Union{Float64,Missing},1}}[],
)


global inversionParameters = DataFrame(
    Timestamp = String[],
    Ncpc = Union{Float64,Missing}[],
    N = Float64[],
    A = Float64[],
    V = Float64[],
    # useCounts = Bool[],
    # converged = Bool[],
    # λopt = Float64[],
    # λfb = Float64[],
    # L1 = Vector[],
    # L2 = Vector[],
    # λs = Vector[],
    # ii = Int[],
)

global SizeDistribution_filename = Dates.format(now(), "yyyymmdd_HHMM") * ".jld2"

global ℝ₁ = SizeDistribution
global ℝ₂ = Array{SizeDistribution,1}(undef, 6)
global ℝᶜ = Array{Array{Union{Float64,Missing},1}}(undef, 6)
global HTDMA_ts = Array{DateTime,1}(undef, 6)
global HTDMA_tenHz = Array{DataFrame,1}(undef, 6)
global HTDMA_oneHz = Array{DataFrame,1}(undef, 6)
