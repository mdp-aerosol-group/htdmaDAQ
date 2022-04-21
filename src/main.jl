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
using DifferentialMobilityAnalyzers
using TETechTC3625RS232
import NumericIO:UEXPONENT

(@isdefined wnd) && destroy(wnd)      # Destroy window if exists
gui = GtkBuilder(filename = pwd() * "/htdma.glade")  # Load the GUI template
wnd = gui["mainWindow"]               # Set the main window

include("global_variables.jl")        # Reactive signals and global variables
include("gtk_callbacks.jl")           # Link GTK GUI fields with code
include("te_io.jl")                   # Thermoelectric Signals (wavefrom)
include("gtk_graphs.jl")              # Graph I/O on GTK backend
include("cpc_serial_io.jl")           # CPC I/O functions
# include("labjack_io.jl")            # Labjack I/O functions
include("initialize_hardware.jl")     # Hardware pointers to LJ and Serial Ports
include("set_gui_initial_state.jl")   # Initialze graphs and computed fields
include("daq_loops.jl")               # Data acquisistion functions
include("smps_signals.jl")            # Logic for SMPS controls (Julia I and II)

oneHz = fps(1.0  * 1.0015272)        # 1  Hz time
tenHz = fps(10.0 * 1.015272)         # 10 Hz time

TE1_elapsed_time = foldp(+, 0.0, oneHz)   
TE1setT, TE1reset = TE1_signals()           

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

aCRef1 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA"),
    smpsCounter,
)
aCRef2 = map(
    _ -> set_gtk_property!(gui["ManualStateSelection"], "active-id", "SMPS"),
    htdmaCounter,
)

signalV = map(v -> (v[1] / 1000.0, v[2] / 1000, false, false), V)
#labjack_signals = map(v -> labjackReadWrite(v[1], v[2], v[3], v[4]), signalV)
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

Gtk.showall(wnd)
set_gtk_property!(gui["ManualStateSelection"], "active-id", "SMPS"),

Dds = [40, 50, 60, 70, 80, 90, 100]*1.0
map(set_dry_diameter, Dds, 1:6)

:DONE
