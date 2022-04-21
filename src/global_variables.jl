const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const mblue = RGBA(0, 0, 0.8, 1)
const mgrey = RGBA(0.4, 0.4, 0.4, 1)
const lpm = 1.666666e-5
const bufferlength = 400
const datestr = Reactive.Signal(Dates.format(now(), "yyyymmdd"))

a = pwd() |> x -> split(x, "/")
const path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/Raw 10 Hz/"
const outfile = path * Dates.format(now(), "yyyymmdd_HHMM") * ".csv"
const TEsetT = Reactive.Signal(22.0)
const instrumentStateChanged = Reactive.Signal(0)
const rampTE1 = Reactive.Signal(false)
const stateTE1 = Reactive.Signal(:Manual)

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
    TESet = Float64[],
    TE1ReadT1 = Float64[],
    TE1ReadT2 = Float64[],
    N1cpcCount = Float64[],
    N2cpcCount = Float64[],
    N1cpcSerial = Union{Float64,Missing}[],
    N2cpcSerial = Union{Float64,Missing}[],
)

global HTDMA_df = DataFrame(
    Timestamp = Array{DateTime}[],
    useCounts = [],
    Response = Array{SizeDistribution,1}[],
    CPC1 = Array{Array{Union{Float64,Missing},1}}[],
)

global ℝ₁ = SizeDistribution
global ℝ₂ = Array{SizeDistribution,1}(undef, 6)
global ℝᶜ = Array{Array{Union{Float64,Missing},1}}(undef, 6)
global HTDMA_ts = Array{DateTime,1}(undef, 6)
global HTDMA_tenHz = Array{DataFrame,1}(undef, 6)
global HTDMA_oneHz = Array{DataFrame,1}(undef, 6)
