# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

- `compute_hurst`, `compute_hawkes`, and `compute_gbm_surprise` transitional
  time-series proxy functions; these now belong to `kinetic-signals`
  ([#22](https://github.com/Limen-Neural/SpikeStream.jl/pull/22)).

## [0.1.0] - 2026-03-23

### Added

- Initial release with spike-stream feature extraction functions:
  `spike_count`, `spike_density`, `isi_stats`, `detect_bursts`,
  `windowed_spike_features`, and `normalized_feature_vector`.
