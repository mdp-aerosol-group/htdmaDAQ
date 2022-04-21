# +
#
# set_SMPS1_config() -- configure SMPS1 
# set_SMPS2_config() -- configure SMPS2

function setCalibrationSwitch(widget::Gtk.GtkSwitchLeaf, state::Bool)
	push!(CalibrationSwitch, state)
end

# if diameter changes then Recompute Voltage
function SMPS1startDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("SMPS1StartDiameter", "SMPS1StartVoltage", 1)
end

function SMPS1endDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("SMPS1EndDiameter", "SMPS1EndVoltage", 1)
end

function SMPS2startDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("SMPS2StartDiameter", "SMPS2StartVoltage", 2)
end

function SMPS2endDiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("SMPS2EndDiameter", "SMPS2EndVoltage", 2)
end

function Min1DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin1", "VoltageMin1", 2)      # Map Diameter to Voltage
end

function Min2DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin2", "VoltageMin2", 2)      # Map Diameter to Voltage
end

function Min3DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin3", "VoltageMin3", 2)      # Map Diameter to Voltage
end
	
function Min4DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin4", "VoltageMin4", 2)      # Map Diameter to Voltage
end
	
function Min5DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin5", "VoltageMin5", 2)      # Map Diameter to Voltage
end

function Min6DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMin6", "VoltageMin6", 2)      # Map Diameter to Voltage
end

function Max1DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax1", "VoltageMax1", 2)      # Map Diameter to Voltage
end

function Max2DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax2", "VoltageMax2", 2)      # Map Diameter to Voltage
end

function Max3DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax3", "VoltageMax3", 2)      # Map Diameter to Voltage
end

function Max4DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax4", "VoltageMax4", 2)      # Map Diameter to Voltage
end

function Max5DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax5", "VoltageMax5", 2)      # Map Diameter to Voltage
end

function Max6DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("DiameterMax6", "VoltageMax6", 2)      # Map Diameter to Voltage
end

function Classifier1DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter1", "ClassifierVoltage1", 1)      # Map Diameter to Voltage
end

function Classifier2DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter2", "ClassifierVoltage2", 1)      # Map Diameter to Voltage
end

function Classifier3DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter3", "ClassifierVoltage3", 1)      # Map Diameter to Voltage
end

function Classifier4DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter4", "ClassifierVoltage4", 1)      # Map Diameter to Voltage
end

function Classifier5DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter5", "ClassifierVoltage5", 1)      # Map Diameter to Voltage
end

function Classifier6DiameterChanged(widget::GtkEntryLeaf, EventAny::Gtk.GdkEventAny)
	set_voltage_SMPS("Diameter6", "ClassifierVoltage6", 1)      # Map Diameter to Voltage
end

sbox = gui["ManualStateSelection"]
signal_connect(sbox, "changed") do widget, others...
	v = get_gtk_property(sbox, :active_id, String) 
	push!(instrumentStateChanged,instrumentStateChanged.value+1)
end
id2 = signal_connect(SMPS1startDiameterChanged, gui["SMPS1StartDiameter"], "focus-out-event")
id3 = signal_connect(SMPS1endDiameterChanged, gui["SMPS1EndDiameter"], "focus-out-event")
id4 = signal_connect(SMPS2startDiameterChanged, gui["SMPS2StartDiameter"], "focus-out-event")
id5 = signal_connect(SMPS2endDiameterChanged, gui["SMPS2EndDiameter"], "focus-out-event")
id6 = signal_connect(Min1DiameterChanged, gui["DiameterMin1"], "focus-out-event")
id7 = signal_connect(Min2DiameterChanged, gui["DiameterMin2"], "focus-out-event")
id8 = signal_connect(Min3DiameterChanged, gui["DiameterMin3"], "focus-out-event")
id9 = signal_connect(Min4DiameterChanged, gui["DiameterMin4"], "focus-out-event")
id10 = signal_connect(Min5DiameterChanged, gui["DiameterMin5"], "focus-out-event")
id11 = signal_connect(Min6DiameterChanged, gui["DiameterMin6"], "focus-out-event")
id12 = signal_connect(Max1DiameterChanged, gui["DiameterMax1"], "focus-out-event")
id13 = signal_connect(Max2DiameterChanged, gui["DiameterMax2"], "focus-out-event")
id14 = signal_connect(Max3DiameterChanged, gui["DiameterMax3"], "focus-out-event")
id15 = signal_connect(Max4DiameterChanged, gui["DiameterMax4"], "focus-out-event")
id16 = signal_connect(Max5DiameterChanged, gui["DiameterMax5"], "focus-out-event")
id17 = signal_connect(Max6DiameterChanged, gui["DiameterMax6"], "focus-out-event")
id18 = signal_connect(Classifier1DiameterChanged, gui["Diameter1"], "focus-out-event")
id19 = signal_connect(Classifier2DiameterChanged, gui["Diameter2"], "focus-out-event")
id20 = signal_connect(Classifier3DiameterChanged, gui["Diameter3"], "focus-out-event")
id21 = signal_connect(Classifier4DiameterChanged, gui["Diameter4"], "focus-out-event")
id22 = signal_connect(Classifier5DiameterChanged, gui["Diameter5"], "focus-out-event")
id23 = signal_connect(Classifier6DiameterChanged, gui["Diameter6"], "focus-out-event")

