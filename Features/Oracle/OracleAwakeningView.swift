import UIKit
import MetalKit
import simd

private struct AwakeningUniforms {
    var colorA: SIMD4<Float>
    var colorB: SIMD4<Float>
    var resolution: SIMD2<Float>
    var progress: Float
    var time: Float
    var reduceMotion: Float
    var intensity: Float
}

/// Full-screen Metal "awakening" visual driven by real download progress: a
/// domain-warped nebula-portal that ignites from the center as the model arrives,
/// tinted to the consulting deity's colors. Foreground-only (Metal command buffers
/// must not ride into the background), reduce-motion aware, thermally throttled.
///
/// Returns `nil` from the initializer when Metal is unavailable (Simulator / no GPU)
/// so callers can fall back to `PapyrusLoadingView`.
final class OracleAwakeningView: MTKView {

    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState

    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var displayedProgress: Float = 0
    private var targetProgress: Float = 0
    private var colorA = SIMD4<Float>(0.10, 0.07, 0.05, 1)
    private var colorB = SIMD4<Float>(212.0/255, 175.0/255, 55.0/255, 1)
    private var intensity: Float = 1

    init?(deityColor: UIColor?) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertexFn = library.makeFunction(name: "awakening_vertex"),
              let fragmentFn = library.makeFunction(name: "awakening_fragment") else {
            return nil
        }
        self.commandQueue = queue

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFn
        descriptor.fragmentFunction = fragmentFn
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else { return nil }
        self.pipeline = state

        super.init(frame: .zero, device: device)

        colorPixelFormat = .bgra8Unorm
        framebufferOnly = true
        clearColor = MTLClearColor(red: 0.06, green: 0.05, blue: 0.04, alpha: 1)
        preferredFramesPerSecond = 30
        isPaused = false
        enableSetNeedsDisplay = false
        delegate = self
        isOpaque = true
        if let deityColor { setDeity(color: deityColor) }
        applyThermalState()

        NotificationCenter.default.addObserver(
            self, selector: #selector(applyThermalState),
            name: ProcessInfo.thermalStateDidChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(pauseRendering),
            name: UIApplication.willResignActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(resumeRendering),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public

    /// Monotonic — the portal never visually recedes even if a transient progress dip arrives.
    func update(progress: Float) {
        targetProgress = max(targetProgress, min(max(progress, 0), 1))
    }

    func setDeity(color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        colorB = SIMD4<Float>(Float(r), Float(g), Float(b), 1)
        colorA = SIMD4<Float>(Float(r) * 0.18, Float(g) * 0.14, Float(b) * 0.12, 1)
    }

    @objc func pauseRendering() { isPaused = true }
    @objc func resumeRendering() { isPaused = false }

    @objc private func applyThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .serious: preferredFramesPerSecond = 20; intensity = 0.9
        case .critical: preferredFramesPerSecond = 12; intensity = 0.8
        default: preferredFramesPerSecond = 30; intensity = 1
        }
    }

    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }
}

extension OracleAwakeningView: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        displayedProgress += (targetProgress - displayedProgress) * 0.08
        if abs(targetProgress - displayedProgress) < 0.001 { displayedProgress = targetProgress }

        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        let scale = Float(window?.screen.scale ?? 2)
        var uniforms = AwakeningUniforms(
            colorA: colorA,
            colorB: colorB,
            resolution: SIMD2<Float>(Float(bounds.width) * scale, Float(bounds.height) * scale),
            progress: displayedProgress,
            time: reduceMotion ? 0 : Float(CACurrentMediaTime() - startTime),
            reduceMotion: reduceMotion ? 1 : 0,
            intensity: intensity
        )

        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<AwakeningUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
