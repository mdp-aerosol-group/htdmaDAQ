function tenHz_daq_loop()
    # - 
    # Logic and setup for Julia 1 10 Hz SMPS Loop
    # This function executes @10 Hz during SMPS state
    # It provides Labjack DAQ, populates GUI Texbox, and generates a 10 Hz data file
    # -
    AIN, Tk, rawcount, count = labjack_signals.value # Unpack signals

    N1cpcCount = count[1] / tenHz.value / (flowRate1 * 16.6666666)   # Compute concentration
    N2cpcCount = count[2] / tenHz.value / (flowRate2 * 16.6666666)   # Compute concentration

    # Dump to GUI
    set_gtk_property!(gui["Ncounts1"], :text, @sprintf("%0.1f", N1cpcCount))
    set_gtk_property!(gui["Ncounts2"], :text, @sprintf("%0.1f", N2cpcCount))

    # Convert AIN signal to RH,T,P for channels AIN0 and AIN1
    RH1, T1, Td1 = AIN2HC(AIN, 5, 6)
    set_gtk_property!(gui["RHsh1"], :text, @sprintf("%0.1f", RH1))
    set_gtk_property!(gui["Tsh1"], :text, @sprintf("%0.1f", T1))
    set_gtk_property!(gui["Tdsh1"], :text, @sprintf("%0.1f", Td1))

    # Convert AIN signal to RH,T,P for channels AIN2 and AIN3
    RH2, T2, Td2 = AIN2HC(AIN, 3, 4)
    set_gtk_property!(gui["RHsa1"], :text, @sprintf("%0.1f", RH2))
    set_gtk_property!(gui["Tsa1"], :text, @sprintf("%0.1f", T2))
    set_gtk_property!(gui["Tdsa1"], :text, @sprintf("%0.1f", Td2))

    # Convert AIN signal to RH,T,P for channels AIN4 and AIN5
    RH3, T3, Td3 = AIN2HC(AIN, 1, 2)
    set_gtk_property!(gui["RHsh2"], :text, @sprintf("%0.1f", RH3))
    set_gtk_property!(gui["Tsh2"], :text, @sprintf("%0.1f", T3))
    set_gtk_property!(gui["Tdsh2"], :text, @sprintf("%0.1f", Td3))

    # Convert AIN signal to RH,T,P for channels AIN6 and AIN7
    RH4, T4, Td4 = AIN2HC(AIN, 7, 8)
    set_gtk_property!(gui["RHsa2"], :text, @sprintf("%0.1f", RH4))
    set_gtk_property!(gui["Tsa2"], :text, @sprintf("%0.1f", T4))
    set_gtk_property!(gui["Tdsa2"], :text, @sprintf("%0.1f", Td4))

    # Write signals to GUI
    set_gtk_property!(gui["SMPS1ScanCount"], :text, @sprintf("%.1f", elapsed_time.value))
    set_gtk_property!(gui["SMPS1ScanNum"], :text, @sprintf("%i", smps_scan_number.value))
    set_gtk_property!(gui["SMPS1ScanState"], :text, scan_state.value[1])
    set_gtk_property!(gui["SMPS1SetpointV"], :text, @sprintf("%.1f", V.value[1]))
    set_gtk_property!(gui["SMPS1CurrentDiam"], :text, @sprintf("%.1f", Dp.value[1]))

    set_gtk_property!(gui["SMPS2ScanCount"], :text, @sprintf("%.1f", elapsed_time.value))
    set_gtk_property!(gui["SMPS2ScanNum"], :text, @sprintf("%i", htdma_diam_number.value))
    set_gtk_property!(gui["SMPS2ScanState"], :text, scan_state.value[2])
    set_gtk_property!(gui["SMPS2SetpointV"], :text, @sprintf("%.1f", V.value[2]))
    set_gtk_property!(gui["SMPS2CurrentDiam"], :text, @sprintf("%.1f", Dp.value[2]))

    TE1Set = parse_box("TE1Set", NaN)
    TE1ReadT1 = parse_box("TE1ReadT1", NaN)
    TE1ReadT2 = parse_box("TE1ReadT2", NaN)
    TE2ReadT1 = parse_box("TE2ReadT1", NaN)
    TE2ReadT2 = parse_box("TE2ReadT2", NaN)
    Tdsh2 = get_gtk_property(gui["Tdsh2"], :text, String) |> x -> parse(Float64, x)
    Tdsa2 = get_gtk_property(gui["Tdsa2"], :text, String) |> x -> parse(Float64, x)
    InletTd = get_gtk_property(gui["InletTd"], :text, String) |> x -> parse_missing2(x)
    ColumnAverageT = mean([TE1ReadT1, TE1ReadT2, TE2ReadT1])
    ColumnAverageTd = (5.0 * Tdsh2 + 1.0 * Tdsa2) / 6.0
    x = get_gtk_property(gui["BathSetT"], :text, String)
    BathSetT = try
        parse(Float64, x)
    catch
        NaN
    end
    x = get_gtk_property(gui["BathReadT1"], :text, String)
    BathReadT1 = try
        parse(Float64, x)
    catch
        NaN
    end

    # Write data to file
    ts = now()     # Generate current time stamp

    push!(
        tenHz_df,
        Dict(
            :Timestamp => ts,
            :Unixtime => datetime2unix(ts),
            :Int64time => Dates.value(ts),
            :LapseTime => @sprintf("%.3f", elapsed_time.value),
            :stateDMA1 => Symbol(scan_state.value[1]),
            :voltageSetDMA1 => V.value[1],
            :currentDiameterDMA1 => Dp.value[1],
            :stateDMA2 => Symbol(scan_state.value[2]),
            :voltageSetDMA2 => V.value[2],
            :currentDiameterDMA2 => Dp.value[2],
            :RH1 => RH1,
            :RH2 => RH2,
            :RH3 => RH3,
            :RH4 => RH4,
            :T1 => T1,
            :T2 => T2,
            :T3 => T3,
            :T4 => T4,
            :TESet => TE1Set,
            :TE1ReadT1 => TE1ReadT1,
            :TE1ReadT2 => TE1ReadT2,
            :TE2ReadT1 => TE2ReadT1,
            :TE2ReadT2 => TE2ReadT2,
            :Tdsh2 => Tdsh2,
            :Tdsa2 => Tdsa2,
            :InletTd => InletTd,
            :ColumnAverageT => ColumnAverageT,
            :ColumnAverageTd => ColumnAverageTd,
            :BathSetT => BathSetT,
            :BathReadT1 =>  GEOptiSonde.Td.value[2],
            :N1cpcCount => N1cpcCount,
            :N2cpcCount => N2cpcCount,
            :N1cpcSerial => parse_box("Nserial1", missing),
            :N2cpcSerial => parse_box("Nserial2", missing),
            :Calibrate => CalibrationSwitch.value
        ),
    )
