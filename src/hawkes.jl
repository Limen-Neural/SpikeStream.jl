# hawkes.jl — Self-Exciting Hawkes Intensity Proxy
#
# Computes a momentum / adrenaline signal proportional to recent jump activity.
# Higher intensity → more self-exciting signal jumps → higher SNN arousal.

"""
    compute_hawkes(signal_values::AbstractVector{<:Real}) -> Float64

Estimate the Hawkes self-exciting intensity of `signal_values` from recent
absolute differences.

Returns a value in `[0.5, 3.0]`.  Returns `1.0` (neutral) when the series
has fewer than 2 elements.

# Example
```julia
using SpikeStream
signal_values = [100.0, 100.5, 102.0, 101.0, 103.5]
λ = compute_hawkes(signal_values)   # > 1.0 for volatile series
```
"""
function compute_hawkes(signal_values::AbstractVector{<:Real})::Float64
    length(signal_values) < 2 && return 1.0

    diffs     = abs.(diff(Float64.(signal_values)))
    intensity = 1.0 + mean(diffs) * 10.0
    return clamp(intensity, 0.5, 3.0)
end
