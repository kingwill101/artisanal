window.addEventListener('error', function(e) {
  var pre = document.createElement('pre');
  pre.style.color = 'red';
  pre.style.fontFamily = 'monospace';
  pre.style.padding = '20px';
  pre.textContent = 'Error: ' + (e.error ? (e.error.message || e.error) : e.message) + '\n' + (e.error ? e.error.stack || '' : '');
  document.body.appendChild(pre);
  console.error('Global error:', e.error || e.message);
});

window.addEventListener('unhandledrejection', function(e) {
  var pre = document.createElement('pre');
  pre.style.color = 'red';
  pre.style.fontFamily = 'monospace';
  pre.style.padding = '20px';
  pre.textContent = 'Unhandled Rejection: ' + (e.reason ? (e.reason.message || e.reason) : e) + '\n' + (e.reason ? e.reason.stack || '' : '');
  document.body.appendChild(pre);
  console.error('Unhandled rejection:', e.reason);
});

(async function () {
  let dart2wasm_runtime;
  let moduleInstance;
  try {
    const dartModulePromise = WebAssembly.compileStreaming(fetch('main.wasm'));
    const imports = {};
    dart2wasm_runtime = await import('./main.mjs');
    moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, imports);
  } catch (exception) {
    console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
    console.error('See https://dart.dev/web/wasm for more information.');
    var pre = document.createElement('pre');
    pre.style.color = 'red';
    pre.style.fontFamily = 'monospace';
    pre.style.padding = '20px';
    pre.textContent = 'Failed to instantiate: ' + (exception.message || exception);
    document.body.appendChild(pre);
  }

  if (moduleInstance) {
    try {
      await dart2wasm_runtime.invoke(moduleInstance);
    } catch (exception) {
      console.error(`Exception while invoking: ${exception}`);
      var pre = document.createElement('pre');
      pre.style.color = 'red';
      pre.style.fontFamily = 'monospace';
      pre.style.padding = '20px';
      pre.textContent = 'Exception: ' + (exception.message || exception) + '\n' + (exception.stack || '');
      document.body.appendChild(pre);
    }
  }
})();
