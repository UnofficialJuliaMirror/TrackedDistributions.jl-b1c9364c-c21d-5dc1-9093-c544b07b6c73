@testset "DiagonalNormal API: Reals" begin
    dn = TMVDiagonalNormal([0, 0], [1, 1])
    dn = TMVDiagonalNormal([0., 0.], [1., 1.])
    @test length(dn) == 2
    @test size(dn) == (2,)
    @test eltype(dn) == Float64
    @test mean(dn) == [0, 0]
    @test var(dn) == exp(2) * [1, 1]
    @test cov(dn) == exp(2) * eye(2)
    @test cor(dn) == eye(2)
    mv = convert(Distributions.MvNormal, dn)
    @test mean(mv) == [0.0, 0.0]
    @test cov(mv) ≈ exp(2) * eye(2)
    @test size(rand(dn, 3)) == (2, 3)
    rng = MersenneTwister(23)
    rng2 = MersenneTwister(23)
    @test rand(rng, dn, 3) ≈  rand(rng2, mv, 3)

    rng = MersenneTwister(23)
    @test size(rand(rng, dn)) == (2,)
    # Gaussian evaluated at peak
    max_gaussian = prod(1./sqrt.(2 * pi * var(dn)))
    # gaussian evaluated at [1, 1]
    value = max_gaussian * prod(exp.(- [1, 1]/(2 * var(dn)[1])))
    expected_vec = [max_gaussian, value]
    @test pdf(dn, [0, 0]) == max_gaussian
    @test pdf(dn, [[0 1]; [0 1]]) == expected_vec
    @test logpdf(dn, [0, 0]) == log(max_gaussian)
    @test logpdf(dn, [[0 1]; [0 1]]) == log.(expected_vec)
    @test entropy(dn) == entropy(mv)
    @test loglikelihood(dn, [[0 1]; [0 1]]) == sum(log.(expected_vec))

    @test_throws AssertionError TMVDiagonalNormal(zeros(2,2), ones(2,2))
    @test typeof(TMVDiagonalNormal(ones(2)[:, :], ones(2)[:, :])) == typeof(TMVDiagonalNormal(ones(2), ones(2)))
end

@testset "DiagonalNormal API: TrackedArray" begin
    Tracked = Flux.Tracker.TrackedArray
    dn = TMVDiagonalNormal(Tracked([0., 0]), Tracked([1., 1]))
    @test length(dn) == 2
    @test size(dn) == (2,)
    @test eltype(dn) == Float64
    @test mean(dn) == Tracked([0, 0])
    @test isa(mean(dn), Tracked)
    @test var(dn) == exp(2) * Tracked([1, 1])
    @test isa(var(dn), Tracked)
    @test cov(dn) == Tracked(exp(2) * eye(2))
    @test isa(cov(dn), Tracked)
    @test cor(dn) == eye(2)
    rng = MersenneTwister(23)
    @test size(rand(rng, dn)) == (2,)
    @test logpdf(dn, [0, 0]) == logpdf(MvNormal(zeros(2), exp.(ones(2))), zeros(2))
    @test_throws MethodError (logpdf(dn, [[0 1]; [0 1]]))

    @test pdf(dn, [0, 0]) == pdf(MvNormal(zeros(2), exp.(ones(2))), zeros(2))
    @test_throws MethodError pdf(dn, [[0 1]; [0 1]])
    @test_throws MethodError convert(Distributions.MvNormal, dn)
    @test_throws ErrorException rand(rng, dn, 1)
    @test_throws ErrorException rand(dn, 3)

    @test_throws MethodError entropy(dn)
    @test_nowarn loglikelihood(dn, [[0 1]; [0 1]])

    dn = TMVDiagonalNormal(Tracked([0, 0]), Tracked([1, 1]))
    rng = MersenneTwister(23)
    @test size(rand(rng, dn)) == (2,)

    # Check comparison with previous implementations:
    rng1 = MersenneTwister(1)
    rng2 = MersenneTwister(1)
    @test TrackedDistributions.sample(rng1, dn)==rand(rng2, dn)
    x = rand(2)
    @test TrackedDistributions.log_pdf(dn, x) == logpdf(dn, x)
end

@testset "DiagonalNormal API: Univariate" begin
    # There are no univariates! Convert to multivariate. Only works for reals.
    @test typeof(TMVDiagonalNormal([0], [1]))==typeof(TMVDiagonalNormal(0, 1))
end


@testset "DiagonalNormal API: Non-trivial cases" begin
    # Test log_pdf for D=1 case; x=0, μ=0, logσ=1
    DN = TMVDiagonalNormal([0.0], [1.])
    logP = logpdf(DN, [0.])
    @test logP ≈ -0.5*(2 + log(2*pi))

    # Test log_pdf D=3 case; x=0, μ=0, logσ=1
    DN = TMVDiagonalNormal(zeros(3), ones(3))
    X = zeros(1,3)
    logP = logpdf(DN, X[1,:])
    @test logP ≈ -0.5*(6 + 3*log(2*pi))

    # Test if case N=3,D=2 where we pass in x = column vec
    rng = MersenneTwister(9000)
    N = 3
    D = 2
    x = rand(rng, (N, D))
    DN = TMVDiagonalNormal(zeros(D), ones(D))
    logP = logpdf(DN, x[3,:])
    @test typeof(logP)==Float64
end
