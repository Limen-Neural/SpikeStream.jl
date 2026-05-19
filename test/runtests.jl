using Test
using SpikeStream

@testset "SpikeStream" begin

    @testset "Package loads" begin
        @test @isdefined(SpikeStream)
        @test SpikeStream isa Module
        @test isdefined(SpikeStream, :spike_count)
        @test isdefined(SpikeStream, :spike_density)
        @test isdefined(SpikeStream, :isi_stats)
        @test isdefined(SpikeStream, :detect_bursts)
        @test isdefined(SpikeStream, :windowed_spike_features)
        @test isdefined(SpikeStream, :normalized_feature_vector)
    end

    @testset "spike_count + spike_density" begin
        spikes = [0.1, 0.2, 0.25, 0.9]
        @test spike_count(spikes) == 4
        @test spike_count(spikes; t_start = 0.15, t_end = 0.3) == 2
        @test spike_density(spikes; t_start = 0.0, t_end = 1.0) == 4.0
        @test spike_density([0.1]) == 0.0

        # partial bounds should be respected
        @test spike_density(spikes; t_start = 0.2) ≈ 3 / (0.9 - 0.2)
        @test spike_density(spikes; t_end = 0.25) ≈ 3 / (0.25 - 0.1)
    end

    @testset "ISI stats" begin
        spikes = [0.1, 0.2, 0.4, 0.7]
        stats = isi_stats(spikes)
        @test stats.mean ≈ 0.2
        @test stats.min ≈ 0.1
        @test stats.max ≈ 0.3
        @test stats.cv ≥ 0

        empty_stats = isi_stats([0.1])
        @test empty_stats.mean == 0.0

        two_spike = isi_stats([0.1, 0.5])
        @test two_spike.mean ≈ 0.4
        @test two_spike.std == 0.0
        @test two_spike.cv == 0.0
    end

    @testset "burst detection" begin
        spikes = [0.0, 0.005, 0.009, 0.1, 0.2]
        bursts = detect_bursts(spikes; max_isi = 0.01, min_spikes = 3)
        @test length(bursts) == 1
        @test first(bursts) == 1:3
    end

    @testset "windowed extraction" begin
        spikes = [0.01, 0.02, 0.06, 0.07]
        feats = windowed_spike_features(
            spikes;
            window_size = 0.05,
            step = 0.05,
            t_start = 0.0,
            t_end = 0.1,
        )
        @test length(feats) == 2
        @test feats[1].count == 2
        @test feats[2].count == 2
        @test all(f -> f.density ≥ 0, feats)

        # auto t_end includes the final spike
        auto_feats = windowed_spike_features([0.0, 0.5, 1.0]; window_size = 0.5, step = 0.5)
        @test sum(f.count for f in auto_feats) == 3
    end

    @testset "normalized vector" begin
        spikes = [0.0, 0.01, 0.02, 0.2]
        vec = normalized_feature_vector(
            spikes;
            t_start = 0.0,
            t_end = 1.0,
            max_density = 10.0,
        )
        @test length(vec) == 4
        @test all(0.0 .≤ vec .≤ 1.0)

        vec_window = normalized_feature_vector(
            spikes;
            t_start = 0.0,
            t_end = 0.03,
            max_density = 100.0,
        )
        @test vec_window[4] ≈ 1 / 3
    end

    @testset "Legacy transitional APIs" begin
        @test compute_hurst([1.0, 2.0, 3.0]) == 0.5
        @test compute_hawkes([100.0]) == 1.0
        @test compute_gbm_surprise([100.0, 101.0]) == 0.0
    end
end
