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
using JLD2
using FileIO
using LabjackU6Library
using DifferentialMobilityAnalyzers
using TETechTC3625RS232
using GEOptiSonde


(@isdefined wnd) && destroy(wnd)      # Destroy window if exists
gui = GtkBuilder(filename = pwd() * "/htdma.glade")  # Load the GUI template
wnd = gui["mainWindow"]               # Set the main window

include("global_variables.jl")        # Reactive signals and global variables
include("gtk_callbacks.jl")           # Link GTK GUI fields with code
include("gtk_graphs.jl")              # Graph I/O on GTK backend
include("cpc_serial_io.jl")           # CPC I/O functions
include("polyscience_io.jl")          # Polyscience Bath I/O functions
include("labjack_io.jl")              # Labjack I/O functions
include("solenoid_io.jl")             # Labjack U3 solenoid I/O functions
include("initialize_hardware.jl")     # Hardware pointers to LJ and Serial Ports
include("set_gui_initial_state.jl")   # Initialze graphs and computed fields
include("daq_loops.jl")               # Data acquisistion functions
include("smps_signals.jl")            # Logic for SMPS controls (Julia I and II)

genericSwitch = Signal(true)

oneHz = fpswhen(genericSwitch, 1.0 / 2 * 1.0015272)       # 0.5  Hz time
tenHz = fpswhen(genericSwitch, 10.0 * 1.015272)         # 10 Hz time

globalState =
    map(_ -> get_gtk_property(gui["ManualStateSelection"], "active-id", String), oneHz)

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

smpsCounter, htdmaCounter = Signal(1), Signal(1)

stateReset = map(instrumentStateChanged) do _
    push!(elapsed_time, 0.0)
end

smpsRef = map(
    _ -> push!(smpsCounter, smpsCounter.value + 1),
    filter(s -> s[1] == "DONE", scan_state),
)
calRef = map(calibrate, CalibrationSwitch)


aCRef1 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),
    smpsCounter,
)
aCRef2 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),
    htdmaCounter,
)
#aCRef3 = map(_ -> push!(CalibrationSwitch, true), filter(s -> s == 6, htdma_diam_number))
#aCRef4 = map(_ -> push!(CalibrationSwitch, false), filter(s -> s != 6, htdma_diam_number))
#push!(CalibrationSwitch, false)

foo = every(30.0)
aCRef5 = map(_ -> push!(CalibrationSwitch, ~CalibrationSwitch.value), foo)

#signalV = map(v -> (v[2] / 1000.0, v[1] / 1000, false, false), V)
signalV = map(v -> (v[1] / 1000.0, v[2] / 1000, false, false), V)
labjack_signals = map(v -> labjackReadWrite(v[1], v[2], v[3], v[4]), signalV)
main_elapsed_time = foldp(+, 0.0, oneHz)

oneHzGenericLoop = map(_ -> (@async generic_loop()), oneHz)
oneHzInletLoop = map(_ -> (@async inlet()), htdma_scan_number)
tenHzSMPSLoop = map(_ -> (@async tenHz_daq_loop()), tenHz)
oneHzSMPSLoop = map(filter(s -> s == "SMPS", globalState)) do _
    @async oneHz_smps_loop()
end
oneHzHTDMALoop = map(filter(s -> s == "HTDMA", globalState)) do _
    @async oneHz_htdma_loop()
end

const newDay = map(droprepeats(datestr)) do x
    path3 = path * "Processed SMPS/" * datestr.value
    read(`mkdir -p $path3`)
    outfile = path3 * "/" * SizeDistribution_filename
    @save outfile SizeDistribution_df δ₁ˢᵐᵖˢ Λ₁ˢᵐᵖˢ inversionParameters
    try
        deleterows!(SizeDistribution_df, collect(1:length(SizeDistribution_df[:Timestamp])))
    catch
    end

    try
        deleterows!(inversionParameters, collect(1:length(inversionParameters[:Timestamp])))
    catch
    end
    path4 = path * "Processed HTDMA/" * datestr.value
    read(`mkdir -p $path4`)
    outfile = path4 * "/" * SizeDistribution_filename
    @save outfile HTDMA_df δ₁ˢᵐᵖˢ Λ₁ˢᵐᵖˢ δ₂ˢᵐᵖˢ Λ₂ˢᵐᵖˢ
    try
        deleterows!(HTDMA_df, collect(1:length(SizeDistribution_df[:Timestamp])))
    catch
    end
    global SizeDistribution_filename = Dates.format(now(), "yyyymmdd_HHMM") * ".jld2"
end

Gtk.showall(wnd)

set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),


:DONE
