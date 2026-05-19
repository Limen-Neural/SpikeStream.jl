<p align="center">
  <img src="docs/logo.png" width="220" alt="Spikenaut">
</p>

<h1 align="center">SpikeStream.jl</h1>
<p align="center">Spike-stream feature extraction for spiking neural systems</p>
<p align="center">
  [![CI](https://github.com/Limen-Neural/SpikeStream.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/Limen-Neural/SpikeStream.jl/actions/workflows/ci.yml)
</p>

---

SpikeStream.jl is focused on feature extraction from spike-event streams.

## Core Features

- `spike_count(spike_times; t_start, t_end)`
- `spike_density(spike_times; t_start, t_end)`
- `isi_stats(spike_times)`
- `detect_bursts(spike_times; max_isi, min_spikes)`
- `windowed_spike_features(spike_times; window_size, step)`
- `normalized_feature_vector(spike_times)`

## Output Ranges

- `spike_count` → integer `>= 0`
- `spike_density` → real `>= 0`
- `isi_stats` → all fields non-negative
- `detect_bursts` → vector of index ranges (possibly empty)
- `windowed_spike_features`:
  - `count >= 0`
  - `density >= 0`
  - `isi_mean >= 0`
  - `isi_cv >= 0`
  - `burst_count >= 0`
- `normalized_feature_vector` → length-4 vector in `[0, 1]`

## Quick Start

```julia
using SpikeStream

spike_times = [0.001, 0.005, 0.009, 0.040, 0.042, 0.044, 0.090]

count = spike_count(spike_times)
density = spike_density(spike_times; t_start=0.0, t_end=0.1)
stats = isi_stats(spike_times)
bursts = detect_bursts(spike_times; max_isi=0.004, min_spikes=3)
windows = windowed_spike_features(spike_times; window_size=0.03, step=0.03)
vec = normalized_feature_vector(spike_times; t_start=0.0, t_end=0.1, max_density=200.0)
```

## Legacy / Transitional APIs

The following market/time-series proxy features remain available temporarily for compatibility:

- `compute_hurst`
- `compute_hawkes`
- `compute_gbm_surprise`

They are transitional and may move to a separate package boundary later.

## Installation

```julia
using Pkg
Pkg.add("SpikeStream")
```

## License

GPL-3.0-or-later