end

function oneHz_htdma_loop()
    state = deepcopy(tenHz_df[!, :stateDMA2])
    Dp = deepcopy(tenHz_df[!, :currentDiameterDMA2])
    useCounts = get_gtk_property(gui["SMPS2UseCounts"], :state, Bool)
    N = (useCounts == true) ? deepcopy(tenHz_df[!, :N2cpcCount]) :
        deepcopy(tenHz_df[!, :N2cpcSerial])
    Ncpc = deepcopy(tenHz_df[!, :N1cpcCount])
    τᶜ = get_gtk_property(gui["SMPS2PlumbTime"], :text, String) |> x -> parse(Float64, x)
    τserial =
        get_gtk_property(gui["SMPS2SerialDelay"], :text, String) |> x -> parse(Float64, x)
    (useCounts == false) && (τᶜ += τserial)
    τ = parse_box("SMPS2BeamTransitTime", 4.0)
    correct = @. x ->
        -lambertw(-x * flowRate2 * 16.666τ * 1e-6, 0) / (flowRate2 * 16.6666 * τ * 1e-6)
    if length(N[state.==:SCAN]) > τᶜ * 10 + 1
        N = circshift(N, Int(round(-τᶜ * 10)))
        N = N[(state.==:SCAN).|(state.==:FLUSH)]
        Ncpc = circshift(Ncpc, Int(round(-τᶜ * 10)))
        Ncpc = Ncpc[(state.==:SCAN).|(state.==:FLUSH)]
        if (useCounts == true)
            N = try
                correct(N)
            catch
                N
            end
        end
        Dp = Dp[(state.==:SCAN).|(state.==:FLUSH)]
        mDp = reverse(Dp[1:end-Int(round(τᶜ * 10))])
        mN = reverse(N[1:end-Int(round(τᶜ * 10))])
        mCPC = reverse(Ncpc[1:end-Int(round(τᶜ * 10))])
        n = htdma_diam_number.value
        if (n >= 1) && (n <= 6)
            ℝ₂[n], ℝᶜ[n] = resampleTDMA((mDp, mN, mCPC), (δ₂ˢᵐᵖˢ.Dp, δ₂ˢᵐᵖˢ.De))
        end
        eval(Meta.parse("plotHTDMA$n.data[1].ds.x = reverse(ℝ₂[$n].Dp)"))
        eval(Meta.parse("plotHTDMA$n.data[1].ds.y = reverse(ℝ₂[$n].N)"))
        if typeof(Meta.parse("sum(ℝᶜ[$n])")) != Missing
            Nx = eval(Meta.parse("ℝᶜ[$n]"))
            Nx = convert(Array{Float64}, Nx)
            eval(Meta.parse("plotHTDMA$n.data[2].ds.x = reverse(ℝ₂[$n].Dp)"))
            eval(Meta.parse("plotHTDMA$n.data[2].ds.y = reverse($Nx)"))
        end
        miny, maxy = Float64[], Float64[]
        for x in eval(Meta.parse("plotHTDMA$n.data[1:2]"))
            push!(miny, minimum(skipmissing(x.ds.y)))
            push!(maxy, maximum(skipmissing(x.ds.y)))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)

        Ddry =
            get_gtk_property(gui["SMPS1CurrentDiam"], :text, String) |>
            x -> parse(Float64, x)
        currentDiameter =
            get_gtk_property(gui["SMPS2CurrentDiam"], :text, String) |>
            x -> parse(Float64, x)
        maxD =
            get_gtk_property(gui["SMPS2StartDiameter"], :text, String) |>
            x -> parse(Float64, x)
        minD =
            get_gtk_property(gui["SMPS2EndDiameter"], :text, String) |>
            x -> parse(Float64, x)
        eval(Meta.parse("plotHTDMA$n.data[3].ds.x = [$(Ddry), $(Ddry)]"))
        eval(Meta.parse("plotHTDMA$n.data[3].ds.y = [$(miny), $(maxy)]"))
        eval(Meta.parse("plotHTDMA$n.data[4].ds.x = [$(currentDiameter), $(currentDiameter)]"))
        eval(Meta.parse("plotHTDMA$n.data[4].ds.y = [$(miny), $(maxy)]"))
        eval(Meta.parse("plotHTDMA$n.data[5].ds.x = [$(minD), $(minD)]"))
        eval(Meta.parse("plotHTDMA$n.data[5].ds.y = [$(miny), $(maxy)]"))
        eval(Meta.parse("plotHTDMA$n.data[6].ds.x = [$(maxD), $(maxD)]"))
        eval(Meta.parse("plotHTDMA$n.data[6].ds.y = [$(miny), $(maxy)]"))
        graph = eval(Meta.parse("plotHTDMA$n.strips[1]"))
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
        refreshplot(eval(Meta.parse("gplotHTDMA$n")))

        eval(Meta.parse("plotGF$n.data[1].ds.x = reverse(ℝ₂[$n].Dp./$Ddry)"))
        eval(Meta.parse("plotGF$n.data[1].ds.y = reverse(ℝ₂[$n].N)"))
        eval(Meta.parse("plotGF$n.data[2].ds.x = [$(currentDiameter/Ddry), $(currentDiameter/Ddry)]"))
        eval(Meta.parse("plotGF$n.data[2].ds.y = [$(miny), $(maxy)]"))
        eval(Meta.parse("plotGF$n.data[3].ds.x = [$(minD/Ddry), $(minD/Ddry)]"))
        eval(Meta.parse("plotGF$n.data[3].ds.y = [$(miny), $(maxy)]"))
        eval(Meta.parse("plotGF$n.data[4].ds.x = [$(maxD/Ddry), $(maxD/Ddry)]"))
        eval(Meta.parse("plotGF$n.data[4].ds.y = [$(miny), $(maxy)]"))
        graph = eval(Meta.parse("plotGF$n.strips[1]"))
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
        refreshplot(eval(Meta.parse("gplotGF$n")))
    end
