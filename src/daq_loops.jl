# function vtod_lookup_function()    
#     Vs = ncread("lookup_vtod.cdf", "Vs")    
#     Ts = ncread("lookup_vtod.cdf", "Ts")    
#     ps = ncread("lookup_vtod.cdf", "ps")    
#     lookup = ncread("lookup_vtod.cdf", "lookup")    
#     itp = interpolate((Vs, Ts, ps), lookup, Gridded(Linear()))    
#     extp = extrapolate(itp, NaN)    
#     return extp    
# end    
     
# vtod_lookup = vtod_lookup_function()  

function tenHz_daq_loop()
    # LABJACK Read 
    AIN, Tk, rawcount, count = labjack_signals.value
    N1cpcCount = count[2] / tenHz.value / (0.4 * 16.6666666)
    N2cpcCount = count[1] / tenHz.value / (0.4 * 16.6666666)
    
    RH, T, Td = AIN2HC(AIN, 3, 4)

    set_gtk_property!(gui["readRH1"], :text, @sprintf("%0.1f", RH))
    set_gtk_property!(gui["readT1"], :text, @sprintf("%0.1f", T))
    set_gtk_property!(gui["readTd1"], :text, @sprintf("%0.1f", Td))


    readV2 = AIN[1] .* 1000
    readV1 = AIN[3] .* 1000
    push!(Vr, abs.([readV1, readV2]))

    if N1cpcCount < 0.0
        N1cpcCount =  get_gtk_property(gui["Ncounts1"], :text, String) |> x -> parse(Float64, x)
    else
        set_gtk_property!(gui["Ncounts1"], :text, @sprintf("%0.1f", N1cpcCount))
    end

    if N2cpcCount < 0.0
        N2cpcCount =  get_gtk_property(gui["Ncounts2"], :text, String) |> x -> parse(Float64, x)
    else
        set_gtk_property!(gui["Ncounts2"], :text, @sprintf("%0.1f", N2cpcCount))
    end
    

    set_gtk_property!(gui["SMPS1ReadV1"], :text, @sprintf("%0.1f", readV1))
    set_gtk_property!(gui["SMPS2ReadV1"], :text, @sprintf("%0.1f", readV2))

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
            :voltageReadDMA1 => readV1,
            :currentDiameterDMA1 => Dp.value[1],
            :stateDMA2 => Symbol(scan_state.value[2]),
            :voltageSetDMA2 => V.value[2],
            :voltageReadDMA2 => readV2,
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
    mdf = deepcopy(tenHz_df)
    state = deepcopy(mdf[!, :stateDMA2])
    Dp = deepcopy(mdf[!, :currentDiameterDMA2])
    useCounts = get_gtk_property(gui["SMPS2UseCounts"], :state, Bool)
    N =
        (useCounts == true) ? deepcopy(mdf[!, :N2cpcCount]) :
        deepcopy(mdf[!, :N2cpcSerial])
    Ncpc = deepcopy(mdf[!, :N1cpcCount])
    τᶜ = get_gtk_property(gui["SMPS2PlumbTime"], :text, String) |> x -> parse(Float64, x)
    τserial =
        get_gtk_property(gui["SMPS2SerialDelay"], :text, String) |> x -> parse(Float64, x)
    (useCounts == false) && (τᶜ += τserial)
    τ = parse_box("SMPS2BeamTransitTime", 4.0)
    correct = @. x ->
        -lambertw(-x * flowRate2 * 16.666τ * 1e-6, 0) / (flowRate2 * 16.6666 * τ * 1e-6)
    if length(N) > τᶜ * 10 + 1
        N = circshift(N, Int(round(-τᶜ * 10)))
        Ncpc = circshift(Ncpc, Int(round(-τᶜ * 10)))
        ii = (state .== :UPSCAN) 
        if (useCounts == true)
            N = try
                correct(N)
            catch
                N
            end
        end
        mDp = reverse(Dp[1:end-Int(round(τᶜ * 10))])
        mN = reverse(N[1:end-Int(round(τᶜ * 10))])
        mCPC = reverse(Ncpc[1:end-Int(round(τᶜ * 10))])
        mstate = reverse(state[1:end-Int(round(τᶜ * 10))])
        ii = (mstate .== :UPSCAN)
        jj = (mstate .== :DOWNSCAN)
        
        n = htdma_diam_number.value
        if (n >= 1) && (n <= 6)
            ℝ₂[n],aa = resampleTDMA((mDp[ii], mN[ii], mCPC[ii]), (δ₂ˢᵐᵖˢ.Dp, δ₂ˢᵐᵖˢ.De))
            if sum(jj) > 0
               ℝ₃[n], _ = resampleTDMA((mDp[jj], mN[jj], mCPC[jj]), (δ₂ˢᵐᵖˢ.Dp, δ₂ˢᵐᵖˢ.De))
            else
                ℝ₃[n], _ = resampleTDMA((mDp[ii], zeros(sum(ii)), zeros(sum(ii))), (δ₂ˢᵐᵖˢ.Dp, δ₂ˢᵐᵖˢ.De))
           end

        end
        eval(Meta.parse("plotHTDMA$n.data[1].ds.x = reverse(ℝ₂[$n].Dp)"))
        eval(Meta.parse("plotHTDMA$n.data[1].ds.y = reverse(ℝ₂[$n].N)"))
        eval(Meta.parse("plotHTDMA$n.data[2].ds.x = reverse(ℝ₃[$n].Dp)"))
        eval(Meta.parse("plotHTDMA$n.data[2].ds.y = reverse(ℝ₃[$n].N)"))
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
        eval(
            Meta.parse(
                "plotHTDMA$n.data[4].ds.x = [$(currentDiameter), $(currentDiameter)]",
            ),
        )
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
        eval(
            Meta.parse(
                "plotGF$n.data[2].ds.x = [$(currentDiameter/Ddry), $(currentDiameter/Ddry)]",
            ),
        )
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
    state = deepcopy(tenHz_df[!, :stateDMA2])
    Dp = deepcopy(tenHz_df[!, :currentDiameterDMA2])
    useCounts = get_gtk_property(gui["SMPS2UseCounts"], :state, Bool)
    N =
        (useCounts == true) ? deepcopy(tenHz_df[!, :N2cpcCount]) :
        deepcopy(tenHz_df[!, :N2cpcSerial])
    τᶜ = get_gtk_property(gui["SMPS2PlumbTime"], :text, String) |> x -> parse(Float64, x)
    τserial =
        get_gtk_property(gui["SMPS2SerialDelay"], :text, String) |> x -> parse(Float64, x)
    (useCounts == false) && (τᶜ += τserial)
    τ = parse_box("SMPS2BeamTransitTime", 4.0)

    correct = @. x ->
        -lambertw(-x * flowRate1 * 16.666τ * 1e-6, 0) / (flowRate1 * 16.6666 * τ * 1e-6)
    currentDiameter =
        get_gtk_property(gui["SMPS2CurrentDiam"], :text, String) |> x -> parse(Float64, x)
    if length(N) > τᶜ * 10 + 1
        N = circshift(N, Int(round(-τᶜ * 10)))
        N = N
        if (useCounts == true)
            N = try
                correct(N)
            catch
                N
            end
        end
        Dp = Dp
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
    Nserial1 = 0.0
    a = try
        str = reduce(*,vcat(dataBufferCPC1[end-2:end]))
        a = split(str, "\r\n")

        cpcp = a[end-1]
        (cpcp[1:2] .== "20") && (cpcp[end-2:end] .== "132") ? cpcp : "00"
    catch
        "00"
    end

    cs = try
        rawc = @chain split(a, ",") getindex(_, 20) parse(Float64, _)
        flow = @chain split(a, ",") getindex(_, 16) parse(Float64, _)
        round(rawc/flow .* 60.0, digits = 1)
    catch
        0.0
    end

    b = try
        str = reduce(*,vcat(dataBufferCPC2[end-2:end]))
        b = split(str, "\r\r")

        cpcp = a[end-1]

        (cpcp[1:4] .== "RALL") && (length(cpcp) > 50) ? cpcp : "00"
    catch
        "00"
    end
    
    cs2 = try
        rawconc = @chain split(b, ',') getindex(3) parse(Float64, _)
    catch
        0.0
    end

    set_gtk_property!(gui["Nserial1"], :text, parse_missing(cs2))
    set_gtk_property!(gui["Nserial2"], :text, parse_missing(cs))

    if updatePower.value == true
        value = get_gtk_property(gui["power"], :state, Bool)
        ret =
            (value == true) ? TETechTC3625RS232.turn_power_on(portTE1) :
            TETechTC3625RS232.turn_power_off(portTE1)
        state = (value == true) ? " is on" : " is off"
        @printf("Power%s\n", state)
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
        value =
            get_gtk_property(gui["thermistor"], "active-id", String) |> x -> parse(Int, x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set thermistor type to %s\n", ret)
        push!(updateThermistor, false)
    end

    if updatePolarity.value == true
        value = get_gtk_property(gui["polarity"], "active-id", String) |> x -> parse(Int, x)
        ret = TETechTC3625RS232.set_sensor_type(portTE1, value)
        @printf("Set controller polarity to %s\n", ret)
        push!(updatePolarity, false)
    end

    TE1_T1 = TETechTC3625RS232.read_sensor_T1(portTE1)
    TE1_T2 = TETechTC3625RS232.read_sensor_T2(portTE1)
    Power = TETechTC3625RS232.read_power_output(portTE1)
    TETechTC3625RS232.set_temperature(portTE1, TE1setT.value)

    mode = get_gtk_property(te1Mode, "active-id", String) |> Symbol
    (mode == :Ramp) && set_gtk_property!(
        gui["TERampCounter1"],
        :text,
        @sprintf("%.1f", TE1_elapsed_time.value)
    )
    set_gtk_property!(gui["TE1ReadT1"], :text, parse_missing1(TE1_T1))
    set_gtk_property!(gui["TE1ReadT2"], :text, parse_missing1(TE1_T2))
    set_gtk_property!(gui["TE1PowerOutput"], :text, parse_missing1(Power))
    addpoint!(t, TE1setT.value, plotTemp, gplotTemp, 1, true)
    (typeof(TE1_T1) == Missing) || addpoint!(t, TE1_T1, plotTemp, gplotTemp, 2, true)
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
        parse(Float64, N)
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
    AIN, _, _, _ = labjackReadWrite(0.0, 0.0, false, false; HANDLE = HANDLE1)
    RH, T, Td = AIN2HC(AIN, 1, 2)

    set_gtk_property!(gui["readRH2"], :text, @sprintf("%0.1f", RH))
    set_gtk_property!(gui["readT2"], :text, @sprintf("%0.1f", T))
    set_gtk_property!(gui["readTd2"], :text, @sprintf("%0.1f", Td))

    # count = sum(dataBufferCounts[end])
    # set_gtk_property!(gui["POPSq"], :text, @sprintf("%0.2f", dataBufferQ[end]))
    # set_gtk_property!(gui["POPSq1"], :text, @sprintf("%0.1f", dataBufferN[end]))
    # set_gtk_property!(gui["POPScount"], :text, @sprintf("%i", count))

    # set_gtk_property!(gui["UDPdata"], :text, get_packet())
    # t = main_elapsed_time.value
    # addpoint!(t, dataBufferN[end], POPSConc, gplotConc, 1, true)
    # addpoint!(t, dataBufferQ[end], POPSFlow, gplotFlow, 1, false)
    # graph = POPSFlow.strips[1]
    # graph.yext = InspectDR.PExtents1D()
    # graph.yext_full = InspectDR.PExtents1D(0.0, 0.5)
    # addpoint!(t, count, POPSCount, gplotCount, 1, true)
    # try
    #     x = range(logmin, stop = logmax, length = nbins) |> collect
    #     addseries!(exp10.(x), mean(dataBufferCounts), POPSHist, gplotHist, 1, true, true)
    # catch
    # end

end
