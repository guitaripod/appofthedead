#include <metal_stdlib>
using namespace metal;

struct AwakeningUniforms {
    float4 colorA;
    float4 colorB;
    float2 resolution;
    float progress;
    float time;
    float reduceMotion;
    float intensity;
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut awakening_vertex(uint vid [[vertex_id]]) {
    float2 p = float2((vid << 1) & 2, vid & 2);
    VSOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

static inline float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

static inline float fbm(float2 p) {
    float v = 0.0;
    float amp = 0.5;
    float2x2 m = float2x2(1.6, 1.2, -1.2, 1.6);
    for (int i = 0; i < 5; i++) {
        v += amp * valueNoise(p);
        p = m * p;
        amp *= 0.5;
    }
    return v;
}

fragment float4 awakening_fragment(VSOut in [[stage_in]],
                                   constant AwakeningUniforms &u [[buffer(0)]]) {
    float2 res = max(u.resolution, float2(1.0));
    float2 uv = (in.uv * res - 0.5 * res) / res.y;
    float t = u.time;
    float r = length(uv);
    float ang = atan2(uv.y, uv.x);

    float2 q = float2(fbm(uv * 2.0 + t * 0.05), fbm(uv * 2.0 - t * 0.04));
    float swirl = ang + r * 3.0 - t * 0.30 * (1.0 - u.reduceMotion);
    float2 warped = float2(cos(swirl), sin(swirl)) * r + q * 0.6;
    float n = fbm(warped * 3.0 + q);

    float reveal = u.progress * 1.25;
    float frontier = reveal + 0.04 * fbm(uv * 6.0 + t);
    float mask = smoothstep(frontier + 0.14, frontier - 0.02, r);
    mask = max(mask, (1.0 - u.progress * 8.0) * smoothstep(0.34, 0.0, r) * 0.6);

    float k = clamp(n * 1.15 + (1.0 - r), 0.0, 1.0);
    float3 col = mix(u.colorA.rgb, u.colorB.rgb, k);

    float core = pow(max(0.0, 1.0 - r * 1.4), 3.0);
    col += core * u.colorB.rgb * (0.55 + 0.45 * u.progress);

    float frontierGlow = smoothstep(0.10, 0.0, abs(r - frontier)) * u.progress;
    col += frontierGlow * u.colorB.rgb * 0.5;

    col *= mask;

    float swell = smoothstep(0.97, 1.0, u.progress) * (0.5 + 0.5 * sin(t * 6.0));
    col += u.colorB.rgb * swell * 0.4;

    col *= mix(1.0, 0.5, smoothstep(0.15, -0.55, uv.y));
    col = col / (1.0 + col);
    col *= u.intensity;

    return float4(col, 1.0);
}
