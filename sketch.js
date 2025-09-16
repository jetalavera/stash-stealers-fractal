// Stash Stealers Mandelbrot-ish trip (p5 + WebGL shader)
// GPU fragment shader does the heavy lifting; smooth coloring & palette cycling
// Accessibility: "Reduce Flash" checkbox tones down strobing and lowers color/zoom speeds.
// References: p5 WebGL/shaders, frameRate, Mandelbrot coloring, WCAG flashing guidance.
// Docs: p5 shaders/WEBGL (p5js.org), smooth coloring/escape-time (Wikipedia/StackOverflow). 

let theShader;
let t0;
let safeToggle, colorSpeedInput, zoomSpeedInput;

function preload(){
  theShader = loadShader('vert.glsl', 'frag.glsl'); // p5 loads vertex+fragment
}

function setup(){
  // WEBGL mode to run the fragment shader on GPU
  createCanvas(windowWidth, windowHeight, WEBGL);
  noStroke();
  shader(theShader);

  t0 = millis();

  // DOM controls
  safeToggle      = select('#safe');
  colorSpeedInput = select('#colorSpeed');
  zoomSpeedInput  = select('#zoomSpeed');

  // Default “Reduce Flash” to OFF, but honor prefers-reduced-motion
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    safeToggle.elt.checked = true;
  }

  // Slightly cap frame rate for sanity
  frameRate(60); // target only; browser may vary (p5 reference).  //  [oai_citation:4‡p5.js](https://p5js.org/reference/p5/frameRate/?utm_source=chatgpt.com)
}

function windowResized(){
  resizeCanvas(windowWidth, windowHeight);
}

function draw(){
  const tSec = (millis() - t0) / 1000.0;

  // UI values
  const userColor = parseFloat(colorSpeedInput.elt.value);
  const userZoom  = parseFloat(zoomSpeedInput.elt.value);
  const safeMode  = !!safeToggle.elt.checked;

  // Derive speeds; safe mode reduces intensity and disables fast flicker
  const colorSpeed = safeMode ? userColor * 0.2 : userColor;
  const zoomSpeed  = safeMode ? userZoom  * 0.15 : userZoom;

  // Center pans (subtle orbit)
  const panX = 0.0 + 0.35 * Math.sin(tSec * 0.2);
  const panY = 0.0 + 0.35 * Math.cos(tSec * 0.17);

  // Zoom oscillates and very slowly increases for “infinite depth” sensation
  const baseZoom = 0.85 + 0.15 * Math.sin(tSec * (0.3 + zoomSpeed));
  const deepZoom = 1.0 + 0.25 * (Math.sin(tSec * 0.07) + 1.0) * (zoomSpeed * 0.75);
  const zoom = baseZoom * deepZoom;

  // Palette phase & strobe control
  const colorPhase = tSec * (0.8 + colorSpeed * 2.2);
  const strobe = safeMode ? 0.0 : 0.75;  // 0..1 intensity

  theShader.setUniform('u_time', tSec);
  theShader.setUniform('u_res', [width, height]);
  theShader.setUniform('u_center', [panX, panY]);
  theShader.setUniform('u_zoom', zoom);
  theShader.setUniform('u_colorPhase', colorPhase);
  theShader.setUniform('u_strobe', strobe);

  rect(-width/2, -height/2, width, height);
}
