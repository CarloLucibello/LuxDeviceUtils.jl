module LuxDeviceUtilsMetalExt

using Adapt: Adapt
using GPUArrays: GPUArrays
using LuxDeviceUtils: LuxDeviceUtils, LuxMetalDevice, reset_gpu_device!
using Metal: Metal, MtlArray

__init__() = reset_gpu_device!()

LuxDeviceUtils.__is_loaded(::Union{LuxMetalDevice, Type{<:LuxMetalDevice}}) = true
function LuxDeviceUtils.__is_functional(::Union{LuxMetalDevice, Type{<:LuxMetalDevice}})
    return Metal.functional()
end

# Default RNG
LuxDeviceUtils.default_device_rng(::LuxMetalDevice) = GPUArrays.default_rng(MtlArray)

# Query Device from Array
LuxDeviceUtils.get_device(::MtlArray) = LuxMetalDevice()

# Device Transfer
## To GPU
Adapt.adapt_storage(::LuxMetalDevice, x) = Metal.mtl(x)

end
