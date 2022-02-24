# + 
# Signals for SMPS control
# Setup scan logic and DAQ and Signals. 
# Generates Reactive signals and defines SMPS post-processing
# -

function smps_signals()
    # Set SMPS states
    function state(currentTime)
        holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
            scan_parameters(1)
        holdTime2, scanTime2, flushTime2, scanLength2, startVoltage2, endVoltage2, c2 =
            scan_parameters(2)

        scanStateSMPS1, scanStateSMPS2 = "NONE", "NONE"
        # First DMA = SMPS, Second DMA = NONE
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

        (scanStateSMPS1, scanStateSMPS2)
    end

    # Set SMPS voltage
    function smps_voltage(t)
        holdTime1, scanTime1, flushTime1, scanLength1, startVoltage1, endVoltage1, c1 =
            scan_parameters(1)
        holdTime2, scanTime2, flushTime2, scanLength2, startVoltage2, endVoltage2, c2 =
            scan_parameters(2)

        myV1, myV2 = 10.0, 10.0
        # First DMA = SMPS, Second DMA = NONE
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

        (myV1, myV2)
    end

    # Determine cleanup procedure once scan is done
    function smps_scan_termination(s)
        a = pwd() |> x -> split(x, "/")                           # Output directory
        path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"          # Output directory
        try
            delete!(tenHz_df, 1)
        catch
        end             # Clear misc. "DONE" at start of file
        if length(tenHz_df[!,:stateDMA1]) > 10                      # Limit postprocessing to real scans
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

            path3 = path * "Processed SMPS/" * datestr.value
            read(`mkdir -p $path3`)
            outfile = path3 * "/" * SizeDistribution_filename

            # Query basic SMPS setup for storage
            t = parse_box("ThermoTemp", 22.0) + 273.15
            p = parse_box("ThermoPressure", 1001.0) * 100.0
            qsh = parse_box("SMPS1SheathFlow", 10.0) * lpm
            qsa = parse_box("SMPS1SampleFlow", 1.0) * lpm
            polarity = :-
            column = :TSI
            τᶜ = parse_box("SMPS1PlumbTime", 4.1)
            SMPSsetup = (t, p, qsh, qsa, polarity, column, τᶜ)
            useCounts = get_gtk_property(gui["SMPS1UseCounts"], :state, Bool)

            # Compute inversion and L-curve (see Petters (2018), Notebooks 5 and 6
            # λ₁ = parse_box("SMPS1LambdaLow", 0.05)
            # λ₂ = parse_box("SMPS1LambdaHigh", 0.05)
            bins = length(δ₁ˢᵐᵖˢ.Dp)
            eyeM = Matrix{Float64}(I, bins, bins)
            setupRegularization(δ₁ˢᵐᵖˢ.𝐀, eyeM, ℝ₁.N, inv(δ₁ˢᵐᵖˢ.𝐒) * ℝ₁.N, 1)
            # L1, L2, λs, ii = lcurve(λ₁, λ₂; n = 200)
            # if (ii > 5) && (ii < 195)
            #     converged = true
            #     λopt = lcorner(λ₁, λ₂; n = 10, r = 3)
            # else
            #     converged = false
            #     λopt = parse_box("SMPS1LambdaFallback", 0.05)
            # end
            N = clean((reginv(0.5, r = :Nλ))[1])
            𝕟 = SizeDistribution([], ℝ₁.De, ℝ₁.Dp, ℝ₁.ΔlnD, N ./ ℝ₁.ΔlnD, N, :regularized)

            # Plot the inverted data and L-curve
            addseries!(reverse(𝕟.Dp), reverse(𝕟.S), plot5, gplot5, 1, false, true)
            #addseries!(L1, L2, plot6, gplot6, 1, true, true)
            #addseries!([L1[ii], L1[ii]], [L2[ii], L2[ii]], plot6, gplot6, 2, true, true)

            # Write DataFrames for processed data
            push!(
                inversionParameters,
                Dict(
                    :Timestamp => Dates.format((tenHz_df[!, :Timestamp])[1], "HH:MM"),
                    :Ncpc => 1.0, #mean(oneHz_df[:N3cpcSerial]),
                    :N => sum(𝕟.N),
                    :A => sum(π / 4.0 .* (𝕟.Dp ./ 1000.0) .^ 2 .* 𝕟.N),
                    :V => sum(π / 6.0 .* (𝕟.Dp ./ 1000.0) .^ 3 .* 𝕟.N)
                    # :useCounts => useCounts,
                    # :converged => converged,
                    # :λopt => λopt,
                    # :λfb => 0.5,
                    # :L1 => Vector(L1),
                    # :L2 => Vector(L2),
                    # :λs => Vector(λs),
                    # :ii => ii,
                ),
            )

            # push!(
            #     SizeDistribution_df,
            #     Dict(
            #         :Timestamp => (tenHz_df[!, :Timestamp])[1],
            #         :useCounts => useCounts,
            #         :Response => deepcopy(ℝ₁),
            #         :Inverted => deepcopy(𝕟),
            #     ),
            # )

            # @save outfile SizeDistribution_df δ₁ˢᵐᵖˢ Λ₁ˢᵐᵖˢ SMPSsetup inversionParameters

            # Print summary data to textbox
            ix = size(inversionParameters, 1)
            ix = (ix < 15) ? ix : 15
            open("f.txt", "w") do io
                show(io, inversionParameters[end-ix+1:end, [1, 2, 3, 4, 5]])
            end
            put = open(
                f -> set_gtk_property!(gui["textbuffer1"], :text, read(f, String)),
                "f.txt",
            )

            push!(smps_scan_number, smps_scan_number.value += 1)    # New scan
            if smps_scan_number.value >= 2
                #set_gtk_property!(gui["ManualStateSelection"], "active-id", "HTDMA")
            end
        end

        # reset response function and clear 1Hz and 10Hz DataFrames
        N = zeros(length(δ₁ˢᵐᵖˢ.Dp))
        global ℝ₁ =
            SizeDistribution([[]], δ₁ˢᵐᵖˢ.De, δ₁ˢᵐᵖˢ.Dp, δ₁ˢᵐᵖˢ.ΔlnD, N, N, :response)
        delete!(tenHz_df, collect(1:length(tenHz_df[!, :Timestamp])))
    end

    function htdma_scan_termination(s)
        a = pwd() |> x -> split(x, "/")                           # Output directory
        path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"          # Output directory
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

        n = 6    # Number of diameters
        current = (htdma_diam_number.value % n) + 1
        if htdma_diam_number.value >= n
            push!(htdma_diam_number, current)
            push!(htdmaCounter, htdmaCounter.value + 1)
        else
            push!(htdma_diam_number, current)
        end

        if (current == 1) && (length(tenHz_df[!, :stateDMA2]) > 2)
            path3 = path * "Processed HTDMA/" * datestr.value
            read(`mkdir -p $path3`)
            outfile = path3 * "/" * SizeDistribution_filename

            # Query basic SMPS setup for storage
            t = parse_box("ThermoTemp", 22.0) + 273.15
            p = parse_box("ThermoPressure", 1001.0) * 100.0
            qsh1 = parse_box("SMPS1SheathFlow", 10.0) * lpm
            qsa1 = parse_box("SMPS1SampleFlow", 1.0) * lpm
            qsh2 = parse_box("SMPS2SheathFlow", 10.0) * lpm
            qsa2 = parse_box("SMPS2SampleFlow", 1.0) * lpm
            τᶜ1 = parse_box("SMPS1PlumbTime", 4.1)
            τᶜ2 = parse_box("SMPS2PlumbTime", 4.1)
            SMPSsetup = (t, p, qsh1, qsa1, qsh2, qsa2, τᶜ1, τᶜ2)

            @save outfile δ₁ˢᵐᵖˢ Λ₁ˢᵐᵖˢ δ₂ˢᵐᵖˢ Λ₂ˢᵐᵖˢ SMPSsetup
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

        delete!(tenHz_df, collect(1:length(tenHz_df[!,:Timestamp])))
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

    # Generate signals and connect with functions
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
    elapsed_time,
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

# Read scan settings from GUI
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

    # Compute scan lengh and voltage slope
    scanLength = holdTime + scanTime + flushTime
    c = log(endVoltage / startVoltage) / (scanTime)

    holdTime, scanTime, flushTime, scanLength, startVoltage, endVoltage, c
end
