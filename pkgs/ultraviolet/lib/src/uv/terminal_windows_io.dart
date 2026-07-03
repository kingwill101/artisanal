// Windows-only console (Win32 FFI) code; every entry point is a no-op on
// other platforms and when stdin is not a real console.
import 'dart:ffi';
import 'dart:io';

// Console input-mode flags (consoleapi / wincon.h).
const int _enableLineInput = 0x0002;
const int _enableEchoInput = 0x0004;
const int _enableMouseInput = 0x0010;
const int _enableQuickEditMode = 0x0040;
const int _enableExtendedFlags = 0x0080;
const int _enableVirtualTerminalInput = 0x0200;
const int _stdInputHandle = 0xFFFFFFF6; // (DWORD)-10
const int _lmemZeroInit = 0x0040;

typedef _GetStdHandleC = IntPtr Function(Uint32);
typedef _GetStdHandleD = int Function(int);
typedef _GetConsoleModeC = Int32 Function(IntPtr, Pointer<Uint32>);
typedef _GetConsoleModeD = int Function(int, Pointer<Uint32>);
typedef _SetConsoleModeC = Int32 Function(IntPtr, Uint32);
typedef _SetConsoleModeD = int Function(int, int);
typedef _LocalAllocC = IntPtr Function(Uint32, IntPtr);
typedef _LocalAllocD = int Function(int, int);
typedef _LocalFreeC = IntPtr Function(IntPtr);
typedef _LocalFreeD = int Function(int);

int? _savedMode;

/// Puts the Windows console **input** handle into virtual-terminal mode so
/// arrow keys, Home/End/PgUp/PgDn, function keys, Esc, Alt-modified keys and
/// mouse events reach stdin as the escape sequences [EventDecoder] parses.
///
/// Flipping Dart's `stdin.lineMode`/`echoMode` alone is not enough on
/// Windows: the console stays in legacy input mode, where those keys never
/// reach the byte stream at all (only plain characters do) and Alt-modified
/// characters arrive with the modifier stripped. Enabling
/// `ENABLE_VIRTUAL_TERMINAL_INPUT` is what makes them work; clearing
/// `ENABLE_QUICK_EDIT_MODE` lets mouse events through instead of being
/// captured as console text selection.
///
/// The previous mode is saved once for [restoreWindowsVtInput]. Call while
/// entering raw mode.
void enableWindowsVtInput() {
  if (!Platform.isWindows) return;
  final k32 = DynamicLibrary.open('kernel32.dll');
  final getStdHandle =
      k32.lookupFunction<_GetStdHandleC, _GetStdHandleD>('GetStdHandle');
  final getConsoleMode =
      k32.lookupFunction<_GetConsoleModeC, _GetConsoleModeD>('GetConsoleMode');
  final setConsoleMode =
      k32.lookupFunction<_SetConsoleModeC, _SetConsoleModeD>('SetConsoleMode');
  // Scratch DWORD from the Win32 heap so this file needs no allocator
  // dependency (package:ffi).
  final localAlloc =
      k32.lookupFunction<_LocalAllocC, _LocalAllocD>('LocalAlloc');
  final localFree = k32.lookupFunction<_LocalFreeC, _LocalFreeD>('LocalFree');

  final handle = getStdHandle(_stdInputHandle);
  final mem = localAlloc(_lmemZeroInit, 4);
  if (mem == 0) return;
  final modePtr = Pointer<Uint32>.fromAddress(mem);
  try {
    if (getConsoleMode(handle, modePtr) == 0) return; // not a console
    _savedMode ??= modePtr.value;
    final next = (modePtr.value |
            _enableVirtualTerminalInput |
            _enableExtendedFlags |
            _enableMouseInput) &
        ~(_enableQuickEditMode | _enableLineInput | _enableEchoInput);
    setConsoleMode(handle, next);
  } finally {
    localFree(mem);
  }
}

/// Restores the console input mode captured by the first
/// [enableWindowsVtInput] call. No-op if it never ran.
void restoreWindowsVtInput() {
  if (!Platform.isWindows) return;
  final saved = _savedMode;
  if (saved == null) return;
  final k32 = DynamicLibrary.open('kernel32.dll');
  final getStdHandle =
      k32.lookupFunction<_GetStdHandleC, _GetStdHandleD>('GetStdHandle');
  final setConsoleMode =
      k32.lookupFunction<_SetConsoleModeC, _SetConsoleModeD>('SetConsoleMode');
  setConsoleMode(getStdHandle(_stdInputHandle), saved);
  _savedMode = null;
}
