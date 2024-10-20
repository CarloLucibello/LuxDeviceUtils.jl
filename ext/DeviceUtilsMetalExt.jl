module DeviceUtilsMetalExt

using Adapt: Adapt
using GPUArrays: GPUArrays
using DeviceUtils: DeviceUtils, MetalDevice, reset_gpu_device!
using Metal: Metal, MtlArray

__init__() = reset_gpu_device!()

DeviceUtils.loaded(::Union{MetalDevice, Type{<:MetalDevice}}) = true
function DeviceUtils.functional(::Union{MetalDevice, Type{<:MetalDevice}})
    return Metal.functional()
end

# Default RNG
DeviceUtils.default_device_rng(::MetalDevice) = GPUArrays.default_rng(MtlArray)

# Query Device from Array
DeviceUtils._get_device(::MtlArray) = MetalDevice()

DeviceUtils._get_device_type(::MtlArray) = MetalDevice

# Device Transfer
## To GPU
Adapt.adapt_storage(::MetalDevice, x::AbstractArray) = Metal.mtl(x)

end
