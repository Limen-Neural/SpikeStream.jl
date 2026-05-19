"""
    SpikeStream

Streaming time-series feature extraction designed to feed continuous data
into spiking neural networks.

Provides three complementary signal analysis primitives:
- `compute_hurst(prices)` — Hurst exponent via R/S analysis (trend conviction)
- `compute_hawkes(prices)` — Self-exciting Hawkes intensity (momentum/burst detection)
- `compute_gbm_surprise(prices)` — GBM Z-score residuals (anomaly detection)

All functions accept a `Vector{<:Real}` and return a scalar `Float64` in a
well-defined, SNN-compatible range.
"""
module SpikeStream

using Statistics

include("hurst.jl")
include("hawkes.jl")
include("gbm_surprise.jl")

export compute_hurst, compute_hawkes, compute_gbm_surprise

end # module
