using DifferentialMobilityAnalyzers

function get_DMA_dimensions(column)
    (column == :TSI) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    (column == :HFDMA) && ((r₁, r₂, l) = (0.05, 0.058, 0.6))
    (column == :RDMA) && ((r₁, r₂, l) = (2.4e-3, 50.4e-3, 10e-3))
    (column == :HELSINKI) && ((r₁, r₂, l) = (2.5e-2, 3.3e-2, 10.9e-2))
    (column == :HELSINKI1) && ((r₁, r₂, l) = (2.64e-2, 3.3e-2, 10.9e-2))
    (column == :VIENNA) && ((r₁, r₂, l) = (9.37e-3, 1.961e-2, 0.44369))
    form = (column == :RDMA) ? :radial : :cylindrical
    return r₁, r₂, l, form
end

function set_SMPS_config(col)
	lpm = 1.66666e-5
	t = 293.15
    p = 1001.0 * 100.0
    qsh = 5.0 * lpm
    qsa = 1.0 * lpm
    leff = 4.1
    bins = 120
    polarity = :-
    m = 6

    r₁, r₂, l, form = get_DMA_dimensions(col)
    Λ₁ = DMAconfig(t, p, qsa, qsh, r₁, r₂, l, leff, polarity, m, form)
    v₁, v₂ = 10, 10000
    z₁, z₂ = vtoz(Λ₁, v₂), vtoz(Λ₁, v₁)
    δ₁ = setupDMA(Λ₁, z₁, z₂, bins)
	
	return Λ₁, δ₁
end

Λ, δ = set_SMPS_config(:HELSINKI)
Λ1, δ1 = set_SMPS_config(:HELSINKI1)
vtod(Λ, V) = vtoz(Λ, V) |> z -> ztod(Λ, 1, z)
vtod(Λ, 2426) ./ vtod(Λ1, 2426)


