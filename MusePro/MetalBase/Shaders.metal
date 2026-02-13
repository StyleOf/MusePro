#include <metal_stdlib>
using namespace metal;

//======================================
// Types
//======================================

struct Vertex {
    float4 position [[position]];
    float2 text_coord;
};

struct GrainVertex {
    float4 position [[position]];
    float2 brush_text_coord;
    float2 grain_text_coord;

};

struct Uniforms {
    float4x4 scaleMatrix;
};

struct Point {
    float4 position [[position]];
    float4 color;
    float angle;
    float size [[point_size]];
};

struct Transform {
    float2 offset;
    float scale;
};

struct Sizes {
    float2 brushSize;
    float2 textureSize;
    float textureScale;
    float2 textureOffset;
    float4 color;
};

struct Color {
    float4 color;
};

struct ControlData {
    int useInverseMask; // 0 for direct mask use, 1 for inverse mask use
};

struct LayerRenderData {
    float opacity;
};

//======================================
// Utils
//======================================

// Adjust these functions to work with pixel coordinates
static void atomic_uint_exchange_if_less_than(volatile device atomic_uint* current, uint candidate) {
    uint expected;
    do {
        expected = atomic_load_explicit(current, memory_order_relaxed);
    } while (candidate < expected && !atomic_compare_exchange_weak_explicit(current, &expected, candidate, memory_order_relaxed, memory_order_relaxed));
}

static void atomic_uint_exchange_if_greater_than(volatile device atomic_uint* current, uint candidate) {
    uint expected;
    do {
        expected = atomic_load_explicit(current, memory_order_relaxed);
    } while (candidate > expected && !atomic_compare_exchange_weak_explicit(current, &expected, candidate, memory_order_relaxed, memory_order_relaxed));
}

kernel void computeBounds(texture2d<float, access::read> texture [[texture(0)]],
                                                device atomic_uint* boundsBuffer [[buffer(0)]], // Buffer to hold minX, minY, maxX, maxY
                                                uint2 gid [[thread_position_in_grid]]) {
    float alpha = texture.read(gid).a;
    if (alpha > 0.0) { // Check for non-transparent pixel
        // Update bounds
        atomic_uint_exchange_if_less_than(&boundsBuffer[0], gid.x); // minX
        atomic_uint_exchange_if_greater_than(&boundsBuffer[1], gid.x); // maxX
        atomic_uint_exchange_if_less_than(&boundsBuffer[2], gid.y); // minY
        atomic_uint_exchange_if_greater_than(&boundsBuffer[3], gid.y); // maxY
    }
}

kernel void computeBoundsWithMask(texture2d<float, access::read> texture [[texture(0)]],
                          texture2d<float, access::read> mask [[texture(1)]],
                          device atomic_uint* boundsBuffer [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]]) {

    float textureAlpha = texture.read(gid).a;
    float maskAlpha = mask.read(gid).r;

    float combinedAlpha = textureAlpha * maskAlpha;

    if (combinedAlpha > 0.0) {
        atomic_uint_exchange_if_less_than(&boundsBuffer[0], gid.x); // minX
        atomic_uint_exchange_if_greater_than(&boundsBuffer[1], gid.x); // maxX
        atomic_uint_exchange_if_less_than(&boundsBuffer[2], gid.y); // minY
        atomic_uint_exchange_if_greater_than(&boundsBuffer[3], gid.y); // maxY
    }
}

kernel void copyTextureWithMask(texture2d<float, access::read> sourceTexture [[texture(0)]],
                                texture2d<float, access::read> maskTexture [[texture(1)]],
                                texture2d<float, access::write> destinationTexture [[texture(2)]],
                                constant ControlData& controlData [[buffer(0)]],
                                uint2 gid [[thread_position_in_grid]]) {
  
    float4 sourcePixel = sourceTexture.read(gid);
    float maskAlpha = maskTexture.read(gid).r;
    
    if (controlData.useInverseMask == 1) {
           maskAlpha = 1.0 - maskAlpha;
       }
    
    sourcePixel *= maskAlpha;
    
    destinationTexture.write(sourcePixel, gid);
}

float2 transformPointCoord(float2 pointCoord, float a, float2 anchor) {
    float2 point20 = pointCoord - anchor;
    float x = point20.x * fast::cos(a) - point20.y * fast::sin(a);
    float y = point20.x * fast::sin(a) + point20.y * fast::cos(a);
    return float2(x, y) + anchor;
}

//======================================
// Render Target Shaders
//======================================
vertex Vertex vertex_render_target(constant Vertex *vertices [[ buffer(0) ]],
                                   constant Uniforms &uniforms [[ buffer(1) ]],
                                   uint vid [[vertex_id]])
{
    Vertex out = vertices[vid];
    out.position = uniforms.scaleMatrix * out.position;// * in.position;
    return out;
};

fragment float4 fragment_render_target(Vertex vertex_data [[ stage_in ]],
                                       constant LayerRenderData& layerData [[buffer(0)]],
                                       texture2d<float> tex2d [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, vertex_data.text_coord));
    color *= layerData.opacity;
    return color;
};

fragment float4 clear_fragment_render_target(Vertex vertex_data [[ stage_in ]])
{
    return float4(0,0,0,0);
};

