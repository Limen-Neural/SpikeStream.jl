# SPDX-License-Identifier: MIT OR Apache-2.0

"""
    spike_count(spike_times; t_start=nothing, t_end=nothing) -> Int

Count spikes in `spike_times`, optionally restricted to `[t_start, t_end]`.

`spike_times` should be numeric timestamps in seconds (or any consistent unit).
When no window is provided, all spikes are counted.
"""
function spike_count(
    spike_times::AbstractVector{<:Real};
    t_start = nothing,
    t_end = nothing,
)::Int
    if isnothing(t_start) && isnothing(t_end)
        return length(spike_times)
    end

    start_t = isnothing(t_start) ? -Inf : Float64(t_start)
    end_t = isnothing(t_end) ? Inf : Float64(t_end)
    end_t < start_t && return 0

    times = sort(Float64.(spike_times))
    left = searchsortedfirst(times, start_t)
    right = searchsortedlast(times, end_t)
    return max(0, right - left + 1)
end

"""
    spike_density(spike_times; t_start=nothing, t_end=nothing) -> Float64

Compute spike density as `spike_count / window_duration`.

Returns `0.0` when fewer than 2 spikes are available to infer a duration,
or when the requested window has non-positive duration.
"""
function spike_density(
    spike_times::AbstractVector{<:Real};
    t_start = nothing,
    t_end = nothing,
)::Float64
    length(spike_times) < 2 && return 0.0
    data_min, data_max = extrema(Float64.(spike_times))
    t_min = isnothing(t_start) ? data_min : Float64(t_start)
    t_max = isnothing(t_end) ? data_max : Float64(t_end)

    duration = t_max - t_min
    duration <= 0 && return 0.0

    n = spike_count(spike_times; t_start = t_min, t_end = t_max)
    return n / duration
end

"""
    isi_stats(spike_times) -> NamedTuple

Compute inter-spike-interval statistics.

Returns `(mean, std, min, max, cv)` where CV is coefficient of variation `std/mean`.
All values are non-negative. For fewer than 2 spikes, returns zeros.
"""
function isi_stats(spike_times::AbstractVector{<:Real})
    length(spike_times) < 2 &&
        return (mean = 0.0, std = 0.0, min = 0.0, max = 0.0, cv = 0.0)

    times = sort(Float64.(spike_times))
    return isi_stats_sorted(times)
end

function isi_stats_sorted(sorted_spike_times::AbstractVector{Float64})
    length(sorted_spike_times) < 2 &&
        return (mean = 0.0, std = 0.0, min = 0.0, max = 0.0, cv = 0.0)

    isis = diff(sorted_spike_times)
    μ = mean(isis)
    σ = length(isis) > 1 ? std(isis) : 0.0
    min_isi = minimum(isis)
    max_isi = maximum(isis)
    cv = μ > 0 ? σ / μ : 0.0

    return (mean = μ, std = σ, min = min_isi, max = max_isi, cv = cv)
end

"""
    detect_bursts(spike_times; max_isi=0.02, min_spikes=3) -> Vector{UnitRange{Int}}

Detect bursts as contiguous runs where each inter-spike interval is `<= max_isi`.
Returns index ranges into the sorted spike-time sequence.
"""
function detect_bursts(
    spike_times::AbstractVector{<:Real};
    max_isi::Real = 0.02,
    min_spikes::Int = 3,
)
    n = length(spike_times)
    n < min_spikes && return UnitRange{Int}[]
    times = sort(Float64.(spike_times))
    return detect_bursts_sorted(times; max_isi = max_isi, min_spikes = min_spikes)
end

function detect_bursts_sorted(
    sorted_spike_times::AbstractVector{Float64};
    max_isi::Real = 0.02,
    min_spikes::Int = 3,
)
    n = length(sorted_spike_times)
    n < min_spikes && return UnitRange{Int}[]

    isis = diff(sorted_spike_times)
    bursts = UnitRange{Int}[]
    run_start = 1
    run_len = 1

    for (i, isi) in enumerate(isis)
        if isi <= max_isi
            run_len += 1
        else
            if run_len >= min_spikes
                push!(bursts, run_start:(run_start+run_len-1))
            end
            run_start = i + 1
            run_len = 1
        end
    end

    if run_len >= min_spikes
        push!(bursts, run_start:(run_start+run_len-1))
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
    step::Real = window_size,
    t_start = nothing,
    t_end = nothing,
)
    window_size <= 0 && throw(ArgumentError("window_size must be > 0"))
    step <= 0 && throw(ArgumentError("step must be > 0"))

    times = sort(Float64.(spike_times))

    include_right_edge = false
    if isempty(times)
        base_start = isnothing(t_start) ? 0.0 : Float64(t_start)
        base_end = isnothing(t_end) ? 0.0 : Float64(t_end)
    else
        base_start = isnothing(t_start) ? first(times) : Float64(t_start)
        if isnothing(t_end)
            base_end = nextfloat(last(times))
            include_right_edge = true
        else
            base_end = Float64(t_end)
        end
    end

    base_end < base_start && return NamedTuple[]

    features = NamedTuple[]
    cur = base_start
    left = 1
    right = 0
    n = length(times)

    while cur < base_end
        nxt = min(cur + window_size, base_end)

        while left <= n && times[left] < cur
            left += 1
        end
        right = max(right, left - 1)
        if include_right_edge && nxt == base_end
            while right < n && times[right+1] <= nxt
                right += 1
            end
        else
            while right < n && times[right+1] < nxt
                right += 1
            end
        end

        local_count = max(0, right - left + 1)
        local_times = local_count > 0 ? (@view times[left:right]) : Float64[]

        d = nxt > cur ? local_count / (nxt - cur) : 0.0
        stats = isi_stats_sorted(local_times)
        b = length(detect_bursts_sorted(local_times))

        push!(
            features,
            (
                t_start = cur,
                t_end = nxt,
                count = local_count,
                density = d,
                isi_mean = stats.mean,
                isi_cv = stats.cv,
                burst_count = b,
            ),
        )

        cur += step
    end

    return features
end

"""
    normalized_feature_vector(spike_times; t_start=nothing, t_end=nothing, max_density=1000.0) -> Vector{Float64}

Build a normalized feature vector in `[0, 1]` order:
`[count_norm, density_norm, isi_cv_norm, burst_norm]`.
"""
function normalized_feature_vector(
    spike_times::AbstractVector{<:Real};
    t_start = nothing,
    t_end = nothing,
    max_density::Real = 1000.0,
)::Vector{Float64}
    sorted_times = sort(Float64.(spike_times))
    start_t = isnothing(t_start) ? -Inf : Float64(t_start)
    end_t = isnothing(t_end) ? Inf : Float64(t_end)
    left = searchsortedfirst(sorted_times, start_t)
    right = searchsortedlast(sorted_times, end_t)
    window_times = left <= right ? sorted_times[left:right] : Float64[]

    c = spike_count(spike_times; t_start = t_start, t_end = t_end)
    d = spike_density(spike_times; t_start = t_start, t_end = t_end)
    stats = isi_stats_sorted(window_times)
    b = length(detect_bursts_sorted(window_times))

    count_norm = c > 0 ? 1.0 : 0.0
    density_norm = clamp(d / max_density, 0.0, 1.0)
    isi_cv_norm = clamp(stats.cv / 2.0, 0.0, 1.0)
    burst_norm = clamp(b / max(c, 1), 0.0, 1.0)

    return [count_norm, density_norm, isi_cv_norm, burst_norm]
end
