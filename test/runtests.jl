using Test
using SpikeStream
using Statistics

@testset "SpikeStream" begin

    @testset "Package loads" begin
        @test @isdefined(SpikeStream)
        @test SpikeStream isa Module
        @test isdefined(SpikeStream, :compute_hurst)
        @test isdefined(SpikeStream, :compute_hawkes)
        @test isdefined(SpikeStream, :compute_gbm_surprise)
    end

    @testset "compute_hurst" begin
        # Short series → fallback 0.5
        @test compute_hurst([1.0, 2.0, 3.0]) == 0.5

        # Constant series → fallback 0.5 (zero variance)
        @test compute_hurst(fill(100.0, 50)) == 0.5

        # Random walk: H close to 0.5 (just check range)
        rw = cumsum(randn(200))
        h = compute_hurst(rw)
        @test 0.2 ≤ h ≤ 0.8

        # Trending series: increasing H
        trend = collect(1.0:200.0)
        h_trend = compute_hurst(trend)
        @test h_trend ≥ 0.2   # must be valid
    end

    @testset "compute_hawkes" begin
        # Short series → fallback 1.0
        @test compute_hawkes([100.0]) == 1.0

        # Flat series → low intensity (≈ 1.0 since mean(diffs)≈0)
        flat = fill(100.0, 50)
        λ_flat = compute_hawkes(flat)
        @test λ_flat ≈ 1.0

        # Very volatile series → high intensity
        volatile = [100.0, 200.0, 100.0, 200.0, 100.0]
        λ_vol = compute_hawkes(volatile)
        @test λ_vol > 1.5

        # Output always in [0.5, 3.0]
        @test 0.5 ≤ λ_vol ≤ 3.0
    end

    @testset "compute_gbm_surprise" begin
        # Short series → 0.0
        @test compute_gbm_surprise([100.0, 101.0]) == 0.0

        # Constant signal → 0.0 (zero volatility)
        @test compute_gbm_surprise(fill(100.0, 10)) == 0.0

        # Trending up, last step larger → positive surprise
        signal_up = [100.0, 101.0, 102.0, 103.0, 110.0]
        @test compute_gbm_surprise(signal_up) > 0.0

        # Output always in [-3.0, 3.0]
        signal_vals = 100.0 .+ cumsum(randn(50))
        z = compute_gbm_surprise(signal_vals)
        @test -3.0 ≤ z ≤ 3.0
    end

end
