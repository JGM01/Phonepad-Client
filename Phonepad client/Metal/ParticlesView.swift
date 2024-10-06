import MetalKit
import SwiftUI

class MetalParticleView: MTKView {
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var startTime: Date

    struct Uniforms {
        var resolution: SIMD2<Float>
        var time: Float
    }

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        startTime = Date()
        super.init(frame: frameRect, device: device)
        self.device = device ?? MTLCreateSystemDefaultDevice()
        self.commandQueue = self.device?.makeCommandQueue()
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        self.framebufferOnly = false
        self.preferredFramesPerSecond = 60
        self.enableSetNeedsDisplay = true
        self.isPaused = false

        setupPipeline()
        setupVertexBuffer()
        setupUniformBuffer()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPipeline() {
        guard let device = device,
              let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            fatalError("Failed to create Metal functions")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        // Set up vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    private func setupVertexBuffer() {
        let vertices: [SIMD2<Float>] = [
            SIMD2(-1, -1),
            SIMD2( 1, -1),
            SIMD2(-1,  1),
            SIMD2( 1,  1)
        ]

        vertexBuffer = device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: [])
    }

    private func setupUniformBuffer() {
        uniformBuffer = device?.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderPassDescriptor = currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let uniformBuffer = uniformBuffer else {
            return
        }

        var uniforms = Uniforms(resolution: SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height)),
                                time: Float(-startTime.timeIntervalSinceNow))
        uniformBuffer.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.stride)

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

struct MetalParticleViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalParticleView {
        MetalParticleView(frame: .zero, device: nil)
    }

    func updateUIView(_ uiView: MetalParticleView, context: Context) {
        uiView.setNeedsDisplay()
    }
}
