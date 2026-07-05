# SPDX-License-Identifier: MIT OR Apache-2.0

# hurst.jl — Hurst Exponent via R/S Analysis
#
# Computes trend conviction / long-range dependence of a signal series.
# H > 0.5 → trending, H < 0.5 → mean-reverting, H ≈ 0.5 → random walk.

"""
    compute_hurst(signal_values::AbstractVector{<:Real}) -> Float64

Estimate the Hurst exponent of `signal_values` using simplified R/S analysis.

Returns a value in `[0.2, 0.8]`.  Returns `0.5` (random walk) when the
series is too short (< 20 elements) or degenerate (zero variance).

# Example
```julia
using SpikeStream
signal_values = cumsum(randn(200)) .+ 100.0
h = compute_hurst(signal_values)   # typically near 0.5 for a random walk
```
"""
function compute_hurst(signal_values::AbstractVector{<:Real})::Float64
    length(signal_values) < 20 && return 0.5

    diffs = diff(Float64.(signal_values))
    m = mean(diffs)
    s = std(diffs)

    s < 1e-10 && return 0.5   # degenerate (constant series)

    cum_dev = cumsum(diffs .- m)
    r = maximum(cum_dev) - minimum(cum_dev)

    h = log(r / s) / log(length(signal_values))
    return clamp(h, 0.2, 0.8)
end
