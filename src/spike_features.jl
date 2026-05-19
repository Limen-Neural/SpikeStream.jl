"""
    spike_count(spike_times; t_start=nothing, t_end=nothing) -> Int

Count spikes in `spike_times`, optionally restricted to `[t_start, t_end]`.

`spike_times` should be numeric timestamps in seconds (or any consistent unit).
When no window is provided, all spikes are counted.
"""
function spike_count(spike_times::AbstractVector{<:Real}; t_start=nothing, t_end=nothing)::Int
    if isnothing(t_start) && isnothing(t_end)
        return length(spike_times)
    end

    start_t = isnothing(t_start) ? -Inf : Float64(t_start)
    end_t = isnothing(t_end) ? Inf : Float64(t_end)
    end_t < start_t && return 0

    count = 0
    for t in spike_times
        tf = Float64(t)
        if start_t <= tf <= end_t
            count += 1
        end
    end
    return count
end

"""
    spike_density(spike_times; t_start=nothing, t_end=nothing) -> Float64

Compute spike density as `spike_count / window_duration`.

Returns `0.0` when fewer than 2 spikes are available to infer a duration,
or when the requested window has non-positive duration.
"""
function spike_density(spike_times::AbstractVector{<:Real}; t_start=nothing, t_end=nothing)::Float64
    if isnothing(t_start) || isnothing(t_end)
        length(spike_times) < 2 && return 0.0
        t_min = minimum(Float64.(spike_times))
        t_max = maximum(Float64.(spike_times))
    else
        t_min = Float64(t_start)
        t_max = Float64(t_end)
    end

    duration = t_max - t_min
    duration <= 0 && return 0.0

    n = spike_count(spike_times; t_start=t_min, t_end=t_max)
    return n / duration
end

"""
    isi_stats(spike_times) -> NamedTuple

Compute inter-spike-interval statistics.

Returns `(mean, std, min, max, cv)` where CV is coefficient of variation `std/mean`.
All values are non-negative. For fewer than 2 spikes, returns zeros.
"""
function isi_stats(spike_times::AbstractVector{<:Real})
    length(spike_times) < 2 && return (mean=0.0, std=0.0, min=0.0, max=0.0, cv=0.0)

    times = sort(Float64.(spike_times))
    isis = diff(times)

    μ = mean(isis)
    σ = std(isis)
    min_isi = minimum(isis)
    max_isi = maximum(isis)
    cv = μ > 0 ? σ / μ : 0.0

    return (mean=μ, std=σ, min=min_isi, max=max_isi, cv=cv)
end

"""
    detect_bursts(spike_times; max_isi=0.02, min_spikes=3) -> Vector{UnitRange{Int}}

Detect bursts as contiguous runs where each inter-spike interval is `<= max_isi`.
Returns index ranges into the sorted spike-time sequence.
"""
function detect_bursts(spike_times::AbstractVector{<:Real}; max_isi::Real=0.02, min_spikes::Int=3)
    n = length(spike_times)
    n < min_spikes && return UnitRange{Int}[]

    times = sort(Float64.(spike_times))
    isis = diff(times)

    bursts = UnitRange{Int}[]
    run_start = 1
    run_len = 1

    for (i, isi) in enumerate(isis)
        if isi <= max_isi
            run_len += 1
        else
            if run_len >= min_spikes
                push!(bursts, run_start:(run_start + run_len - 1))
            end
            run_start = i + 1
            run_len = 1
        end
    end

    if run_len >= min_spikes
        push!(bursts, run_start:(run_start + run_len - 1))
    end

    return bursts
end

"""
    windowed_spike_features(spike_times; window_size, step=window_size, t_start=nothing, t_end=nothing)

Extract spike features per window. Returns a vector of named tuples with:
`(t_start, t_end, count, density, isi_mean, isi_cv, burst_count)`.
"""
function windowed_spike_features(
    spike_times::AbstractVector{<:Real};
    window_size::Real,
    step::Real=window_size,
    t_start=nothing,
    t_end=nothing,
)
    window_size <= 0 && throw(ArgumentError("window_size must be > 0"))
    step <= 0 && throw(ArgumentError("step must be > 0"))

    if isempty(spike_times)
        base_start = isnothing(t_start) ? 0.0 : Float64(t_start)
        base_end = isnothing(t_end) ? 0.0 : Float64(t_end)
        base_end < base_start && return NamedTuple[]
    else
        times = sort(Float64.(spike_times))
        base_start = isnothing(t_start) ? first(times) : Float64(t_start)
        base_end = isnothing(t_end) ? last(times) : Float64(t_end)
    end

    base_end < base_start && return NamedTuple[]

    features = NamedTuple[]
    cur = base_start
    while cur < base_end
        nxt = min(cur + window_size, base_end)
        local = Float64[]
        for t in spike_times
            tf = Float64(t)
            if cur <= tf < nxt
                push!(local, tf)
            end
        end

        c = length(local)
        d = nxt > cur ? c / (nxt - cur) : 0.0
        stats = isi_stats(local)
        b = length(detect_bursts(local))

        push!(features, (
            t_start=cur,
            t_end=nxt,
            count=c,
            density=d,
            isi_mean=stats.mean,
            isi_cv=stats.cv,
            burst_count=b,
        ))

        cur += step
    end

    return features
end

"""
    normalized_feature_vector(spike_times; t_start=nothing, t_end=nothing, max_density=1000.0) -> Vector{Float64}

Build a normalized feature vector in `[0, 1]` order:
`[count_norm, density_norm, isi_cv_norm, burst_norm]`.

- `count_norm = count / max(count, 1)` (binary occupancy proxy)
- `density_norm = clamp(density / max_density, 0, 1)`
- `isi_cv_norm = clamp(cv / 2, 0, 1)`
- `burst_norm = clamp(burst_count / max(count, 1), 0, 1)`
"""
function normalized_feature_vector(
    spike_times::AbstractVector{<:Real};
    t_start=nothing,
    t_end=nothing,
    max_density::Real=1000.0,
)::Vector{Float64}
    c = spike_count(spike_times; t_start=t_start, t_end=t_end)
    d = spike_density(spike_times; t_start=t_start, t_end=t_end)
    stats = isi_stats(spike_times)
    b = length(detect_bursts(spike_times))

    count_norm = c > 0 ? 1.0 : 0.0
    density_norm = clamp(d / max_density, 0.0, 1.0)
    isi_cv_norm = clamp(stats.cv / 2.0, 0.0, 1.0)
    burst_norm = clamp(b / max(c, 1), 0.0, 1.0)

    return [count_norm, density_norm, isi_cv_norm, burst_norm]
end
