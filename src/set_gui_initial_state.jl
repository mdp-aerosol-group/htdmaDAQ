function graph1(yaxis)
	plot = InspectDR.transientplot(yaxis, title="")
	InspectDR.overwritefont!(plot.layout, fontname="Helvetica", fontscale=1.0)
	plot.layout[:enable_legend] = true
	plot.layout[:halloc_legend] = 170
	plot.layout[:halloc_left] = 50
	plot.layout[:enable_timestamp] = false
	plot.layout[:length_tickmajor] = 10
	plot.layout[:length_tickminor] = 6
	plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plot.layout[:frame_data] =  InspectDR.AreaAttributes(
         line=InspectDR.line(style=:solid, color=black, width=0.5))
	plot.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
													   RGBA(0, 0, 0, 1))

	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(0, 205)

	a = plot.annotation
	a.xlabel = ""
	a.ylabels = [""]

	return plot
end

style = :solid

plot4 = InspectDR.Plot2D(:log,:lin, title="")
InspectDR.overwritefont!(plot4.layout, fontname="Helvetica", fontscale=1.0)
plot4.layout[:enable_legend] = true
plot4.layout[:halloc_legend] = 170
plot4.layout[:halloc_left] = 50
plot4.layout[:enable_timestamp] = false
plot4.layout[:length_tickmajor] = 10
plot4.layout[:length_tickminor] = 6
plot4.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
plot4.layout[:frame_data] =  InspectDR.AreaAttributes(
       line=InspectDR.line(style=:solid, color=black, width=0.5))
plot4.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
												   RGBA(0, 0, 0, 1))

plot4.xext = InspectDR.PExtents1D()
plot4.xext_full = InspectDR.PExtents1D(8, 600)

a = plot4.annotation
a.xlabel = "Diameter (nm)"
a.ylabels = ["Raw concentration (cm-3)"]
mp4,gplot4 = push_plot_to_gui!(plot4, gui["ResponsePlot"], wnd)
wfrm = add(plot4, [0.0], [0.0], id="Current Scan")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plot4, [0.0], [0.0], id="Past Scan")
wfrm.line = line(color=mblue, width=2, style=style)
wfrm = add(plot4, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plot4, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plot4, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)

graph = plot4.strips[1]
graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, 
								hmajor=true, hminor =true)


a= pwd() |> x->split(x,"/")
path = mapreduce(a->"/"*a,*,a[2:3])*"/Data/"
outfile = path*"yyyymmdd_hhmm.csv"
Gtk.set_gtk_property!(gui["DataFile"],:text,outfile)
Gtk.set_gtk_property!(gui["SMPS1ScanNum"], :text, "0")
Gtk.set_gtk_property!(gui["SMPS1ScanCount"], :text, "0")
Gtk.set_gtk_property!(gui["SMPS1ScanState"], :text, "HOLD");
Gtk.set_gtk_property!(gui["SMPS1SetpointV"], :text, "0");


function graph2(myaxis)
	plot = InspectDR.Plot2D(myaxis,:lin, title="")
	InspectDR.overwritefont!(plot.layout, fontname="Helvetica", fontscale=1.0)
	plot.layout[:enable_legend] = true
	plot.layout[:halloc_legend] = 170
	plot.layout[:halloc_left] = 50
	plot.layout[:enable_timestamp] = false
	plot.layout[:length_tickmajor] = 10
	plot.layout[:length_tickminor] = 6
	plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plot.layout[:frame_data] =  InspectDR.AreaAttributes(
         line=InspectDR.line(style=:solid, color=black, width=0.5))
	plot.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
													   RGBA(0, 0, 0, 1))

	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(0, 205)

	graph = plot.strips[1]
	graph.grid = InspectDR.GridRect(vmajor=true, vminor=true, 
									hmajor=true, hminor =true)
	

	a = plot.annotation
	a.xlabel = ""
	a.ylabels = [""]

	return plot
end


plotHTDMA1 = graph2(:log)
mHTDMA1,gplotHTDMA1 = push_plot_to_gui!(plotHTDMA1, gui["HTDMAAerosolSizeDistribution1"], wnd)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA1, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA1.layout[:halloc_legend] = 120
plotHTDMA1.xext = InspectDR.PExtents1D()
plotHTDMA1.xext_full = InspectDR.PExtents1D(8, 600)

plotHTDMA2 = graph2(:log)
mHTDMA2,gplotHTDMA2 = push_plot_to_gui!(plotHTDMA2, gui["HTDMAAerosolSizeDistribution2"], wnd)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA2, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA2.layout[:halloc_legend] = 120
plotHTDMA2.xext = InspectDR.PExtents1D()
plotHTDMA2.xext_full = InspectDR.PExtents1D(8, 600)

plotHTDMA3 = graph2(:log)
mHTDMA3,gplotHTDMA3 = push_plot_to_gui!(plotHTDMA3, gui["HTDMAAerosolSizeDistribution3"], wnd)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA3, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA3.layout[:halloc_legend] = 120
plotHTDMA3.xext = InspectDR.PExtents1D()
plotHTDMA3.xext_full = InspectDR.PExtents1D(8, 600)

