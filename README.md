<p align="center">
  <img src="docs/logo.png" width="220" alt="Spikenaut">
</p>

<h1 align="center">SpikeStream.jl</h1>
<p align="center">Streaming time-series feature extraction for spiking neural networks</p>

<p align="center">
  <img src="https://img.shields.io/badge/language-Julia-9558B2" alt="Julia">
  <img src="https://img.shields.io/badge/license-GPL--3.0-orange" alt="GPL-3.0">
</p>

---

Streaming signal processing primitives for feeding time-series data into SNNs:
Hurst exponent, Hawkes self-exciting intensity, GBM surprise residuals — all optimized
for real-time O(1)-update streaming with SNN-compatible output normalization.

## Features

- `compute_hurst(signal_values)` — Hurst exponent via R/S analysis → `[0.2, 0.8]`
- `compute_hawkes(signal_values)` — Hawkes self-exciting intensity → `[0.5, 3.0]`
- `compute_gbm_surprise(signal_values)` — GBM surprise Z-score → `[-3.0, 3.0]`
- Graceful fallbacks on short windows (returns neutral values, never errors)
- Pure Julia stdlib — no external dependencies

## Installation

```julia
using Pkg
Pkg.add("SpikeStream")
```

## Quick Start

```julia
using SpikeStream

signal_values = [100.0, 101.2, 99.8, 102.5, 101.0, 103.2]

h  = compute_hurst(signal_values)           # 0.5 = random walk, >0.5 = trending
λ  = compute_hawkes(signal_values)          # >1.0 = clustering, self-exciting
z  = compute_gbm_surprise(signal_values)    # |z| > 2 = anomalous spike

# Feed directly into SNN encoder
spikes = encode_for_snn([h, λ, z])
```

## Signal Interpretations

| Feature | Range | Interpretation |
|---------|-------|----------------|
| Hurst | `[0.2, 0.8]` | `> 0.5` trending, `< 0.5` mean-reverting |
| Hawkes λ | `[0.5, 3.0]` | `> 1.0` self-exciting (event clustering) |
| GBM surprise | `[-3.0, 3.0]` | Z-score deviation from local GBM expectation |

## Mathematical Foundations

**Hurst Exponent (R/S Analysis)**
```
H = log(R/S) / log(n)    where R = range, S = std dev
```
*Hurst (1951) — long-range dependence in time series*

**Hawkes Process Intensity**
```
λ(t) = μ + Σ_{t_i < t} α · exp(-β(t - t_i))
```
*Hawkes (1971) — self-exciting point processes*

**GBM Surprise Z-Score**
```
dS = μS dt + σS dW  →  z = (log(S_t/S_{t-1}) - μ_hat) / σ_hat
```
*Stochastic diffusion processes; Itô calculus*

## Signal Processing Pipeline

Streaming feature extraction pipeline for neuromorphic systems. Works with any numeric time series — hardware telemetry, sensor data, or other signal sources.

## Part of the Spikenaut Ecosystem

| Library | Purpose |
|---------|---------|
| [SpikenautLSM.jl](https://github.com/rmems/SpikenautLSM.jl) | Sparse LSM reservoir |
| [SpikenautNero.jl](https://github.com/rmems/SpikenautNero.jl) | Relevance scoring |
| [spikenaut-encoder](https://github.com/rmems/spikenaut-encoder) | Rust spike encoding |

## License

GPL-3.0-or-later
