/**
 * nocterm xterm.js Host Integration
 *
 * This file bridges xterm.js (terminal UI) with nocterm apps (compiled to JS).
 *
 * Architecture:
 * - xterm.js handles rendering and user input
 * - nocterm app handles application logic
 * - This bridge connects them via window.noctermBridge
 *
 * Flow:
 * 1. Host initializes the bridge (window.noctermBridge)
 * 2. Host creates xterm.js terminal
 * 3. Host loads nocterm app (guest)
 * 4. Guest registers callbacks on the bridge
 * 5. User types in xterm.js → bridge → nocterm app
 * 6. Nocterm app outputs → bridge → xterm.js
 */

class NoctermTerminalHost {
  constructor(containerId) {
    this.containerId = containerId;
    this.terminal = null;
    this.fitAddon = null;
    this.appLoaded = false;

    // Check if xterm is available
    if (typeof Terminal === 'undefined') {
      throw new Error('xterm.js not loaded. Include xterm.js before terminal-host.js');
    }
  }

  /**
   * Initialize the terminal and nocterm bridge
   */
  async initialize() {
    // Create xterm.js terminal with reasonable initial size for TUI apps
    this.terminal = new Terminal({
      cursorBlink: true,
      fontFamily: '"Cascadia Code", "Fira Code", "JetBrains Mono", "Source Code Pro", "DejaVu Sans Mono", Monaco, Menlo, monospace',
      fontSize: 10,
      cols: 160,  // Wider for bento layout (ASCII title is 66 chars + sidebar)
      rows: 45,   // Taller for bento layout
      theme: {
        background: '#1e1e1e',
        foreground: '#d4d4d4',
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
    // Clear any existing content (like "Loading..." message)
    container.innerHTML = '';
    this.terminal.open(container);

    // Don't auto-fit - keep the fixed size we specified
    // The terminal will be centered in the container via CSS

    // Initialize the nocterm bridge BEFORE loading the app
    // This creates window.noctermBridge that the guest will use
    this.initializeBridge();

    // Set the terminal size on the bridge
    // The guest app will read this on startup
    this.updateBridgeSize();

    // Wire up xterm.js input to nocterm bridge
    this.terminal.onData(data => {
      console.log('xterm.js onData fired!');
      this.sendInputToGuest(data);
    });

    // Focus the terminal so it receives keyboard input
    this.terminal.focus();
    console.log('Terminal focused');

    // Handle terminal resize
    this.terminal.onResize(({ cols, rows }) => {
      this.handleResize(cols, rows);
    });

    // Note: We don't auto-resize on window resize
    // TUI apps work best with a fixed size

    console.log('nocterm terminal host initialized');
    console.log(`Terminal size: ${this.terminal.cols}x${this.terminal.rows}`);
  }

  /**
   * Initialize the nocterm bridge object on window.
   * This must be called BEFORE loading the guest app.
   */
  initializeBridge() {
    // Create the bridge object
    window.noctermBridge = {
      // Size (host writes, guest reads)
      width: null,
      height: null,

      // Guest → Host: Output from nocterm app
      onOutput: null,

      // Host → Guest: Input, resize, shutdown
      onInput: null,
      onResize: null,
      onShutdown: null,
    };

    // Set up the output handler
    // The guest will call this when it has output to display
    window.noctermBridge.onOutput = (data) => {
      this.writeToTerminal(data);
    };

    console.log('nocterm bridge initialized');
  }

  /**
   * Update the terminal size on the bridge.
   * The guest app reads this to know the current size.
   */
  updateBridgeSize() {
    if (!window.noctermBridge) {
      console.error('Bridge not initialized');
      return;
    }

    const cols = this.terminal.cols;
    const rows = this.terminal.rows;

    window.noctermBridge.width = cols;
    window.noctermBridge.height = rows;

    console.log(`Bridge size updated: ${cols}x${rows}`);
  }

  /**
   * Send input from xterm.js to the nocterm app via the bridge.
   */
  sendInputToGuest(data) {
    if (!window.noctermBridge) {
      console.error('Bridge not initialized');
      return;
    }

    // Debug: log input data
    console.log('Input received:', JSON.stringify(data), 'bytes:', [...data].map(c => c.charCodeAt(0)));

    // Call the guest's input handler if it's been registered
    if (window.noctermBridge.onInput) {
      console.log('Calling onInput...');
      window.noctermBridge.onInput(data);
      console.log('onInput called successfully');
    } else {
      // Guest hasn't registered yet - queue the input
      console.warn('Guest input handler not registered yet');
    }
  }

  /**
   * Write output from nocterm app to xterm.js.
   * This is called by the bridge's onOutput callback.
   */
  writeToTerminal(data) {
    if (!this.terminal) {
      console.error('Terminal not initialized');
      return;
    }

    this.terminal.write(data);
  }

  /**
   * Handle terminal resize events.
   */
  handleResize(cols, rows) {
    if (!window.noctermBridge) {
      console.error('Bridge not initialized');
      return;
    }

    // Update size on bridge
    window.noctermBridge.width = cols;
    window.noctermBridge.height = rows;

    // Notify the guest app about the resize
    if (window.noctermBridge.onResize) {
      window.noctermBridge.onResize(cols, rows);
    }

    console.log(`Terminal resized: ${cols}x${rows}`);
  }

  /**
   * Load a nocterm app (compiled JS file).
   * The app will automatically connect to the bridge.
   */
  async loadApp(scriptPath) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = scriptPath;
      script.onload = () => {
        console.log(`Loaded nocterm app: ${scriptPath}`);
        this.appLoaded = true;

        // Wait a bit for the app to initialize
        setTimeout(() => {
          // Check if the app connected
          if (window.noctermBridge.onInput) {
            console.log('Guest app connected to bridge');
            resolve();
          } else {
            console.warn('Guest app loaded but did not connect to bridge');
            resolve();
          }
        }, 100);
      };
      script.onerror = (error) => {
        console.error(`Failed to load nocterm app: ${scriptPath}`, error);
        reject(error);
      };
      document.head.appendChild(script);
    });
  }

  /**
   * Request the guest app to shut down.
   */
  shutdown() {
    if (window.noctermBridge && window.noctermBridge.onShutdown) {
      window.noctermBridge.onShutdown();
    }
  }

  /**
   * Reset the bridge for loading a new app.
   */
  reset() {
    if (window.noctermBridge) {
      window.noctermBridge.onInput = null;
      window.noctermBridge.onResize = null;
      window.noctermBridge.onShutdown = null;
    }
    this.appLoaded = false;
    console.log('Bridge reset');
  }

  /**
   * Clean up resources.
   */
  dispose() {
    if (this.terminal) {
      this.terminal.dispose();
      this.terminal = null;
    }
    if (window.noctermBridge) {
      delete window.noctermBridge;
    }
    console.log('Terminal host disposed');
  }

  /**
   * Fit terminal to container.
   */
  fit() {
    if (this.fitAddon) {
      this.fitAddon.fit();
    }
  }
}

// Make the class globally available
window.NoctermTerminalHost = NoctermTerminalHost;
