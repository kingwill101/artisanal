/**
 * Embeddable nocterm terminal for landing page demos
 *
 * This is a smaller, inline version of NoctermTerminalHost
 * designed for embedding interactive demos within the landing page.
 */

class EmbeddedTerminal {
  constructor(containerId, options = {}) {
    this.containerId = containerId;
    this.options = {
      cols: options.cols || 50,
      rows: options.rows || 14,
      fontSize: options.fontSize || 13,
      background: options.background || '#0c0c14',
      ...options
    };
    this.terminal = null;
    this.fitAddon = null;
    this.appLoaded = false;
  }

  async initialize() {
    // Create xterm.js terminal - theme matches landing page exactly
    this.terminal = new Terminal({
      cursorBlink: true,
      cursorStyle: 'underline',
      fontFamily: '"JetBrains Mono", "Fira Code", "Cascadia Code", monospace',
      fontSize: this.options.fontSize,
      cols: this.options.cols,
      rows: this.options.rows,
      theme: {
        // Match landing page CSS variables exactly
        background: '#0c0c14',  // --bg-panel
        foreground: '#9999bb',  // --text-primary
        cursor: '#c0a0ff',      // --purple
        cursorAccent: '#0c0c14',
        selectionBackground: 'rgba(192, 160, 255, 0.3)',
        // ANSI colors matching landing page
        black: '#080810',       // --bg-dark
        red: '#ff6b9d',         // --pink
        green: '#1dd1a1',       // --green
        yellow: '#feca57',      // --yellow
        blue: '#48dbfb',        // --cyan (used for blue)
        magenta: '#c0a0ff',     // --purple
        cyan: '#48dbfb',        // --cyan
        white: '#9999bb',       // --text-primary
        brightBlack: '#666688', // --text-secondary
        brightRed: '#ff8fab',
        brightGreen: '#5eead4',
        brightYellow: '#ffe066',
        brightBlue: '#7eb8ff',
        brightMagenta: '#d4b8ff',
        brightCyan: '#7ee8fa',
        brightWhite: '#ffffff', // --text-bright
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
      throw new Error(`Container element '${this.containerId}' not found`);
    }
    container.innerHTML = '';
    this.terminal.open(container);

    // Initialize the nocterm bridge
    this.initializeBridge();
    this.updateBridgeSize();

    // Wire up input - intercept Escape key before sending to guest
    this.terminal.onData(data => {
      // Check for Escape key (0x1b alone, not part of a sequence)
      if (data === '\x1b' && this.onEscapeKey) {
        this.onEscapeKey();
        return; // Don't send Escape to guest
      }
      this.sendInputToGuest(data);
    });

    // Handle resize
    this.terminal.onResize(({ cols, rows }) => {
      this.handleResize(cols, rows);
    });

    console.log(`Embedded terminal initialized: ${this.terminal.cols}x${this.terminal.rows}`);
    return this;
  }

  initializeBridge() {
    window.noctermBridge = {
      width: null,
      height: null,
      onOutput: null,
      onInput: null,
      onResize: null,
      onShutdown: null,
    };

    window.noctermBridge.onOutput = (data) => {
      this.writeToTerminal(data);
    };
  }

  updateBridgeSize() {
    if (window.noctermBridge) {
      window.noctermBridge.width = this.terminal.cols;
      window.noctermBridge.height = this.terminal.rows;
    }
  }

  sendInputToGuest(data) {
    if (window.noctermBridge && window.noctermBridge.onInput) {
      window.noctermBridge.onInput(data);
    }
  }

  writeToTerminal(data) {
    if (this.terminal) {
      this.terminal.write(data);
    }
  }

  handleResize(cols, rows) {
    if (window.noctermBridge) {
      window.noctermBridge.width = cols;
      window.noctermBridge.height = rows;
      if (window.noctermBridge.onResize) {
        window.noctermBridge.onResize(cols, rows);
      }
    }
  }

  async loadApp(scriptPath) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = scriptPath;
      script.onload = () => {
        this.appLoaded = true;
        setTimeout(resolve, 100);
      };
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  focus() {
    if (this.terminal) {
      this.terminal.focus();
    }
  }

  // Send a key sequence to the terminal (for switching demos from outside)
  sendKey(key) {
    if (window.noctermBridge && window.noctermBridge.onInput) {
      window.noctermBridge.onInput(key);
    }
  }

  // Switch to a specific demo by index (0-3)
  // Sends number keys 1-4 which the app listens for
  switchToDemo(index) {
    // Send the number key corresponding to the demo (1-4)
    const key = String(index + 1);  // 0 -> '1', 1 -> '2', etc.
    this.sendKey(key);
    window.currentDemoIndex = index;
  }

  dispose() {
    if (this.terminal) {
      this.terminal.dispose();
      this.terminal = null;
    }
    if (window.noctermBridge) {
      delete window.noctermBridge;
    }
  }
}

// Factory function
async function createEmbeddedTerminal(containerId, appPath, options = {}) {
  const terminal = new EmbeddedTerminal(containerId, options);
  await terminal.initialize();
  if (appPath) {
    await terminal.loadApp(appPath);
    terminal.focus();
  }
  return terminal;
}

window.EmbeddedTerminal = EmbeddedTerminal;
window.createEmbeddedTerminal = createEmbeddedTerminal;
