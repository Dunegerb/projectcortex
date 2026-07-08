#include <metal_stdlib>
using namespace metal;

static float cortexHash(float2 point, float seed) {
    return fract(sin(dot(point, float2(127.1, 311.7)) + seed * 17.17) * 43758.5453123);
}

static float cortexSmoothNoise(float2 point, float seed) {
    float2 cell = floor(point);
    float2 local = fract(point);
    float2 curve = local * local * local * (local * (local * 6.0 - 15.0) + 10.0);

    float n00 = cortexHash(cell, seed);
    float n10 = cortexHash(cell + float2(1.0, 0.0), seed);
    float n01 = cortexHash(cell + float2(0.0, 1.0), seed);
    float n11 = cortexHash(cell + float2(1.0, 1.0), seed);

    float lower = mix(n00, n10, curve.x);
    float upper = mix(n01, n11, curve.x);
    return mix(lower, upper, curve.y);
}

/// Native equivalent of the SVG feTurbulence + feDisplacementMap lens warp.
/// `position` arrives in screen points, so it is converted back to the 739 ×
/// 1600 design coordinate system before sampling the approved frequencies.
[[ stitchable ]] float2 cortexLiquidWarp(
    float2 position,
    float scaleX,
    float scaleY
) {
    float2 designScale = max(float2(scaleX, scaleY), float2(0.0001));
    float2 designPosition = position / designScale;
    float2 frequency = float2(0.008, 0.024);
    float2 samplePoint = designPosition * frequency;

    float redNoise = cortexSmoothNoise(samplePoint, 17.0);
    float greenNoise = cortexSmoothNoise(samplePoint + float2(37.2, 19.4), 17.0);
    float2 designDisplacement = (float2(redNoise, greenNoise) - 0.5) * 17.0;

    return position + designDisplacement * designScale;
}