end

function oneHz_smps_loop()
    # -    
    # SMPS shifting and inversion
    state = deepcopy(tenHz_df[!, :stateDMA1])
    Dp = deepcopy(tenHz_df[!, :currentDiameterDMA1])
    useCounts = get_gtk_property(gui["SMPS1UseCounts"], :state, Bool)
    N = (useCounts == true) ? deepcopy(tenHz_df[!, :N1cpcCount]) :
        deepcopy(tenHz_df[!, :N1cpcSerial])
    τᶜ = get_gtk_property(gui["SMPS1PlumbTime"], :text, String) |> x -> parse(Float64, x)
    τserial =
        get_gtk_property(gui["SMPS1SerialDelay"], :text, String) |> x -> parse(Float64, x)
    (useCounts == false) && (τᶜ += τserial)
    τ = parse_box("SMPS1BeamTransitTime", 4.0)

    correct = @. x ->
        -lambertw(-x * flowRate1 * 16.666τ * 1e-6, 0) / (flowRate1 * 16.6666 * τ * 1e-6)
    currentDiameter =
        get_gtk_property(gui["SMPS1CurrentDiam"], :text, String) |> x -> parse(Float64, x)
    if length(N[state.==:SCAN]) > τᶜ * 10 + 1
        N = circshift(N, Int(round(-τᶜ * 10)))
        N = N[(state.==:SCAN).|(state.==:FLUSH)]
        if (useCounts == true)
            N = try
                correct(N)
            catch
                N
            end
        end
        Dp = Dp[(state.==:SCAN).|(state.==:FLUSH)]
        mDp = reverse(Dp[1:end-Int(round(τᶜ * 10))])
        mN = reverse(N[1:end-Int(round(τᶜ * 10))])

        global ℝ₁ = resample((mDp, mN), (δ₁ˢᵐᵖˢ.Dp, δ₁ˢᵐᵖˢ.De))

        plot4.data[1].ds.x = reverse(ℝ₁.Dp)
        plot4.data[1].ds.y = reverse(ℝ₁.N)
        miny, maxy = Float64[], Float64[]
        for x in plot4.data[1:2]
            push!(miny, minimum(skipmissing(x.ds.y)))
            push!(maxy, maximum(skipmissing(x.ds.y)))
        end
        miny = minimum(miny)
        maxy = maximum(maxy)

        plot4.data[3].ds.x = [currentDiameter, currentDiameter]
        plot4.data[3].ds.y = [miny, maxy]
        maxD =
            get_gtk_property(gui["SMPS1StartDiameter"], :text, String) |>
            x -> parse(Float64, x)
        minD =
            get_gtk_property(gui["SMPS1EndDiameter"], :text, String) |>
            x -> parse(Float64, x)
        plot4.data[4].ds.x = [minD, minD]
        plot4.data[4].ds.y = [miny, maxy]
        plot4.data[5].ds.x = [maxD, maxD]
        plot4.data[5].ds.y = [miny, maxy]
        graph = plot4.strips[1]
        graph.yext = InspectDR.PExtents1D()
        graph.yext_full = InspectDR.PExtents1D(miny, maxy)
        refreshplot(gplot4)
    end
