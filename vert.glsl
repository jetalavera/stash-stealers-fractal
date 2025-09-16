// Minimal pass-through vertex shader for full-screen quad
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

attribute vec3 aPosition;
void main(){
  gl_Position = vec4(aPosition, 1.0);
}