function set_voltage_SMPS(source::String, destination::String, SMPS::Int)
	Λˢᵐᵖˢ = (SMPS == 1) ? Λ₁ˢᵐᵖˢ : Λ₂ˢᵐᵖˢ
	D = parse_box(source, 100.0)
	(D == 100.0) && set_gtk_property!(gui[source], :text, "100")
	V = ztov(Λˢᵐᵖˢ,dtoz(Λˢᵐᵖˢ,D*1e-9))
	if V > 10000.0
		V = 10000.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10000.0))
		set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
	elseif V < 10.0
		V = 10.0
		D = ztod(Λˢᵐᵖˢ,1,vtoz(Λˢᵐᵖˢ,10.0))
		set_gtk_property!(gui[source], :text, @sprintf("%0.0f", D))
	end
	set_gtk_property!(gui[destination], :text, @sprintf("%0.0f", V))
end

function get_DMA_dimensions(column)
    (column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    (column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (column == :RDMA) && ((r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    (column == :HELSINKI) && ((r₁, r₂, l) = (2.65e-2, 3.3e-2, 10.9e-2))
    (column == :VIENNA) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    form = (column == :RDMA) ? :radial : :cylindrical
	return r₁, r₂, l, form 
end

function set_SMPS1_config()
	t = parse_box("ThermoTemp", 22.0)+273.15
	p = parse_box("ThermoPressure", 1001.0)*100.0
	qsh = parse_box("SMPS1SheathFlow", 10.0)*lpm
	qsa = parse_box("SMPS1SampleFlow", 1.0)*lpm
	leff = parse_box("SMPS1EffectiveLength", 4.1)
	bins = parse_box("SMPS1NumberOfBins", 120)
	polarity = :-
	m = 6

	r₁, r₂, l, form = get_DMA_dimensions(:TSI) 
	global Λ₁ˢᵐᵖˢ = DMAconfig(t,p,qsa,qsh,r₁,r₂,l,leff,polarity,m,form) 
	v₁,v₂ = 10,10000      
	z₁,z₂ = vtoz(Λ₁ˢᵐᵖˢ,v₂), vtoz(Λ₁ˢᵐᵖˢ,v₁)
	global δ₁ˢᵐᵖˢ = setupDMA(Λ₁ˢᵐᵖˢ, z₁, z₂, bins)
	N = zeros(length(δ₁ˢᵐᵖˢ.Dp))
	global ℝ₁ = SizeDistribution([[]],δ₁ˢᵐᵖˢ.De,δ₁ˢᵐᵖˢ.Dp,δ₁ˢᵐᵖˢ.ΔlnD,N,N,:response)
end

function set_SMPS2_config()
	t = parse_box("ThermoTemp", 22.0)+273.15
	p = parse_box("ThermoPressure", 1001.0)*100.0
	qsh = parse_box("SMPS2SheathFlow", 10.0)*lpm
	qsa = parse_box("SMPS2SampleFlow", 1.0)*lpm
	leff = parse_box("SMPS2EffectiveLength", 4.1)
	bins = parse_box("SMPS2NumberOfBins", 120)
	polarity = :-
	m = 6

	r₁, r₂, l, form = get_DMA_dimensions(:HELSINKI) 
	global Λ₂ˢᵐᵖˢ = DMAconfig(t,p,qsa,qsh,r₁,r₂,l,leff,polarity,m,form) 
	v₁,v₂ = 10,10000      
	z₁,z₂ = vtoz(Λ₂ˢᵐᵖˢ,v₂), vtoz(Λ₂ˢᵐᵖˢ,v₁)
	global δ₂ˢᵐᵖˢ = setupDMA(Λ₁ˢᵐᵖˢ, z₁, z₂, bins)
	N = zeros(length(δ₂ˢᵐᵖˢ.Dp))
end


# parse_box functions read a text box and returns the formatted result
function parse_box(s::String, default::Float64)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = default end
end

function parse_box(s::String, default::Int)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Int,x) catch; y = default end
end

function parse_box(s::String, default::Missing)
	x = get_gtk_property(gui[s], :text, String)
	y = try parse(Float64,x) catch; y = missing end
end

function parse_box(s::String)
	x = get_gtk_property(gui[s], :active_id, String)
	y = Symbol(x)
end


set_SMPS1_config()    # Compute DMA functions for SMPS1
set_SMPS2_config()    # Compute DMA functions for SMPS2
set_voltage_SMPS("SMPS1StartDiameter", "SMPS1StartVoltage", 1)  # Map Diameter to Voltage
set_voltage_SMPS("SMPS1EndDiameter", "SMPS1EndVoltage", 1)      # Map Diameter to Voltage
set_voltage_SMPS("SMPS2StartDiameter", "SMPS2StartVoltage", 2)  # Map Diameter to Voltage
set_voltage_SMPS("SMPS2EndDiameter", "SMPS2EndVoltage", 2)      # Map Diameter to Voltage

set_voltage_SMPS("DiameterMin1", "VoltageMin1", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMin2", "VoltageMin2", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMin3", "VoltageMin3", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMin4", "VoltageMin4", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMin5", "VoltageMin5", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMin6", "VoltageMin6", 2)      # Map Diameter to Voltage

set_voltage_SMPS("DiameterMax1", "VoltageMax1", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMax2", "VoltageMax2", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMax3", "VoltageMax3", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMax4", "VoltageMax4", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMax5", "VoltageMax5", 2)      # Map Diameter to Voltage
set_voltage_SMPS("DiameterMax6", "VoltageMax6", 2)      # Map Diameter to Voltage

set_voltage_SMPS("Diameter1", "ClassifierVoltage1", 1)      # Map Diameter to Voltage
set_voltage_SMPS("Diameter2", "ClassifierVoltage2", 1)      # Map Diameter to Voltage
set_voltage_SMPS("Diameter3", "ClassifierVoltage3", 1)      # Map Diameter to Voltage
set_voltage_SMPS("Diameter4", "ClassifierVoltage4", 1)      # Map Diameter to Voltage
set_voltage_SMPS("Diameter5", "ClassifierVoltage5", 1)      # Map Diameter to Voltage
set_voltage_SMPS("Diameter6", "ClassifierVoltage6", 1)      # Map Diameter to Voltage

te1Mode = gui["TE1Mode"]
signal_connect(te1Mode, "changed") do widget, others...
	push!(stateTE1,get_gtk_property(te1Mode, "active-id", String) |> Symbol)	
end

updatePower = Signal(false)
te1Power = gui["power"]
signal_connect(te1Power, "state-set") do widget, others...
    push!(updatePower, true)
end

updateBandwidth = Signal(false)
te1Proportional = gui["proportional"]
signal_connect(te1Proportional, "changed") do widget, others...
    push!(updateBandwidth, true)
end

updateIntegral = Signal(false)
te1Integral = gui["integral"]
signal_connect(te1Integral, "changed") do widget, others...
    push!(updateIntegral, true)
end

updateDerivative = Signal(false)
te1Derivative = gui["derivative"]
signal_connect(te1Derivative, "changed") do widget, others...
    push!(updateDerivative, true)
end

updateThermistor = Signal(false)
te1Thermistor = gui["thermistor"]
signal_connect(te1Thermistor, "changed") do widget, others...
    push!(updateThermistor, true)
end

updatePolarity = Signal(false)
te1Polarity = gui["polarity"]
signal_connect(te1Polarity, "changed") do widget, others...
    push!(updatePolarity, true)
end

function set_dry_diameter(Dd, n)
    set_gtk_property!(gui["Diameter$n"], :text, @sprintf("%.1f", Dd))
    set_gtk_property!(gui["DiameterMin$n"], :text, @sprintf("%.1f", 0.3*Dd))
    set_gtk_property!(gui["DiameterMax$n"], :text, @sprintf("%.1f", 1.5*Dd))
	set_voltage_SMPS("DiameterMin$n", "VoltageMin$n", 2)   
	set_voltage_SMPS("DiameterMax$n", "VoltageMax$n", 2)  
	set_voltage_SMPS("Diameter$n", "ClassifierVoltage$n", 1)     
end


