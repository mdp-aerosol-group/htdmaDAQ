# + 
# Signals for SMPS control
# Setup scan logic and DAQ and Signals. 
# Generates Reactive signals and defines SMPS post-processing
# -

function smps_signals()
    function state(currentTime)
        holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
            scan_parameters(1)
        holdTime2, scanTime2, flushTime2, scanLength2, startVoltage2, endVoltage2, c2 =
            scan_parameters(2)

        scanStateSMPS1, scanStateSMPS2 = "NONE", "NONE"

        if globalState.value == "SMPS"
            scanStateSMPS1 = "DONE"
            scanStateSMPS2 = "NONE"
            (currentTime <= scanLength1) && (scanStateSMPS1 = "FLUSH")
            (currentTime < scanTime1 + holdTime1) && (scanStateSMPS1 = "SCAN")
            (currentTime <= holdTime1) && (scanStateSMPS1 = "HOLD")
        elseif globalState.value == "HTDMA"
            scanStateSMPS1 = "CLASSIFIER"
            scanStateSMPS2 = "DONE"
            (currentTime <= scanLength2) && (scanStateSMPS2 = "FLUSH")
            (currentTime < scanTime2 + holdTime2) && (scanStateSMPS2 = "SCAN")
            (currentTime <= holdTime2) && (scanStateSMPS2 = "HOLD")
        end

        return (scanStateSMPS1, scanStateSMPS2)
    end

    function smps_voltage(t)
        holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
            scan_parameters(1)
        holdTime2, scanTime2, flushTime2, scanLength2, startVoltage2, endVoltage2, c2 =
            scan_parameters(2)

        myV1, myV2 = 10.0, 10.0

        if globalState.value == "SMPS"
            ((scan_state.value[1] == "HOLD") && (t > 5)) && (myV1 = startVoltage1)
            (scan_state.value[1] == "SCAN") &&
                (myV1 = exp(log(startVoltage1) + c1 * (t - holdTime1)))
            (scan_state.value[1] == "FLUSH") && (myV1 = endVoltage1)
            (scan_state.value[1] == "DONE") && (myV1 = endVoltage1)
            myV2 = 10.0
        elseif globalState.value == "HTDMA"
            (scan_state.value[2] == "HOLD") && (myV2 = startVoltage2)
            (scan_state.value[2] == "SCAN") &&
                (myV2 = exp(log(startVoltage2) + c2 * (t - holdTime2)))
            (scan_state.value[2] == "FLUSH") && (myV2 = endVoltage2)
            (scan_state.value[2] == "DONE") && (myV2 = endVoltage2)
            myV1 =
                get_gtk_property(
                    gui["ClassifierVoltage$(htdma_diam_number.value)"],
                    :text,
                    String,
                ) |> x -> parse(Float64, x)
        end

        return (myV1, myV2)
    end

    function smps_scan_termination(s)
        a = pwd() |> x -> split(x, "/")
        path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
        try
            delete!(tenHz_df, 1)
        catch
        end

        if length(tenHz_df[!, :stateDMA1]) > 10
            tstr = Dates.format((tenHz_df[!, :Timestamp])[1], "yyyymmdd")
            path1 = path * "Raw 10 Hz SMPS/" * tstr
            read(`mkdir -p $path1`)
            outfile =
                path1 *
                "/" *
                Dates.format((tenHz_df[!, :Timestamp])[1], "yyyymmdd_HHMM") *
                ".csv"
            tenHz_df |> CSV.write(outfile)
            set_gtk_property!(gui["DataFile"], :text, outfile)

            push!(smps_scan_number, smps_scan_number.value += 1)   
		end

        delete!(tenHz_df, collect(1:length(tenHz_df[!, :Timestamp])))
    end

    function htdma_scan_termination(s)
        a = pwd() |> x -> split(x, "/")
        path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
        try
            delete!(tenHz_df, 1)
        catch
        end
        if length(tenHz_df[!, :stateDMA2]) > 10
            tstr = Dates.format((tenHz_df[!, :Timestamp])[1], "yyyymmdd")
            path1 = path * "Raw 10 Hz HTDMA/" * tstr
            read(`mkdir -p $path1`)
            outfile =
                path1 *
                "/" *
                Dates.format((tenHz_df[!, :Timestamp])[1], "yyyymmdd_HHMM") *
                ".csv"
            tenHz_df |> CSV.write(outfile)
            set_gtk_property!(gui["DataFile"], :text, outfile)
        end

        n = htdma_diam_number.value
        if (n >= 1) && (n <= 5) && (length(tenHz_df[!, :stateDMA2]) > 10)
            HTDMA_ts[n] = deepcopy((tenHz_df[!, :Timestamp])[1])
            HTDMA_tenHz[n] = deepcopy(tenHz_df)
        end

        n = 6
        current = (htdma_diam_number.value % n) + 1
        if htdma_diam_number.value >= n
            push!(htdma_diam_number, current)
            push!(htdmaCounter, htdmaCounter.value + 1)
            # Toggle to SMPS state here
            # set_gtk_property!(gui["ManualStateSelection"], "active-id", "SMPS")
        else
            push!(htdma_diam_number, current)
        end

        if (current == 1) && (length(tenHz_df[!, :stateDMA2]) > 2)
            global ℝ₂ = Array{SizeDistribution,1}(undef, 6)
            global HTDMA_ts = Array{DateTime,1}(undef, 6)
            global HTDMA_tenHz = Array{DataFrame,1}(undef, 6)
            global ℝᶜ = Array{Array{Float64,1}}(undef, 6)
            push!(htdma_scan_number, htdma_scan_number.value += 1)
        end

        MaxD = get_gtk_property(gui["DiameterMax$current"], :text, String)
        MinD = get_gtk_property(gui["DiameterMin$current"], :text, String)
        set_gtk_property!(gui["SMPS2StartDiameter"], :text, MaxD)
        set_gtk_property!(gui["SMPS2EndDiameter"], :text, MinD)
        set_voltage_SMPS("DiameterMax$current", "SMPS2StartVoltage", 2)
        set_voltage_SMPS("DiameterMin$current", "SMPS2EndVoltage", 2)

        delete!(tenHz_df, collect(1:length(tenHz_df[!, :Timestamp])))
    end

    function voltageToDiameters(V)
        Dp₁ = ztod(Λ₁ˢᵐᵖˢ, 1, vtoz(Λ₁ˢᵐᵖˢ, V[1]))
        Dp₂ = ztod(Λ₂ˢᵐᵖˢ, 1, vtoz(Λ₂ˢᵐᵖˢ, V[2]))
        (Dp₁, Dp₂)
    end

    function get_length()
        if globalState.value == "SMPS"
            holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
                scan_parameters(1)
        elseif globalState.value == "HTDMA"
            holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
                scan_parameters(2)
        else
            scanLength1 = 300
        end
        scanLength1
    end

    elapsed_time = foldp(+, 0.0, tenHz)
    scan_state = map(state, elapsed_time)
    smps_scan_number = Signal(1)
    htdma_scan_number = Signal(0)
    htdma_diam_number = Signal(0)
    V = map(smps_voltage, elapsed_time)
    Dp = map(voltageToDiameters, V)
    smps_termination = map(smps_scan_termination, filter(s -> s[1] == "DONE", scan_state))
    htdma_termination = map(htdma_scan_termination, filter(s -> s[2] == "DONE", scan_state))
    reset = map(s -> push!(elapsed_time, 0.0), filter(t -> t > get_length(), elapsed_time))
    
	return elapsed_time,
    scan_state,
    smps_scan_number,
    htdma_scan_number,
    htdma_diam_number,
    smps_termination,
    htdma_termination,
    reset,
    V,
    Dp
end

function scan_parameters(n)
    holdTime =
        get_gtk_property(gui["SMPS$(n)HoldTime"], :text, String) |> x -> parse(Float64, x)
    scanTime =
        get_gtk_property(gui["SMPS$(n)ScanTime"], :text, String) |> x -> parse(Float64, x)
    flushTime =
        get_gtk_property(gui["SMPS$(n)FlushTime"], :text, String) |> x -> parse(Float64, x)
    startVoltage =
        get_gtk_property(gui["SMPS$(n)StartVoltage"], :text, String) |>
        x -> parse(Float64, x)
    endVoltage =
        get_gtk_property(gui["SMPS$(n)EndVoltage"], :text, String) |> x -> parse(Float64, x)

    scanLength = holdTime + scanTime + flushTime
    c = log(endVoltage / startVoltage) / (scanTime)

    holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c
end
