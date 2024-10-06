#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float time;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.uv = in.position * 0.5 + 0.5;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 center = float2(0.5, 0.5);
    float time = uniforms.time;
    
    // Calculate distance from center
    float dist = distance(uv, center);
    
    // Create pulsing effect
    float pulse = sin(time * 2.0) * 0.5 + 0.5;
    
    // Create particle field
    float particles = 0.0;
    for (int i = 0; i < 100; i++) {
        float2 particle = float2(fract(sin(float(i) * 789.32) * 43758.5453),
                                 fract(cos(float(i) * 123.45) * 28947.1234));
        particle = particle * 2.0 - 1.0; // Map to [-1, 1]
        
        float particleDist = length(uv - (particle * 0.5 + 0.5));
        particles += smoothstep(0.02 * (1.0 + pulse * 0.5), 0.0, particleDist);
    }
    
    // Make particle field denser near center
    particles *= smoothstep(0.5, 0.0, dist);
    
    // Create glowing effect
    float3 color = float3(0.1, 0.4, 0.8) * particles;
    color += float3(0.1, 0.2, 0.3) * (1.0 - dist) * pulse;
    
    return float4(color, 1.0);
}
