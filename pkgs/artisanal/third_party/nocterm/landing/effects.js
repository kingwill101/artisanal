/**
 * nocterm Landing Page Effects
 * WebGL plasma background + CSS wave animation
 */

// ============================================
// WebGL Plasma Background (GPU-accelerated)
// ============================================

class PlasmaEffect {
  constructor(canvas) {
    this.canvas = canvas;
    this.gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');

    if (!this.gl) {
      console.warn('WebGL not supported, falling back to static');
      return;
    }

    this.time = 0;
    this.animationId = null;
    this.isVisible = true;

    this.init();
    this.setupVisibility();
  }

  init() {
    const gl = this.gl;

    // Vertex shader - just a full-screen quad
    const vertexShader = this.createShader(gl.VERTEX_SHADER, `
      attribute vec2 a_position;
      varying vec2 v_uv;
      void main() {
        v_uv = a_position * 0.5 + 0.5;
        gl_Position = vec4(a_position, 0.0, 1.0);
      }
    `);

    // Fragment shader - plasma effect with terminal characters
    const fragmentShader = this.createShader(gl.FRAGMENT_SHADER, `
      precision mediump float;
      varying vec2 v_uv;
      uniform float u_time;
      uniform vec2 u_resolution;

      // Terminal character patterns (8x8 bitmap-style)
      float char_empty(vec2 p) { return 0.0; }

      float char_dot_small(vec2 p) {
        vec2 c = vec2(0.5);
        return smoothstep(0.2, 0.15, length(p - c));
      }

      float char_dot(vec2 p) {
        vec2 c = vec2(0.5);
        return smoothstep(0.3, 0.25, length(p - c));
      }

      float char_light(vec2 p) {
        // ░ - light shade - scattered dots
        vec2 grid = fract(p * 4.0);
        float d = step(0.7, grid.x) * step(0.7, grid.y);
        d += step(0.7, 1.0 - grid.x) * step(0.7, 1.0 - grid.y);
        return d * 0.4;
      }

      float char_medium(vec2 p) {
        // ▒ - medium shade - checkerboard
        vec2 grid = fract(p * 4.0);
        float check = mod(floor(p.x * 4.0) + floor(p.y * 4.0), 2.0);
        return check * 0.6;
      }

      float char_dark(vec2 p) {
        // ▓ - dark shade - inverse checkerboard
        vec2 grid = fract(p * 4.0);
        float check = mod(floor(p.x * 4.0) + floor(p.y * 4.0), 2.0);
        return (1.0 - check * 0.3) * 0.8;
      }

      float char_block(vec2 p) {
        // █ - full block
        return 1.0;
      }

      // Plasma function
      float plasma(vec2 uv, float t) {
        float v1 = sin(uv.x * 12.0 + t);
        float v2 = cos(uv.y * 10.0 + t);
        float v3 = sin((uv.x + uv.y) * 8.0 + t);
        float v4 = cos(length(uv - 0.5) * 15.0 - t);
        return (v1 + v2 + v3 + v4) * 0.25;
      }

      void main() {
        // Character cell size
        vec2 cellSize = vec2(10.0, 16.0);
        vec2 cells = u_resolution / cellSize;

        // Which cell we're in
        vec2 cellCoord = floor(v_uv * cells);
        vec2 cellUV = fract(v_uv * cells);

        // Normalized cell position for plasma
        vec2 plasmaUV = cellCoord / cells;

        // Get plasma value for this cell
        float p = plasma(plasmaUV, u_time);

        // Choose character based on plasma value
        float charValue = 0.0;
        if (p > 0.7) {
          charValue = char_block(cellUV);
        } else if (p > 0.5) {
          charValue = char_dark(cellUV);
        } else if (p > 0.3) {
          charValue = char_medium(cellUV);
        } else if (p > 0.1) {
          charValue = char_light(cellUV);
        } else if (p > -0.1) {
          charValue = char_dot(cellUV);
        } else if (p > -0.4) {
          charValue = char_dot_small(cellUV);
        }

        // Color based on plasma
        float v3 = p * 3.0;
        float r = sin(v3 + u_time) * 0.23 + 0.31;
        float g = sin(v3 + 2.0) * 0.16 + 0.12;
        float b = sin(v3 + 4.0 + u_time) * 0.31 + 0.55;

        // Clamp colors
        r = clamp(r, 0.08, 0.55);
        g = clamp(g, 0.04, 0.31);
        b = clamp(b, 0.24, 0.86);

        // Background color
        vec3 bgColor = vec3(0.047, 0.047, 0.078);
        vec3 charColor = vec3(r, g, b);

        // Mix based on character
        vec3 color = mix(bgColor, charColor, charValue);

        gl_FragColor = vec4(color, 1.0);
      }
    `);

    if (!vertexShader || !fragmentShader) return;

    // Create program
    this.program = gl.createProgram();
    gl.attachShader(this.program, vertexShader);
    gl.attachShader(this.program, fragmentShader);
    gl.linkProgram(this.program);

    if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) {
      console.error('Program link error:', gl.getProgramInfoLog(this.program));
      return;
    }

