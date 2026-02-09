/**
 * Embedded Demo Host for nocterm landing page
 *
 * This creates mini xterm.js terminals that can display different
 * compiled nocterm demos inline on the landing page.
 */

// Load xterm.js CSS dynamically
if (!document.querySelector('link[href*="xterm.css"]')) {
  const xtermCss = document.createElement('link');
  xtermCss.rel = 'stylesheet';
  xtermCss.href = 'https://cdn.jsdelivr.net/npm/xterm@5.3.0/css/xterm.css';
  document.head.appendChild(xtermCss);
}

class EmbeddedDemoHost {
  constructor(containerId, options = {}) {
    this.containerId = containerId;
    this.options = {
      cols: options.cols || 40,
      rows: options.rows || 12,
      fontSize: options.fontSize || 12,
      ...options
    };
    this.terminal = null;
    this.fitAddon = null;
    this.bridgeId = `nocterm_bridge_${containerId}`;
    this.isInitialized = false;
  }

  async initialize() {
    // Wait for xterm.js to load
    await this.waitForXterm();

    // Create xterm.js terminal
    this.terminal = new Terminal({
      cursorBlink: false,
      cursorStyle: 'underline',
      fontFamily: '"Cascadia Code", "Fira Code", "JetBrains Mono", "Source Code Pro", monospace',
      fontSize: this.options.fontSize,
      cols: this.options.cols,
      rows: this.options.rows,
      theme: {
        background: '#0c0c14',
        foreground: '#d4d4d4',
        cursor: '#c0a0ff',
        cursorAccent: '#0c0c14',
        black: '#1e1e1e',
        red: '#ff6b9d',
        green: '#1dd1a1',
        yellow: '#feca57',
        blue: '#54a0ff',
        magenta: '#c0a0ff',
        cyan: '#48dbfb',
        white: '#d4d4d4',
        brightBlack: '#858585',
        brightRed: '#ff8fab',
        brightGreen: '#5eead4',
        brightYellow: '#ffe066',
        brightBlue: '#7eb8ff',
        brightMagenta: '#d4b8ff',
        brightCyan: '#7ee8fa',
        brightWhite: '#ffffff',
      },
      allowTransparency: false,
      convertEol: true,
      drawBoldTextInBrightColors: false,
    });

    // Create and load fit addon
    this.fitAddon = new FitAddon.FitAddon();
    this.terminal.loadAddon(this.fitAddon);

    // Open terminal in container
    const container = document.getElementById(this.containerId);
    if (!container) {
      throw new Error(`Container element #${this.containerId} not found`);
    }

    // Clear any loading state
    container.innerHTML = '';
    this.terminal.open(container);

    // Initialize bridge for this demo instance
    this.initializeBridge();

    // Wire up input
    this.terminal.onData(data => {
      this.sendInputToGuest(data);
    });

    this.isInitialized = true;
    return this;
  }

  async waitForXterm() {
    // Wait for xterm.js to be available
    return new Promise((resolve, reject) => {
      let attempts = 0;
      const maxAttempts = 50;

      const check = () => {
        if (typeof Terminal !== 'undefined' && typeof FitAddon !== 'undefined') {
          resolve();
        } else if (attempts >= maxAttempts) {
          reject(new Error('xterm.js failed to load'));
        } else {
          attempts++;
          setTimeout(check, 100);
        }
      };
      check();
    });
  }

  initializeBridge() {
    // Each embedded demo gets its own bridge namespace
    if (!window.noctermBridges) {
      window.noctermBridges = {};
    }

    window.noctermBridges[this.bridgeId] = {
      width: this.options.cols,
      height: this.options.rows,
      onOutput: null,
      onInput: null,
      onResize: null,
      onShutdown: null,
    };
  }

  sendInputToGuest(data) {
    const bridge = window.noctermBridges[this.bridgeId];
    if (bridge && bridge.onInput) {
      bridge.onInput(data);
    }
  }

  writeToTerminal(data) {
    if (this.terminal) {
      this.terminal.write(data);
    }
  }

  async loadApp(scriptPath) {
    return new Promise((resolve, reject) => {
      // Set up the bridge reference for the guest app
      window.currentNoctermBridge = window.noctermBridges[this.bridgeId];
      window.currentNoctermBridgeId = this.bridgeId;

      // Set up output handler
      window.noctermBridges[this.bridgeId].onOutput = (data) => {
        this.writeToTerminal(data);
      };

      // Load the compiled Dart app
      const script = document.createElement('script');
      script.src = scriptPath;
      script.async = true;

      script.onload = () => {
        resolve();
      };

      script.onerror = (e) => {
        reject(new Error(`Failed to load app: ${scriptPath}`));
      };

      document.body.appendChild(script);
    });
  }

  focus() {
    if (this.terminal) {
      this.terminal.focus();
    }
  }

  dispose() {
    if (this.terminal) {
      this.terminal.dispose();
    }
    if (window.noctermBridges && window.noctermBridges[this.bridgeId]) {
      delete window.noctermBridges[this.bridgeId];
    }
  }
}

// Factory function for creating embedded demos
async function createEmbeddedDemo(containerId, appPath, options = {}) {
  const host = new EmbeddedDemoHost(containerId, options);
  await host.initialize();
  if (appPath) {
    await host.loadApp(appPath);
  }
  return host;
}

// Export for use
window.EmbeddedDemoHost = EmbeddedDemoHost;
window.createEmbeddedDemo = createEmbeddedDemo;