//======================================
// Printer Shaders
//======================================
vertex Vertex printer_vertex(constant Vertex *vertices [[ buffer(0) ]],
                                  constant Uniforms &uniforms [[ buffer(1) ]],
                                  constant Transform &transform [[ buffer(2) ]],
                                  uint vid [[ vertex_id ]])
{
    Vertex out = vertices[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);// * in.position;
    return out;
};

fragment float4 printer_fragment(Vertex vertex_data [[ stage_in ]],
                                       texture2d<float> tex2d [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, vertex_data.text_coord));
    return color;
};

fragment float4 color_printer_fragment(Vertex vertex_data [[ stage_in ]],
                                             constant Color &color [[ buffer(0) ]])
{
    return color.color;
};

//======================================
// Point Shaders
//======================================
vertex Point brush_vertex(constant Point *points [[ buffer(0) ]],
                               constant Uniforms &uniforms [[ buffer(1) ]],
                               constant Transform &transform [[ buffer(2) ]],
                               uint vid [[ vertex_id ]])
{
    Point out = points[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);// * in.position;
    out.size = out.size * scale;
    return out;
};

fragment float4 brush_fragment(Point point_data [[ stage_in ]],
                                           texture2d<float> brushTexture [[ texture(0) ]],
                                           float2 pointCoord [[ point_coord ]],
                                           sampler brushSampler [[ sampler(0) ]])
{
    float2 text_coord = transformPointCoord(pointCoord, point_data.angle, float2(0.5));
    float brushValue = brushTexture.sample(brushSampler, text_coord).r;
    return float4(1, 1, 1, brushValue * point_data.color.a);
}

fragment float4 brush_fragment_without_texture(Point point_data [[ stage_in ]],
                                                    float2 pointCoord  [[ point_coord ]])
{
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return point_data.color;
}

//======================================
// Grain Shaders
//======================================
// Add parameters for scale and offset in the vertex function
vertex GrainVertex grain_vertex(uint vid [[vertex_id]],
                           constant Sizes &sizes [[ buffer(0) ]]) {
    float4 positions[6] = {
        float4(-1.0, -1.0, 0.0, 1.0),
        float4(-1.0,  1.0, 0.0, 1.0),
        float4( 1.0, -1.0, 0.0, 1.0),
        float4(-1.0,  1.0, 0.0, 1.0),
        float4( 1.0,  1.0, 0.0, 1.0),
        float4( 1.0, -1.0, 0.0, 1.0)
    };
    
    float2 brushTexCoords[6] = {
        float2(0.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0),
    };
    
    float2 grainTexCoords[6] = {
        float2(0.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(1.0, 1.0),
    };

    // Apply scale and offset to texture coordinates
    for (int i = 0; i < 6; ++i) {
        grainTexCoords[i] = (grainTexCoords[i] / sizes.textureScale) + sizes.textureOffset;
    }

    GrainVertex out;
    out.position = positions[vid];
    out.brush_text_coord = brushTexCoords[vid];
    out.grain_text_coord = grainTexCoords[vid];

    return out;
}


fragment float4 grain_fragment(GrainVertex in [[ stage_in ]],
                                           constant Sizes &sizes [[ buffer(0) ]],
                                           texture2d<float> canvasTexture [[ texture(0) ]],
                                            texture2d<float> offscreenTexture [[ texture(1) ]],
                                           sampler canvasSampler [[ sampler(0) ]])
{
    float brushValue = offscreenTexture.sample(canvasSampler, in.brush_text_coord).a;
    float canvasValue = canvasTexture.sample(canvasSampler, in.grain_text_coord).r;
    return float4(sizes.color.rgb, sizes.color.a * canvasValue * brushValue);
}


//======================================
// Selection Shaders
//======================================
vertex Point selection_vertex(constant Point *points [[ buffer(0) ]],
                              constant Uniforms &uniforms [[ buffer(1) ]],
                              constant Transform &transform [[ buffer(2) ]],
                              uint vid [[ vertex_id ]])
{
    Point out = points[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);// * in.position;
    out.size = out.size * scale;
    return out;
};

fragment float4 selection_fragment(Point point_data [[ stage_in ]],
                                   constant float& time [[ buffer(0) ]],
                                   constant Uniforms &uniforms [[ buffer(1) ]], // Ensure you pass the uniforms to the fragment shader
                                   texture2d<float> brushTexture [[ texture(0) ]],
                                   float2 pointCoord [[ point_coord ]],
                                   sampler brushSampler [[ sampler(0) ]])
{
    // Calculate the phase of the marching ants based on time and position along the line.
    // This is a simple example; you may need to adjust it based on your polyline representation and desired effect.
    float dashLength = 10.0; // Length of dashes, adjust as needed.
    float speed = 5.0; // Speed of animation.
    float phase = fract(time * speed + point_data.position.x / dashLength);
    bool isAnt = phase < 0.5;
    
    // Sample the brush texture as before.
    float brushValue = brushTexture.sample(brushSampler, pointCoord).r;
    
    // Use the 'isAnt' variable to modulate the alpha value or color for the marching ants effect.
    float _ = isAnt ? brushValue * point_data.color.a : 0.0;
    
    return float4(1, 1, 1, 1); // Adjust color as needed for your application.
}