    // Set up geometry (full-screen quad)
    const positions = new Float32Array([
      -1, -1,
       1, -1,
      -1,  1,
       1,  1,
    ]);

    this.buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
    gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

    // Get locations
    this.positionLoc = gl.getAttribLocation(this.program, 'a_position');
    this.timeLoc = gl.getUniformLocation(this.program, 'u_time');
    this.resolutionLoc = gl.getUniformLocation(this.program, 'u_resolution');

    this.resize();
    window.addEventListener('resize', () => this.resize());
  }

  createShader(type, source) {
    const gl = this.gl;
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      console.error('Shader compile error:', gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  setupVisibility() {
    // Pause when tab hidden
    document.addEventListener('visibilitychange', () => {
      this.isVisible = !document.hidden;
      if (this.isVisible && !this.animationId) {
        this.animate();
      }
    });

    // Pause when scrolled out of view
    this.observer = new IntersectionObserver((entries) => {
      this.isVisible = entries[0].isIntersecting;
      if (this.isVisible && !this.animationId) {
        this.animate();
      }
    }, { threshold: 0.1 });
    this.observer.observe(this.canvas);
  }

  resize() {
    const rect = this.canvas.parentElement.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    this.canvas.width = rect.width * dpr;
    this.canvas.height = rect.height * dpr;
    this.canvas.style.width = rect.width + 'px';
    this.canvas.style.height = rect.height + 'px';

    this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
  }

  render() {
    const gl = this.gl;

    gl.useProgram(this.program);

    // Set uniforms
    gl.uniform1f(this.timeLoc, this.time);
    gl.uniform2f(this.resolutionLoc, this.canvas.width, this.canvas.height);

    // Draw
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
    gl.enableVertexAttribArray(this.positionLoc);
    gl.vertexAttribPointer(this.positionLoc, 2, gl.FLOAT, false, 0, 0);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  }

  animate() {
    if (!this.isVisible || !this.gl) {
      this.animationId = null;
      return;
    }

    this.time += 0.02;
    this.render();
    this.animationId = requestAnimationFrame(() => this.animate());
  }

  start() {
    if (this.gl) {
      this.animate();
    }
  }
}

// ============================================
// Wave Effect (CSS-only, no JS animation needed)
// ============================================

class WaveEffect {
  constructor(container) {
    this.container = container;
    this.createElements();
  }

  createElements() {
    // Create wave characters with CSS animation delays
    const chars = 30;
    const fragment = document.createDocumentFragment();

    for (let i = 0; i < chars; i++) {
      const span = document.createElement('span');
      span.className = 'wave-char';
      span.style.setProperty('--i', i);
      span.textContent = '█';
      fragment.appendChild(span);
    }

    this.container.appendChild(fragment);
  }
}

// ============================================
// Keyboard Navigation (vim-style)
// ============================================
// NOTE: Removed KeyboardNav class - spatial navigation is now handled
// in index.html directly with the unified nav system using data-nav attributes.
// This prevents the dual-focus bug where both keyboard-focus and nav-selected
// classes were being applied simultaneously.

// ============================================
// Initialize Effects
// ============================================

document.addEventListener('DOMContentLoaded', () => {
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (!prefersReducedMotion) {
    // Start WebGL plasma effect
    const plasmaCanvas = document.getElementById('plasma-bg');
    if (plasmaCanvas) {
      const plasma = new PlasmaEffect(plasmaCanvas);
      plasma.start();
    }

    // Create wave elements (animated via CSS)
    const waveContainer = document.getElementById('wave');
    if (waveContainer) {
      new WaveEffect(waveContainer);
    }
  } else {
    // Static fallback
    const waveContainer = document.getElementById('wave');
    if (waveContainer) {
      waveContainer.textContent = '░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░';
      waveContainer.style.color = '#5a5a8a';
    }
  }

  // NOTE: Keyboard navigation is now handled in index.html via the unified
  // spatial navigation system using data-nav attributes.
});
