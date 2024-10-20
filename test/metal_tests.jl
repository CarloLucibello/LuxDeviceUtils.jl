using DeviceUtils, Random, Test
using ArrayInterface: parameterless_type

@testset "CPU Fallback" begin
    @test !DeviceUtils.functional(MetalDevice)
    @test cpu_device() isa CPUDevice
    @test gpu_device() isa CPUDevice
    @test_throws DeviceUtils.DeviceSelectionException gpu_device(;
        force_gpu_usage=true)
    @test_throws Exception default_device_rng(MetalDevice())
end

using Metal

@testset "Loaded Trigger Package" begin
    @test DeviceUtils.GPU_DEVICE[] === nothing

    if DeviceUtils.functional(MetalDevice)
        @info "Metal is functional"
        @test gpu_device() isa MetalDevice
        @test gpu_device(; force_gpu_usage=true) isa MetalDevice
    else
        @info "Metal is NOT functional"
        @test gpu_device() isa MetalDevice
        @test_throws DeviceUtils.DeviceSelectionException gpu_device(;
            force_gpu_usage=true)
    end
    @test DeviceUtils.GPU_DEVICE[] !== nothing
end

using FillArrays, Zygote  # Extensions

@testset "Data Transfer" begin
    ps = (a=(c=zeros(10, 1), d=1), b=ones(10, 1), e=:c,
        d="string", mixed=[2.0f0, 3.0, ones(2, 3)],  # mixed array types
        range=1:10,
        rng_default=Random.default_rng(), rng=MersenneTwister(),
        one_elem=Zygote.OneElement(2.0f0, (2, 3), (1:3, 1:4)), farray=Fill(1.0f0, (2, 3)))

    device = gpu_device()
    aType = DeviceUtils.functional(MetalDevice) ? MtlArray : Array
    rngType = DeviceUtils.functional(MetalDevice) ? Metal.GPUArrays.RNG :
              Random.AbstractRNG

    ps_xpu = ps |> device
    @test get_device(ps_xpu) isa MetalDevice
    @test get_device_type(ps_xpu) <: MetalDevice
    @test ps_xpu.a.c isa aType
    @test ps_xpu.b isa aType
    @test ps_xpu.a.d == ps.a.d
    @test ps_xpu.mixed isa Vector
    @test ps_xpu.mixed[1] isa Float32
    @test ps_xpu.mixed[2] isa Float64
    @test ps_xpu.mixed[3] isa aType
    @test ps_xpu.range isa aType
    @test ps_xpu.e == ps.e
    @test ps_xpu.d == ps.d
    @test ps_xpu.rng_default isa rngType
    @test ps_xpu.rng == ps.rng

    if DeviceUtils.functional(MetalDevice)
        @test ps_xpu.one_elem isa MtlArray
        @test ps_xpu.farray isa MtlArray
    else
        @test ps_xpu.one_elem isa Zygote.OneElement
        @test ps_xpu.farray isa Fill
    end

    ps_cpu = ps_xpu |> cpu_device()
    @test get_device(ps_cpu) isa CPUDevice
    @test get_device_type(ps_cpu) <: CPUDevice
    @test ps_cpu.a.c isa Array
    @test ps_cpu.b isa Array
    @test ps_cpu.a.c == ps.a.c
    @test ps_cpu.b == ps.b
    @test ps_cpu.a.d == ps.a.d
    @test ps_cpu.mixed isa Vector
    @test ps_cpu.mixed[1] isa Float32
    @test ps_cpu.mixed[2] isa Float64
    @test ps_cpu.mixed[3] isa Array
    @test ps_cpu.range isa Array
    @test ps_cpu.e == ps.e
    @test ps_cpu.d == ps.d
    @test ps_cpu.rng_default isa Random.TaskLocalRNG
    @test ps_cpu.rng == ps.rng

    if DeviceUtils.functional(MetalDevice)
        @test ps_cpu.one_elem isa Array
        @test ps_cpu.farray isa Array
    else
        @test ps_cpu.one_elem isa Zygote.OneElement
        @test ps_cpu.farray isa Fill
    end

    ps_mixed = (; a=rand(2), b=device(rand(2)))
    @test_throws ArgumentError get_device(ps_mixed)
    @test_throws ArgumentError get_device_type(ps_mixed)

    @testset "get_device_type compile constant" begin
        x = rand(10, 10) |> device
        ps = (; weight=x, bias=x, d=(x, x))

        return_val(x) = Val(get_device_type(x))  # If it is a compile time constant then type inference will work
        @test @inferred(return_val(ps)) isa Val{parameterless_type(typeof(device))}

        return_val2(x) = Val(get_device(x))
        @test @inferred(return_val2(ps)) isa Val{get_device(x)}
    end
end

@testset "Wrapper Arrays" begin
    if DeviceUtils.functional(MetalDevice)
        x = rand(Float32, 10, 10) |> MetalDevice()
        @test get_device(x) isa MetalDevice
        @test get_device_type(x) <: MetalDevice
        x_view = view(x, 1:5, 1:5)
        @test get_device(x_view) isa MetalDevice
        @test get_device_type(x_view) <: MetalDevice
    end
end

@testset "setdevice!" begin
    if DeviceUtils.functional(MetalDevice)
        @test_logs (:warn,
            "Support for Multi Device Metal hasn't been implemented yet. Ignoring the device setting.") DeviceUtils.set_device!(
            MetalDevice, nothing, 1)
    end
end
