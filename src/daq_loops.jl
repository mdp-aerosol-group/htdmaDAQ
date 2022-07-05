function tenHz_daq_loop()
	# LABJACK Read 
    # AIN, Tk, rawcount, count = labjack_signals.value 
    # N1cpcCount = count[1] / tenHz.value / (flowRate1 * 16.6666666)  
    # N2cpcCount = count[2] / tenHz.value / (flowRate2 * 16.6666666) 

	N1cpcCount = 0.0
	N2cpcCount = 0.0
    set_gtk_property!(gui["Ncounts1"], :text, @sprintf("%0.1f", N1cpcCount))
    set_gtk_property!(gui["Ncounts2"], :text, @sprintf("%0.1f", N2cpcCount))

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

    TE1ReadT1 = parse_box("TE1ReadT1", NaN)
    TE1ReadT2 = parse_box("TE1ReadT2", NaN)

    ts = now()   

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
            :TESet => TE1setT.value,
            :TE1ReadT1 => TE1ReadT1,
            :TE1ReadT2 => TE1ReadT2,
            :N1cpcCount => N1cpcCount,
            :N2cpcCount => N2cpcCount,
            :N1cpcSerial => parse_box("Nserial1", missing),
            :N2cpcSerial => parse_box("Nserial2", missing),
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
	Nserial1 = readWriteCPC(port1, CPCType1, flowRate1, signalV.value[1])
	Nserial2 = readWriteCPC(port2, CPCType2, flowRate2, signalV.value[2])

    set_gtk_property!(gui["Nserial1"], :text, parse_missing(Nserial1))
    set_gtk_property!(gui["Nserial2"], :text, parse_missing(Nserial2))

    if updatePower.value == true
        value = get_gtk_property(gui["power"], :state, Bool)
        ret = (value == true) ? TETechTC3625RS232.turn_power_on(portTE1) : TETechTC3625RS232.turn_power_off(portTE1)
        state = (value == true) ? " is on" : " is off"
        @printf("Power%s\n",state)    
        push!(updatePower, false)
    end
    
    if updateBandwidth.value == true
        value = get_gtk_property(gui["proportional"], :value, Float64)
        ret = TETechTC3625RS232.write_proportional_bandwidth(portTE1, value)
        @printf("Set proportional bandwidth to %f\n", ret)
        push!(updateBandwidth, false)
    end

    if updateIntegral.value == true
        value = get_gtk_property(gui["integral"], :value, Float64)
    	ret = TETechTC3625RS232.write_integral_gain(portTE1, value)
        @printf("Set integral gain to %f\n", ret)
        push!(updateIntegral, false)
    end

    if updateDerivative.value == true
        value = get_gtk_property(gui["derivative"], :value, Float64)
        ret = TETechTC3625RS232.write_derivative_gain(portTE1, value)
        @printf("Set derivative gain to %f\n", ret)
        push!(updateDerivative, false)
    end

    if updateThermistor.value == true
        value = get_gtk_property(gui["thermistor"], "active-id", String) |> x->parse(Int,x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set thermistor type to %s\n", ret)
        push!(updateThermistor, false)
    end

    if updatePolarity.value == true
        value = get_gtk_property(gui["polarity"], "active-id", String) |> x->parse(Int,x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set controller polarity to %s\n", ret)
        push!(updatePolarity, false)
    end

    TE1_T1 = TETechTC3625RS232.read_sensor_T1(portTE1)
    TE1_T2 = TETechTC3625RS232.read_sensor_T2(portTE1)
    Power = TETechTC3625RS232.read_power_output(portTE1)
    TETechTC3625RS232.set_temperature(portTE1, TE1setT.value)
     
    mode = get_gtk_property(te1Mode, "active-id", String) |> Symbol
    (mode == :Ramp) && set_gtk_property!(gui["TERampCounter1"],:text,@sprintf("%.1f",TE1_elapsed_time.value))
    set_gtk_property!(gui["TE1ReadT1"],:text,parse_missing1(TE1_T1))
    set_gtk_property!(gui["TE1ReadT2"],:text,parse_missing1(TE1_T2))
    set_gtk_property!(gui["TE1PowerOutput"],:text,parse_missing1(Power))
    addpoint!(t,TE1setT.value,plotTemp,gplotTemp,1,true)
	(typeof(TE1_T1) == Missing) || addpoint!(t,TE1_T1,plotTemp,gplotTemp,2,true)
    ## (typeof(TE1_T2) == Missing) || addpoint!(t,TE1_T2,plotTemp,gplotTemp,3,true)

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
