import Metal

/// What the on-device language model needs from this iPhone's GPU.
///
/// MLX compiles its kernels for bfloat16, which Metal supports from the Apple6 GPU family
/// (A14, iPhone 12) onwards. On an A12 or A13 the bfloat16 kernel fails to compile inside
/// MLX — a trap in a debug build and a thrown load error in a release build — so the model
/// is never offered, downloaded or loaded on those devices.
nonisolated enum OnDeviceCapability {

    static var supportsMetalLanguageModels: Bool {
        MTLCreateSystemDefaultDevice()?.supportsFamily(.apple6) ?? false
    }
}
