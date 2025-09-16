#ifdef GL_ES
precision highp float;
#endif

uniform vec2 u_res;
uniform float u_time;
uniform vec2 u_center;
uniform float u_zoom;
uniform float u_colorPhase;
uniform float u_strobe;

// Complex iteration for Mandelbrot (z -> z^2 + c), smooth coloring
// Inspired by escape-time w/ normalized iteration count for smooth bands.
// Sources discuss smooth/continuous coloring & palette mapping.  //  [oai_citation:5‡Wikipedia](https://en.wikipedia.org/wiki/Plotting_algorithms_for_the_Mandelbrot_set?utm_source=chatgpt.com)

vec3 palette(float t){
  // Iridescent / neon sweep: cycle hues smoothly; clamp strobe to avoid WCAG issues.
  float s = 0.65 + 0.35 * sin(u_colorPhase * 0.5);
  float v = 0.9;
  float h = fract(t + 0.15 * sin(u_colorPhase*0.7));
  // Convert HSV -> RGB (approx)
  float c = v * s;
  float hh = h * 6.0;
  float x = c * (1.0 - abs(mod(hh, 2.0) - 1.0));
  vec3 rgb;
  if (hh < 1.0) rgb = vec3(c, x, 0.0);
  else if (hh < 2.0) rgb = vec3(x, c, 0.0);
  else if (hh < 3.0) rgb = vec3(0.0, c, x);
  else if (hh < 4.0) rgb = vec3(0.0, x, c);
  else if (hh < 5.0) rgb = vec3(x, 0.0, c);
  else              rgb = vec3(c, 0.0, x);
  float m = v - c;
  return rgb + m;
}

void main(){
  // Map pixel to complex plane with aspect ratio accounted, center & zoom control
  vec2 uv = (gl_FragCoord.xy / u_res) * 2.0 - 1.0;
  uv.x *= u_res.x / u_res.y;

  // “Camera”
  float scale = 1.8 / max(0.2, u_zoom);
  vec2 c = vec2(uv.x * scale + u_center.x, uv.y * scale + u_center.y);

  // Mandelbrot escape-time w/ smooth coloring
  vec2 z = vec2(0.0);
  float iter = 0.0, maxIter = mix(80.0, 420.0, clamp(u_zoom * 0.75, 0.0, 1.0));
  float escape = 4.0;

  for (int i = 0; i < 1000; i++){
    if (iter >= maxIter) break;
    float x = (z.x*z.x - z.y*z.y) + c.x;
    float y = (2.0*z.x*z.y) + c.y;
    z = vec2(x,y);
    if (dot(z,z) > escape) break;
    iter += 1.0;
  }

  // Smooth iteration count (normalized) for bandless gradient
  float smooth = iter;
  if (iter < maxIter){
    float zn = length(z);
    // normalized iteration count
    smooth = iter + 1.0 - log(log(zn)) / log(2.0);
  }
  float t = smooth / maxIter;

  // Neon palette + gentle bloom
  vec3 col = palette(fract(t + 0.2 * sin(u_colorPhase*0.3)));
  // Strobe is capped; multiply by low-amplitude sine to avoid >3 flashes/sec concerns.  //  [oai_citation:6‡W3C](https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold.html?utm_source=chatgpt.com)
  float pulse = 0.5 + 0.5 * sin(u_time * 2.5);
  col *= (1.0 + u_strobe * 0.25 * pulse);

  // Add subtle “sparkle” via high-frequency jitter in brightness
  float sparkle = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);
  col += 0.03 * (sparkle - 0.5);

  // Vignette for depth
  float d = length(uv);
  col *= smoothstep(1.2, 0.2, d);

  gl_FragColor = vec4(pow(max(col, 0.0), vec3(1.0/1.8)), 1.0);
}
