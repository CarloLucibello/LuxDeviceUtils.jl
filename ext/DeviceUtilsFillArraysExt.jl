module DeviceUtilsFillArraysExt

using Adapt: Adapt
using FillArrays: FillArrays, AbstractFill
using DeviceUtils: DeviceUtils, CPUDevice, AbstractDevice

Adapt.adapt_structure(::CPUDevice, x::AbstractFill) = x
Adapt.adapt_structure(to::AbstractDevice, x::AbstractFill) = Adapt.adapt(to, collect(x))

end
