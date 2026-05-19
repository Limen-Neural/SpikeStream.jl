# gbm_surprise.jl — Geometric Brownian Motion Surprise Z-Score
#
# Computes the last logarithmic rate of change's deviation from the local
# GBM drift/volatility estimate.  Positive values → upward surprise;
# negative → downward surprise.  Useful for anomaly detection and adaptive
# SNN threshold modulation.

"""
    compute_gbm_surprise(signal_values::AbstractVector{<:Real}) -> Float64

Compute the GBM surprise Z-score of the last logarithmic rate of change in
`signal_values`.

The surprise is `(last_delta − drift) / volatility`, where `drift` and
`volatility` are estimated from the full `signal_values` series.

Returns a value in `[-3.0, 3.0]`.  Returns `0.0` when the series has fewer
than 5 elements or volatility is effectively zero.

# Example
```julia
using SpikeStream
signal_values = [100.0, 101.0, 100.5, 102.0, 103.5]
z = compute_gbm_surprise(signal_values)   # positive → last move was above expectation
```
"""
function compute_gbm_surprise(signal_values::AbstractVector{<:Real})::Float64
    length(signal_values) < 5 && return 0.0

    sv         = Float64.(signal_values)
    log_deltas = log.(sv[2:end] ./ sv[1:end-1])
    drift      = mean(log_deltas)
    vol        = std(log_deltas)

    vol < 1e-10 && return 0.0

    surprise = (log_deltas[end] - drift) / vol
    return clamp(surprise, -3.0, 3.0)
end
