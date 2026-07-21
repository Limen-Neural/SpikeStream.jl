# SPDX-License-Identifier: MIT OR Apache-2.0

"""
    SpikeStream

Spike-stream feature extraction primitives for spiking neural systems.

Primary package boundary:
- `spike_count` — spike count in full stream or a time window
- `spike_density` — spikes per unit time
- `isi_stats` — inter-spike interval summary statistics
- `detect_bursts` — burst detection from short ISIs
- `windowed_spike_features` — rolling/windowed extraction
- `normalized_feature_vector` — normalized `[0, 1]` feature vector output

"""
module SpikeStream

using Statistics

include("spike_features.jl")

export spike_count, spike_density, isi_stats, detect_bursts
export windowed_spike_features, normalized_feature_vector

end # module