end


function generic_loop()
    t = main_elapsed_time.value

    push!(datestr, Dates.format(now(), "yyyymmdd"))
    # CPC I/O
    Nserial1 = readCPC(port1, CPCType1, flowRate1)
    Nserial2 = readCPC(port2, CPCType2, flowRate2)
    #Nserial3 = readCPC(port3, CPCType3, flowRate3)

    set_gtk_property!(gui["Nserial1"], :text, parse_missing(Nserial1))
    set_gtk_property!(gui["Nserial2"], :text, parse_missing(Nserial2))
    #set_gtk_property!(gui["Nserial3"],:text,parse_missing(Nserial3))


    # TE I/O
    TE1_T1 = TETechTC3625RS232.read_sensor_T1(portTE1)
    TE1_T2 = TETechTC3625RS232.read_sensor_T2(portTE1)
    T = TE1_T2
    (typeof(T) == Missing) && (T = 22.0)
    T = ((T > 30.0) || (T < 10.0)) ? 22.0 : T   # Set bounds from sensor
    push!(TEsetT, T)
    TETechTC3625RS232.set_temperature(portTE1, TEsetT.value)

    set_gtk_property!(gui["TE1Set"], :text, @sprintf("%.2f", TEsetT.value))
    set_gtk_property!(gui["TE1ReadT1"], :text, parse_missing1(TE1_T1))
    set_gtk_property!(gui["TE1ReadT2"], :text, parse_missing1(TE1_T2))

    TE2_T1 = TETechTC3625RS232.read_sensor_T1(portTE2)
    TE2_T2 = TETechTC3625RS232.read_sensor_T2(portTE2)
    TETechTC3625RS232.set_temperature(portTE2, TEsetT.value)
    set_gtk_property!(gui["TE2Set"], :text, @sprintf("%.2f", TEsetT.value))
    set_gtk_property!(gui["TE2ReadT1"], :text, parse_missing1(TE2_T1))
    set_gtk_property!(gui["TE2ReadT2"], :text, parse_missing1(TE2_T2))

    RHsh1 = get_gtk_property(gui["RHsh1"], :text, String) |> x -> parse_missing2(x)
    RHsa1 = get_gtk_property(gui["RHsa1"], :text, String) |> x -> parse_missing2(x)
    addpoint!(t, RHsh1, plot1, gplot1, 1, true)
    addpoint!(t, RHsa1, plot1, gplot1, 2, true)

    Tdsh2 = get_gtk_property(gui["Tdsh2"], :text, String) |> x -> parse_missing2(x)
    Tdsa2 = get_gtk_property(gui["Tdsa2"], :text, String) |> x -> parse_missing2(x)
    addpoint!(t, Tdsh2, plot2, gplot2, 1, true)
    addpoint!(t, Tdsa2, plot2, gplot2, 2, true)

    ColumnAverageT = mean([TE1_T1, TE1_T2, TE2_T1])
    ColumnAverageTd = (5.0 * Tdsh2 + 1.0 * Tdsa2) / 6.0
    set_gtk_property!(gui["ColumnAvgTemp"], :text, parse_missing1(ColumnAverageT))
    BathManualT =
        get_gtk_property(gui["BathManualTemp"], "value", Float64) 
    BathOffset =
        get_gtk_property(gui["BathOffset"], "value", Float64) 
    RHControl = get_gtk_property(gui["RHControlSwitch"], :state, Bool)
    bath_set = RHControl ? ColumnAverageT - BathOffset : BathManualT
    set_gtk_property!(gui["BathSetT"], :text, parse_missing1(bath_set))

    bath_readT = TETechTC3625RS232.read_sensor_T1(portTE3)
    GEOptiSonde.read(portOpti)
   
    set_gtk_property!(gui["BathReadT1"], :text, parse_missing1(bath_readT))
    set_gtk_property!(gui["BathReadT2"], :text, parse_missing1(GEOptiSonde.Td.value[2]))
    ColumnAverageTd = GEOptiSonde.Td.value[2]
    set_gtk_property!(gui["ColumnDewPoint"], :text, parse_missing1(ColumnAverageTd))
    a, b, c, d = 6.1121, 18.678, 257.14, 234.5
    es = T -> 100.0 * a * exp((b - T / d) * (T / (c + T)))
    calcRH = try
        100.0 * es(ColumnAverageTd) / es(ColumnAverageT)
    catch
        missing
    end

    set_gtk_property!(gui["CalculatedRH"], :text, parse_missing(calcRH))
    (typeof(calcRH) == Missing) || addpoint!(t, calcRH, plot3, gplot3, 1, true)
    BathManualT1 =
        get_gtk_property(gui["BathManualTemp1"], "value", Float64) 
    BathOffset1 =
        get_gtk_property(gui["BathOffset1"], "value", Float64) 
    bath_set1 = RHControl ? ColumnAverageT - BathOffset1 : BathManualT1

    polyscience_temperature = bath_set1 
    set_polyscience_temperature(portPS, polyscience_temperature)
    TETechTC3625RS232.set_temperature(portTE3, bath_set)
    return nothing