plotHTDMA4 = graph2(:log)
mHTDMA4,gplotHTDMA4 = push_plot_to_gui!(plotHTDMA4, gui["HTDMAAerosolSizeDistribution4"], wnd)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA4, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA4.layout[:halloc_legend] = 120
plotHTDMA4.xext = InspectDR.PExtents1D()
plotHTDMA4.xext_full = InspectDR.PExtents1D(8, 600)

plotHTDMA5 = graph2(:log)
mHTDMA5,gplotHTDMA5 = push_plot_to_gui!(plotHTDMA5, gui["HTDMAAerosolSizeDistribution5"], wnd)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA5, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA5.layout[:halloc_legend] = 120
plotHTDMA5.xext = InspectDR.PExtents1D()
plotHTDMA5.xext_full = InspectDR.PExtents1D(8, 600)

plotHTDMA6 = graph2(:log)
mHTDMA6,gplotHTDMA6 = push_plot_to_gui!(plotHTDMA6, gui["HTDMAAerosolSizeDistribution6"], wnd)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="Ncpc")
wfrm.line = line(color=mgrey, width=2, style=style)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="Ddry")
wfrm.line = line(color=red, width=2, style=style)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotHTDMA6, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotHTDMA6.layout[:halloc_legend] = 120
plotHTDMA6.xext = InspectDR.PExtents1D()
plotHTDMA6.xext_full = InspectDR.PExtents1D(8, 600)

plotGF1 = graph2(:lin)
mGF1,gplotGF1 = push_plot_to_gui!(plotGF1, gui["HTDMAGFDistribution1"], wnd)
wfrm = add(plotGF1, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF1, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF1, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF1, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotGF1.layout[:halloc_legend] = 120
plotGF1.xext = InspectDR.PExtents1D()
plotGF1.xext_full = InspectDR.PExtents1D(0.5, 2.5)

plotGF2 = graph2(:lin)
mGF2,gplotGF2 = push_plot_to_gui!(plotGF2, gui["HTDMAGFDistribution2"], wnd)
wfrm = add(plotGF2, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF2, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF2, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF2, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotGF2.layout[:halloc_legend] = 120
plotGF2.xext = InspectDR.PExtents1D()
plotGF2.xext_full = InspectDR.PExtents1D(0.5, 2.5)

plotGF3 = graph2(:lin)
mGF3,gplotGF3 = push_plot_to_gui!(plotGF3, gui["HTDMAGFDistribution3"], wnd)
wfrm = add(plotGF3, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF3, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF3, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF3, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotGF3.layout[:halloc_legend] = 120
plotGF3.xext = InspectDR.PExtents1D()
plotGF3.xext_full = InspectDR.PExtents1D(0.5, 2.5)

plotGF4 = graph2(:lin)
mGF4,gplotGF4 = push_plot_to_gui!(plotGF4, gui["HTDMAGFDistribution4"], wnd)
wfrm = add(plotGF4, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF4, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF4, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF4, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)
plotGF4.layout[:halloc_legend] = 120
plotGF4.xext = InspectDR.PExtents1D()
plotGF4.xext_full = InspectDR.PExtents1D(0.5, 2.5)

plotGF5 = graph2(:lin)
mGF5,gplotGF5 = push_plot_to_gui!(plotGF5, gui["HTDMAGFDistribution5"], wnd)
wfrm = add(plotGF5, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF5, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF5, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF5, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)

plotGF5.layout[:halloc_legend] = 120
plotGF5.xext = InspectDR.PExtents1D()
plotGF5.xext_full = InspectDR.PExtents1D(0.5, 2.5)

plotGF6 = graph2(:lin)
mGF6,gplotGF6 = push_plot_to_gui!(plotGF6, gui["HTDMAGFDistribution6"], wnd)
wfrm = add(plotGF6, [0.0], [0.0], id="R")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotGF6, [0.0], [0.0], id="Current D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF6, [0.0], [0.0], id="Min D")
wfrm.line = line(color=black, width=2, style=:solid)
wfrm = add(plotGF6, [0.0], [0.0], id="Max D")
wfrm.line = line(color=black, width=2, style=:solid)

plotGF6.layout[:halloc_legend] = 120
plotGF6.xext = InspectDR.PExtents1D()
plotGF6.xext_full = InspectDR.PExtents1D(0.5, 2.5)

style = :solid 
plotTemp = graph1(:lin)
plotTemp.layout[:halloc_legend] = 110
mpTemp,gplotTemp = push_plot_to_gui!(plotTemp, gui["TempGraph1"], wnd)
wfrm = add(plotTemp, [0.0], [22.0], id="Set T(°C)")
wfrm.line = line(color=black, width=2, style=style)
wfrm = add(plotTemp, [0.0], [22.0], id="T1 (°C)")
wfrm.line = line(color=mblue, width=2, style=style)
wfrm = add(plotTemp, [0.0], [22.0], id="T2 (°C)")
wfrm.line = line(color=red, width=2, style=style)

Gtk.showall(wnd);
