// The wallpaper transition shader: bloom, keys, stripe, fade, slide, pixel, blinds, ripple.
// Edit: each mode's branch here, then rebuild:
// qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o wall.frag.qsb wall.frag

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    float seed;
    int mode;
    vec2 center;
    vec2 fromScale;
    vec2 toScale;
    vec4 colA;
    vec4 colB;
    vec4 colC;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

vec4 crop(sampler2D t, vec2 uv, vec2 s) {
    return texture(t, (uv - 0.5) * s + 0.5);
}

float easeInOut(float t) {
    return t < 0.5 ? 4.0 * t * t * t : 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0;
}

float easeOutBack(float t) {
    float c1 = 1.70158;
    float c3 = c1 + 1.0;
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed * 91.7) * 43758.5453);
}

vec4 bands(float x, float aa, vec4 a, vec4 b) {
    vec4 c = mix(colC, colB, smoothstep(0.33 - aa, 0.33 + aa, x));
    c = mix(c, colA, smoothstep(0.66 - aa, 0.66 + aa, x));
    c = mix(a, c, smoothstep(-aa, aa, x));
    return mix(c, b, smoothstep(1.0 - aa, 1.0 + aa, x));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 a = crop(fromTex, uv, fromScale);
    vec4 b = crop(toTex, uv, toScale);
    float p = clamp(progress, 0.0, 1.0);
    vec4 col;

    if (mode == 1) {
        vec2 d = (uv - center) * vec2(aspect, 1.0);
        float r = length(d);
        float maxR = length(max(center, 1.0 - center) * vec2(aspect, 1.0));
        float w = mix(0.22, 0.08, p);
        float edge = easeInOut(p) * (maxR + w + 0.05);
        float ang = atan(d.y, d.x);
        float wob = 0.014 * sin(ang * 6.0 + p * 8.0 + seed * 6.2832) * (1.0 - p);
        float x = (edge - r + wob) / w;
        float aa = fwidth(r) / w * 1.5;
        col = bands(x, aa, a, b);
    } else if (mode == 2) {
        float rows = 9.0;
        float cols = ceil(aspect * rows);
        vec2 q = vec2(uv.x * aspect, uv.y) * rows;
        vec2 cell = floor(q);
        vec2 f = fract(q) - 0.5;
        float order = (cell.x / cols + cell.y / rows) * 0.5;
        float t = clamp((p * 1.4 - order * 0.9 - hash(cell) * 0.12) / 0.32, 0.0, 1.0);
        float size = 0.5 * clamp(easeOutBack(t), 0.0, 1.08);
        float rad = min(0.16, size);
        vec2 qd = abs(f) - vec2(max(size - rad, 0.0));
        float sd = length(max(qd, 0.0)) + min(max(qd.x, qd.y), 0.0) - rad;
        float aa = fwidth(q.x) * 1.2;

        float rimW = 0.08 * (1.0 - smoothstep(0.55, 0.95, t));
        vec4 rim = mix(colA, colC, t);
        vec4 inner = mix(rim, b, smoothstep(rimW - aa, rimW + aa, -sd));
        col = mix(a, inner, smoothstep(aa, -aa, sd));
        if (t >= 1.0) col = b;
    } else if (mode == 3) {
        float s = (uv.x * aspect + uv.y) / (aspect + 1.0);
        float w = 0.12;
        float edge = easeInOut(p) * (1.0 + w + 0.02);
        float x = (edge - s) / w;
        float aa = fwidth(s) / w * 1.5;
        float stripe = smoothstep(0.45, 0.55, fract((uv.x * aspect - uv.y) * 16.0 + p * 2.0));
        vec4 band = mix(colA, colC, stripe);
        col = mix(a, band, smoothstep(-aa, aa, x));
        col = mix(col, b, smoothstep(1.0 - aa, 1.0 + aa, x));
    } else if (mode == 4) {
        float e = easeInOut(p);
        vec2 ua = vec2(uv.x + e, uv.y);
        vec2 ub = vec2(uv.x - (1.0 - e), uv.y);
        vec4 ca = crop(fromTex, ua, fromScale);
        vec4 cb = crop(toTex, ub, toScale);
        float edgeX = 1.0 - e;
        col = uv.x < edgeX ? ca : cb;

        float seam = 1.0 - smoothstep(0.0, 0.006, abs(uv.x - edgeX));
        col = mix(col, colA, seam * (1.0 - smoothstep(0.85, 1.0, p)) * step(0.001, p));
    } else if (mode == 5) {

        float k = sin(clamp(p, 0.0, 1.0) * 3.14159265);
        float cells = mix(900.0, 14.0, k);
        vec2 grid = vec2(cells * aspect, cells);
        vec2 puv = (floor(uv * grid) + 0.5) / grid;
        vec4 pa = crop(fromTex, puv, fromScale);
        vec4 pb = crop(toTex, puv, toScale);
        col = mix(pa, pb, smoothstep(0.42, 0.58, p));
    } else if (mode == 6) {
        float slats = 14.0;
        float id = floor(uv.x * slats);
        float f = fract(uv.x * slats);

        float t = clamp((p * 1.5 - id / slats * 0.5) / 1.0, 0.0, 1.0);
        float turn = easeInOut(t);

        float w = abs(cos(turn * 3.14159265));
        float half_ = 0.5 * w;
        bool showNew = turn > 0.5;
        float inside = step(abs(f - 0.5), max(half_, 0.0005));
        vec4 face = showNew ? b : a;
        vec4 gap = mix(a, b, step(0.5, turn));
        vec4 edgeCol = mix(colC, colA, turn);
        col = mix(edgeCol, face, inside);
        if (turn <= 0.0) col = a;
        if (turn >= 1.0) col = b;

        col = mix(gap * 0.35 + edgeCol * 0.1, col, max(inside, step(turn, 0.0) + step(1.0, turn)));
    } else if (mode == 7) {
        vec2 d = (uv - center) * vec2(aspect, 1.0);
        float r = length(d);
        float maxR = length(max(center, 1.0 - center) * vec2(aspect, 1.0));
        float e = easeInOut(p);
        float front = e * (maxR + 0.15);
        float x = front - r;
        float wave = sin(x * 40.0) * exp(-abs(x) * 9.0) * 0.018 * (1.0 - p * 0.6);
        vec2 dir = r > 0.0001 ? d / r : vec2(0.0);
        vec2 off = dir * wave * vec2(1.0 / aspect, 1.0);
        vec4 ra = crop(fromTex, uv + off, fromScale);
        vec4 rb = crop(toTex, uv + off, toScale);
        col = mix(ra, rb, smoothstep(-0.02, 0.02, x));
        float ring = exp(-abs(x) * 70.0) * 0.35 * (1.0 - smoothstep(0.8, 1.0, p));
        col = mix(col, colA, ring);
    } else {
        col = mix(a, b, smoothstep(0.0, 1.0, p));
    }

    fragColor = col * qt_Opacity;
}