end

function parse_missing(N)
    str = try
        @sprintf("%.1f", N)
    catch
        "missing"
    end

    return str
end

function parse_missing1(N)
    str = try
        @sprintf("%.2f", N)
    catch
        "missing"
    end

    return str
end

function parse_missing2(N)
    str = try
        parse(Float64,N)
    catch
        0.0
    end

    return str
end


function resampleTDMA((mDp, mN, mCPC), (newDp, newDe))
    ΔlnD = log.(newDe[1:end-1] ./ newDe[2:end])
    R, CPC = Float64[], Float64[]
    for i = 1:length(newDe)-1
        ii = (mDp .<= newDe[i]) .& (mDp .> newDe[i+1])
        un = mDp[ii]
        c = mN[ii]
        Nm = length(c) > 0 ? mean(c) : 0
        d = mCPC[ii]
        Ncpc = length(d) > 0 ? mean(d) : 0
        push!(R, Nm)
        push!(CPC, Ncpc)
    end

    SizeDistribution([[]], newDe, newDp, ΔlnD, R ./ ΔlnD, R, :response), CPC
end

function resample((mDp, mN), (newDp, newDe))
    ΔlnD = log.(newDe[1:end-1] ./ newDe[2:end])
    R = Float64[]
    for i = 1:length(newDe)-1
        ii = (mDp .<= newDe[i]) .& (mDp .> newDe[i+1])
        un = mDp[ii]
        c = mN[ii]
        Nm = length(c) > 0 ? mean(c) : 0
        push!(R, Nm)
    end
    SizeDistribution([[]], newDe, newDp, ΔlnD, R ./ ΔlnD, R, :response)
end

function inlet()
    Tinlet, RHinlet = poll_EL1050()
    inletTd = try
        Tdew(Tinlet, RHinlet)
    catch 
        missing
    end
    set_gtk_property!(gui["InletTd"], :text, parse_missing(inletTd))
end
