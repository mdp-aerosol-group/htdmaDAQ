using Gtk
using InspectDR
using Reactive
using Colors
using DataFrames
using Dates
using LibSerialPort
using Interpolations
using Statistics
using LambertW
using LinearAlgebra
using Printf
using CSV
using FileIO
using DataStructures
using Chain

using DifferentialMobilityAnalyzers
using TETechTC3625RS232
using LabjackU6Library
using RegularizationTools
import NumericIO: UEXPONENT
using CondensationParticleCounters


(@isdefined wnd) && destroy(wnd)      # Destroy window if exists
gui = GtkBuilder(filename = pwd() * "/htdma.glade")  # Load the GUI template
wnd = gui["mainWindow"]               # Set the main window

include("global_variables.jl")        # Reactive signals and global variables
include("gtk_callbacks.jl")           # Link GTK GUI fields with code
include("hv_io.jl")                   # Ultravolt calibration
include("te_io.jl")                   # Thermoelectric Signals (wavefrom)
include("gtk_graphs.jl")              # Graph I/O on GTK backend
include("labjack_io.jl")              # Labjack I/O functions
include("initialize_hardware.jl")     # Hardware pointers to LJ and Serial Ports
include("set_gui_initial_state.jl")   # Initialze graphs and computed fields
include("daq_loops.jl")               # Data acquisistion functions
include("smps_signals.jl")            # Logic for SMPS controls (Julia I and II)

oneHz = fps(1.0 * 1.0015272)          # 1  Hz time
tenHz = fps(10.0 * 1.015272)          # 10 Hz time

sleep(15)

TE1_elapsed_time = foldp(+, 0.0, oneHz)
TE1setT, TE1reset = TE1_signals()

globalState =
    map(_ -> get_gtk_property(gui["ManualStateSelection"], "active-id", String), oneHz)

smpsCounter, htdmaCounter = Signal(1), Signal(1)

elapsed_time,
scan_state,
smps_scan_number,
htdma_scan_number,
htdma_diam_number,
smps_termination,
htdma_termination,
reset,
V,
Dp = smps_signals()


stateReset = map(instrumentStateChanged) do _
    push!(elapsed_time, 0.0)
end

sleep(2)

smpsRef = map(
    _ -> push!(smpsCounter, smpsCounter.value + 1),
    filter(s -> s[1] == "DONE", scan_state),
)

aCRef1 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),
    smpsCounter,
)

aCRef2 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),
    htdmaCounter,
)

aCRef3 = map(_ -> set_gtk_property!(gui["TE1Mode"], "active-id", "Ramp"), smpsCounter)

maxl() = get_gtk_property(gui["duration1"], :value, Float64) * 60.0
acRef4 = map(filter(s -> s > maxl(), TE1_elapsed_time)) do _
    if globalState.value .== "HTDMA"
        set_gtk_property!(gui["TE1Mode"], "active-id", "Manual")
        push!(TE1_elapsed_time, 0.0)
        delete!(tenHz_df, collect(1:length(tenHz_df[!, :Timestamp])))
        set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA")
    end
end

sleep(10)
calvdac(v) =  99.89032641516044  + 0.9409502590503874 * v
calvdac(100.0)
sleep(1)
signalV = map(v -> [v[1]/1000, getVdac(calvdac(v[2]), :-, true)], V)
sleep(1)
labjack_signals = map(v -> labjackReadWrite(v[2], v[2], true, true), signalV)
sleep(1)
labjack_signals1 = map(v -> labjackReadWrite(v[1], v[1], true, true;
    HANDLE = HANDLE1, caliInfo = caliInfo1, caliInfoTdac = caliInfoTdac1),
    signalV)
main_elapsed_time = foldp(+, 0.0, oneHz)

oneHzGenericLoop = map(_ -> (@async generic_loop()), oneHz)

sleep(5)
tenHzSMPSLoop = map(_ -> (@async tenHz_daq_loop()), tenHz)
sleep(5)
oneHzSMPSLoop = map(filter(s -> s == "SMPS", globalState)) do _
    @async oneHz_smps_loop()
end
sleep(8)
oneHzHTDMALoop = map(filter(s -> s == "HTDMA", globalState)) do _
    @async oneHz_htdma_loop()
end


# POPS acquisition loops
# const daqLoop = map(_ -> acquire(), oneHz)
# sleep(6)
# const accLoop = map(_ -> accumulate(), oneHz)
const inletLoop = map(_ -> inlet(), oneHz)


Gtk.showall(wnd)
set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA")

Dds = [20, 20, 20, 20, 20, 20, 20] * 1.0
Dds = ones(6) .* 70.0
map(set_dry_diameter, Dds, 1:6)
map(set_dry_diameter, Dds, 1:6)
sleep(1)
TETechTC3625RS232.write_heat_multiplier(portTE1, 1.0)
sleep(1)
TETechTC3625RS232.write_cool_multiplier(portTE1, 1.0)

:DONE
