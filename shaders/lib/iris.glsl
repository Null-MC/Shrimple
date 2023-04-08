const vec3 BACKGROUND_COLOR = vec3(0.824, 0.808, 0.761);
const vec3 GRADIENT_LEFT = vec3(0.031, 0.133, 0.365);
const vec3 GRADIENT_RIGHT = vec3(0.718, 0.769, 0.804);

const float MARGIN = 8.0;


// https://iquilezles.org/articles/distfunctions2d/
float sdTriangleIsosceles(in vec2 p, in vec2 q) {
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

float sdUnevenCapsule(vec2 p, float r1, float r2, float h) {
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

void drawClose(vec2 uv, inout vec3 color) {
    vec2 size = vec2(16.0, 14.0);
    uv = (uv - vec2(336.0, 2.0));
    
    if (clamp(uv, vec2(0.0), size) != uv) return;
    
    color = BACKGROUND_COLOR;
    ivec2 iuv = ivec2(uv);
    if (iuv.x == 15 || iuv.y == 0) {
        color = vec3(0, 0, 0);
        return;
    }
    
    if (iuv.x == 0 || iuv.y == 13) {
        color *= 1.2;
        return;
    }

    if (clamp(uv, vec2(3.0), size - 3.0) != uv) return;

    uv -= vec2(7, 6.5);
    uv = floor(uv);
    color *= clamp(min(distance(uv, uv.xx), distance(uv, vec2(uv.x, -uv.x))) / 1.5 - 0.4, 0.0, 1.0) * 0.3 + 0.7;
}

void drawHeader(vec2 uv, inout vec3 color) {
    vec2 size = vec2(354.0, 18.0);
    uv = (uv - vec2(3.0, 99.0)) / size;
    
    if (clamp(uv, 0.0, 1.0) != uv) return;
        
    color = mix(GRADIENT_LEFT, GRADIENT_RIGHT, uv.x);
    drawClose(uv * size, color);

    beginText(ivec2(uv * size), ivec2(4, 13));
    text.bgCol = vec4(0);
    printString((_W, _a, _r, _n, _i, _n, _g))
    endText(color);
}

void drawTriangle(vec2 uv, inout vec3 color) {
    uv = floor((uv - vec2(16.0, 50.0))) / vec2(32.0, 32.0);
    if (clamp(uv, 0.0, 1.0) != uv) return;
   
    uv -= vec2(0.5, 0.8);

    float shadowDist = sdTriangleIsosceles(uv + vec2(-0.1, 0.06), vec2(0.3, -0.6));
    if (shadowDist < 0.087)
        color *= 0.7;

    float dist = sdTriangleIsosceles(uv, vec2(0.3, -0.6));
    if (dist >= 0.087) return;
    
    color = vec3(0.98, 0.93, 0.2);
    if (dist < 0.087 && dist > 0.06) {
        color = vec3(0, 0, 0);
        return;
    }
    
    if (distance(uv, vec2(0.0, -0.53)) < 0.052)
        color = vec3(0, 0, 0);
    
    uv.y += 0.43;
    if (sdUnevenCapsule(uv, 0.01, 0.082, 0.2) < 0.0)
        color = vec3(0, 0, 0);
}

void drawButton(vec2 uv, inout vec3 color) {
    uv -= vec2(145.0, 20.0);
    if (clamp(uv, vec2(0.0), vec2(65.0, 20.0)) != uv) return;
       
    ivec2 iuv = ivec2(uv);
    
    if (iuv.x == 0 || iuv.y == 0 || iuv.x == 64 || iuv.y == 19) {
        color = vec3(0, 0, 0);
        return;
    }
    
    if (iuv.x == 63 || iuv.y == 1) {
        color *= 0.6;
        return;
    }
    
    if (iuv.x == 1 || iuv.y == 18)
        color *= 1.2;
    
    if (clamp(uv, vec2(4.0), vec2(61.0, 17.0)) != uv) return;
    
    if (clamp(uv, vec2(5.0), vec2(60.0, 16.0)) != uv) {
        color = (iuv.x + iuv.y + 1) % 2 == 0 ? vec3(0, 0, 0) : BACKGROUND_COLOR;
        return;
    }
    
    beginText(iuv, ivec2(15, 15));
    text.bgCol = vec4(0);
    text.fgCol = vec4(0, 0, 0, 1);
    printString((_N, _o, _t, _space, _O, _K))
    endText(color);
}

void drawWarning(inout vec3 color) {
    vec2 uv = gl_FragCoord.xy * 0.5;

    uv -= (vec2(viewWidth, viewHeight)*0.5 - vec2(360.0, 120.0)) * 0.5;

    if (clamp(uv, vec2(0.0), vec2(360.0, 120.0)) != uv) return;
    
    color = BACKGROUND_COLOR;
    ivec2 iuv = ivec2(uv);
    
    if (iuv.x == 359 || iuv.y == 0) {
        color = vec3(0, 0, 0);
        return;
    }
    
    if (iuv.x == 358 || iuv.y == 1) {
        color *= 0.6;
        return;
    }
    
    if (iuv.x == 0 || iuv.y == 119) return;
        
    if (iuv.x == 1 || iuv.y == 118) {
        color *= 1.2;
        return;
    }
    
    drawHeader(uv, color);
    drawTriangle(uv, color);
    drawButton(uv, color);

    beginText(iuv, ivec2(60, 70));
    text.bgCol = vec4(0);
    text.fgCol = vec4(0, 0, 0, 1);
    printString((_E, _n, _a, _b, _l, _e, _d, _space, _f, _e, _a, _t, _u, _r, _e, _s, _space, _r, _e, _q, _u, _i, _r, _e, _space, _I, _r, _i, _s, _space, _1, _dot, _6, _space, _o, _r, _space, _l, _a, _t, _e, _r))
    endText(color.rgb);
}
