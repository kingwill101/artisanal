import 'dart:async';
import 'dart:convert';

import 'package:json_schema_builder/json_schema_builder.dart';

const remotePluginProtocolVersion = 'artisanal.remote_surface.v1alpha1';

typedef JsonObject = Map<String, Object?>;

enum RemotePluginMessageType {
  hostHello('host.hello'),
  pluginHello('plugin.hello'),
  pluginSurfaceOpen('plugin.surface.open'),
  pluginSurfaceResize('plugin.surface.resize'),
  pluginSurfaceClose('plugin.surface.close'),
  pluginSurfaceFrame('plugin.surface.frame'),
  pluginClipboardRead('plugin.clipboard.read'),
  pluginClipboardWrite('plugin.clipboard.write'),
  pluginUrlOpen('plugin.url.open'),
  pluginNotify('plugin.notify'),
  hostInputKey('host.input.key'),
  hostInputMouse('host.input.mouse'),
  hostInputFocus('host.input.focus'),
  hostInputBlur('host.input.blur'),
  hostClipboardRead('host.clipboard.read'),
  hostClipboardWrite('host.clipboard.write'),
  hostUrlOpen('host.url.open'),
  hostNotify('host.notify');

  const RemotePluginMessageType(this.wireName);

  final String wireName;

  static RemotePluginMessageType parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin message type: $value',
      ),
    );
  }
}

enum RemotePluginSurfaceKind {
  panel('panel'),
  popup('popup'),
  dialog('dialog'),
  overlay('overlay');

  const RemotePluginSurfaceKind(this.wireName);

  final String wireName;

  static RemotePluginSurfaceKind parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin surface kind: $value',
      ),
    );
  }
}

enum RemotePluginCursorShape {
  block('block'),
  underline('underline'),
  bar('bar');

  const RemotePluginCursorShape(this.wireName);

  final String wireName;

  static RemotePluginCursorShape parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin cursor shape: $value',
      ),
    );
  }
}

enum RemotePluginMouseAction {
  motion('motion'),
  press('press'),
  release('release'),
  wheel('wheel');

  const RemotePluginMouseAction(this.wireName);

  final String wireName;

  static RemotePluginMouseAction parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin mouse action: $value',
      ),
    );
  }
}

enum RemotePluginMouseButton {
  none('none'),
  left('left'),
  middle('middle'),
  right('right'),
  wheelUp('wheelUp'),
  wheelDown('wheelDown');

  const RemotePluginMouseButton(this.wireName);

  final String wireName;

  static RemotePluginMouseButton parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin mouse button: $value',
      ),
    );
  }
}

enum RemotePluginNotificationLevel {
  info('info'),
  success('success'),
  warning('warning'),
  error('error');

  const RemotePluginNotificationLevel(this.wireName);

  final String wireName;

  static RemotePluginNotificationLevel parse(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException(
        'Unsupported remote plugin notification level: $value',
      ),
    );
  }
}

final class RemotePluginAnchorRect {
  const RemotePluginAnchorRect({
    required this.column,
    required this.row,
    required this.width,
    required this.height,
  });

  final int column;
  final int row;
  final int width;
  final int height;

  factory RemotePluginAnchorRect.fromJson(JsonObject json) {
    return RemotePluginAnchorRect(
      column: _requireInt(json, 'column'),
      row: _requireInt(json, 'row'),
      width: _requireInt(json, 'width'),
      height: _requireInt(json, 'height'),
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      'column': column,
      'row': row,
      'width': width,
      'height': height,
    };
  }
}

final class RemotePluginCellAttributes {
  const RemotePluginCellAttributes({
    this.bold = false,
    this.dim = false,
    this.italic = false,
    this.underline = false,
    this.inverse = false,
  });

  final bool bold;
  final bool dim;
  final bool italic;
  final bool underline;
  final bool inverse;

  factory RemotePluginCellAttributes.fromJson(JsonObject json) {
    return RemotePluginCellAttributes(
      bold: _readBool(json, 'bold'),
      dim: _readBool(json, 'dim'),
      italic: _readBool(json, 'italic'),
      underline: _readBool(json, 'underline'),
      inverse: _readBool(json, 'inverse'),
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      if (bold) 'bold': bold,
      if (dim) 'dim': dim,
      if (italic) 'italic': italic,
      if (underline) 'underline': underline,
      if (inverse) 'inverse': inverse,
    };
  }
}

final class RemotePluginFrameCell {
  const RemotePluginFrameCell({
    required this.column,
    required this.row,
    required this.symbol,
    this.width = 1,
    this.foreground,
    this.background,
    this.attributes = const RemotePluginCellAttributes(),
  });

  final int column;
  final int row;
  final String symbol;
  final int width;
  final String? foreground;
  final String? background;
  final RemotePluginCellAttributes attributes;

  factory RemotePluginFrameCell.fromJson(JsonObject json) {
    final attributesValue = json['attributes'];
    return RemotePluginFrameCell(
      column: _requireInt(json, 'column'),
      row: _requireInt(json, 'row'),
      symbol: _requireString(json, 'symbol'),
      width: _readInt(json, 'width', fallback: 1),
      foreground: _readStringOrNull(json, 'foreground'),
      background: _readStringOrNull(json, 'background'),
      attributes: attributesValue is Map<Object?, Object?>
          ? RemotePluginCellAttributes.fromJson(
              _castJsonObject(attributesValue),
            )
          : const RemotePluginCellAttributes(),
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      'column': column,
      'row': row,
      'symbol': symbol,
      if (width != 1) 'width': width,
      if (foreground != null) 'foreground': foreground,
      if (background != null) 'background': background,
      if (attributes.toJson().isNotEmpty) 'attributes': attributes.toJson(),
    };
  }
}

final class RemotePluginCursor {
  const RemotePluginCursor({
    required this.column,
    required this.row,
    this.visible = true,
    this.shape = RemotePluginCursorShape.block,
    this.blink = false,
  });

  final int column;
  final int row;
  final bool visible;
  final RemotePluginCursorShape shape;
  final bool blink;

  factory RemotePluginCursor.fromJson(JsonObject json) {
    final shapeValue = json['shape'];
    return RemotePluginCursor(
      column: _requireInt(json, 'column'),
      row: _requireInt(json, 'row'),
      visible: _readBool(json, 'visible', fallback: true),
      shape: shapeValue is String
          ? RemotePluginCursorShape.parse(shapeValue)
          : RemotePluginCursorShape.block,
      blink: _readBool(json, 'blink'),
    );
  }

  JsonObject toJson() {
    return <String, Object?>{
      'column': column,
      'row': row,
      if (!visible) 'visible': visible,
      if (shape != RemotePluginCursorShape.block) 'shape': shape.wireName,
      if (blink) 'blink': blink,
    };
  }
}

sealed class RemotePluginMessage {
  const RemotePluginMessage();

  RemotePluginMessageType get messageType;

  JsonObject get payloadJson;

  JsonObject toJson() {
    return <String, Object?>{
      'protocol': remotePluginProtocolVersion,
      'type': messageType.wireName,
      'payload': payloadJson,
    };
  }

  String encodeJson() => jsonEncode(toJson());

  static RemotePluginMessage fromJson(JsonObject json) {
    final type = RemotePluginMessageType.parse(_requireString(json, 'type'));
    final payload = _requireObject(json, 'payload');
    return switch (type) {
      RemotePluginMessageType.hostHello => RemotePluginHostHello.fromPayload(
        payload,
      ),
      RemotePluginMessageType.pluginHello => RemotePluginHello.fromPayload(
        payload,
      ),
      RemotePluginMessageType.pluginSurfaceOpen =>
        RemotePluginSurfaceOpen.fromPayload(payload),
      RemotePluginMessageType.pluginSurfaceResize =>
        RemotePluginSurfaceResize.fromPayload(payload),
      RemotePluginMessageType.pluginSurfaceClose =>
        RemotePluginSurfaceClose.fromPayload(payload),
      RemotePluginMessageType.pluginSurfaceFrame =>
        RemotePluginFrame.fromPayload(payload),
      RemotePluginMessageType.pluginClipboardRead =>
        RemotePluginClipboardReadRequest.fromPayload(payload),
      RemotePluginMessageType.pluginClipboardWrite =>
        RemotePluginClipboardWriteRequest.fromPayload(payload),
      RemotePluginMessageType.pluginUrlOpen =>
        RemotePluginOpenUrlRequest.fromPayload(payload),
      RemotePluginMessageType.pluginNotify =>
        RemotePluginNotificationRequest.fromPayload(payload),
      RemotePluginMessageType.hostInputKey => RemotePluginKeyInput.fromPayload(
        payload,
      ),
      RemotePluginMessageType.hostInputMouse =>
        RemotePluginMouseInput.fromPayload(payload),
      RemotePluginMessageType.hostInputFocus =>
        RemotePluginFocusInput.fromPayload(payload),
      RemotePluginMessageType.hostInputBlur =>
        RemotePluginBlurInput.fromPayload(payload),
      RemotePluginMessageType.hostClipboardRead =>
        RemotePluginClipboardReadResponse.fromPayload(payload),
      RemotePluginMessageType.hostClipboardWrite =>
        RemotePluginClipboardWriteResponse.fromPayload(payload),
      RemotePluginMessageType.hostUrlOpen =>
        RemotePluginOpenUrlResponse.fromPayload(payload),
      RemotePluginMessageType.hostNotify =>
        RemotePluginNotificationResponse.fromPayload(payload),
    };
  }

  static Future<RemotePluginMessage> decodeJson(
    String source, {
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
  }) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<Object?, Object?>) {
      throw FormatException(
        'Remote plugin message must decode to a JSON object.',
      );
    }
    final json = _castJsonObject(decoded);
    await validator.validateJsonOrThrow(json);
    return RemotePluginMessage.fromJson(json);
  }
}

final class RemotePluginHostHello extends RemotePluginMessage {
  const RemotePluginHostHello({
    required this.hostName,
    required this.hostVersion,
    this.capabilities = const <String>[],
  });

  final String hostName;
  final String hostVersion;
  final List<String> capabilities;

  factory RemotePluginHostHello.fromPayload(JsonObject payload) {
    return RemotePluginHostHello(
      hostName: _requireString(payload, 'hostName'),
      hostVersion: _requireString(payload, 'hostVersion'),
      capabilities: _readStringList(payload, 'capabilities'),
    );
  }

  @override
  RemotePluginMessageType get messageType => RemotePluginMessageType.hostHello;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'hostName': hostName,
    'hostVersion': hostVersion,
    if (capabilities.isNotEmpty) 'capabilities': capabilities,
  };
}

final class RemotePluginHello extends RemotePluginMessage {
  const RemotePluginHello({
    required this.pluginId,
    required this.pluginVersion,
    this.displayName,
    this.capabilities = const <String>[],
  });

  final String pluginId;
  final String pluginVersion;
  final String? displayName;
  final List<String> capabilities;

  factory RemotePluginHello.fromPayload(JsonObject payload) {
    return RemotePluginHello(
      pluginId: _requireString(payload, 'pluginId'),
      pluginVersion: _requireString(payload, 'pluginVersion'),
      displayName: _readStringOrNull(payload, 'displayName'),
      capabilities: _readStringList(payload, 'capabilities'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginHello;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'pluginId': pluginId,
    'pluginVersion': pluginVersion,
    if (displayName != null) 'displayName': displayName,
    if (capabilities.isNotEmpty) 'capabilities': capabilities,
  };
}

final class RemotePluginSurfaceOpen extends RemotePluginMessage {
  const RemotePluginSurfaceOpen({
    required this.surfaceId,
    required this.kind,
    required this.width,
    required this.height,
    this.title,
    this.slot,
    this.parentSurfaceId,
    this.anchor,
  });

  final String surfaceId;
  final RemotePluginSurfaceKind kind;
  final int width;
  final int height;
  final String? title;
  final String? slot;
  final String? parentSurfaceId;
  final RemotePluginAnchorRect? anchor;

  factory RemotePluginSurfaceOpen.fromPayload(JsonObject payload) {
    final anchorValue = payload['anchor'];
    return RemotePluginSurfaceOpen(
      surfaceId: _requireString(payload, 'surfaceId'),
      kind: RemotePluginSurfaceKind.parse(_requireString(payload, 'kind')),
      width: _requireInt(payload, 'width'),
      height: _requireInt(payload, 'height'),
      title: _readStringOrNull(payload, 'title'),
      slot: _readStringOrNull(payload, 'slot'),
      parentSurfaceId: _readStringOrNull(payload, 'parentSurfaceId'),
      anchor: anchorValue is Map<Object?, Object?>
          ? RemotePluginAnchorRect.fromJson(_castJsonObject(anchorValue))
          : null,
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginSurfaceOpen;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    'kind': kind.wireName,
    'width': width,
    'height': height,
    if (title != null) 'title': title,
    if (slot != null) 'slot': slot,
    if (parentSurfaceId != null) 'parentSurfaceId': parentSurfaceId,
    if (anchor != null) 'anchor': anchor!.toJson(),
  };
}

final class RemotePluginSurfaceResize extends RemotePluginMessage {
  const RemotePluginSurfaceResize({
    required this.surfaceId,
    required this.width,
    required this.height,
  });

  final String surfaceId;
  final int width;
  final int height;

  factory RemotePluginSurfaceResize.fromPayload(JsonObject payload) {
    return RemotePluginSurfaceResize(
      surfaceId: _requireString(payload, 'surfaceId'),
      width: _requireInt(payload, 'width'),
      height: _requireInt(payload, 'height'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginSurfaceResize;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    'width': width,
    'height': height,
  };
}

final class RemotePluginSurfaceClose extends RemotePluginMessage {
  const RemotePluginSurfaceClose({required this.surfaceId, this.reason});

  final String surfaceId;
  final String? reason;

  factory RemotePluginSurfaceClose.fromPayload(JsonObject payload) {
    return RemotePluginSurfaceClose(
      surfaceId: _requireString(payload, 'surfaceId'),
      reason: _readStringOrNull(payload, 'reason'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginSurfaceClose;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    if (reason != null) 'reason': reason,
  };
}

final class RemotePluginFrame extends RemotePluginMessage {
  const RemotePluginFrame({
    required this.surfaceId,
    required this.width,
    required this.height,
    required this.cells,
    this.cursor,
  });

  final String surfaceId;
  final int width;
  final int height;
  final List<RemotePluginFrameCell> cells;
  final RemotePluginCursor? cursor;

  factory RemotePluginFrame.fromPayload(JsonObject payload) {
    final cursorValue = payload['cursor'];
    return RemotePluginFrame(
      surfaceId: _requireString(payload, 'surfaceId'),
      width: _requireInt(payload, 'width'),
      height: _requireInt(payload, 'height'),
      cells: _readObjectList(
        payload,
        'cells',
      ).map(RemotePluginFrameCell.fromJson).toList(growable: false),
      cursor: cursorValue is Map<Object?, Object?>
          ? RemotePluginCursor.fromJson(_castJsonObject(cursorValue))
          : null,
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginSurfaceFrame;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    'width': width,
    'height': height,
    'cells': cells.map((cell) => cell.toJson()).toList(growable: false),
    if (cursor != null) 'cursor': cursor!.toJson(),
  };
}

final class RemotePluginKeyInput extends RemotePluginMessage {
  const RemotePluginKeyInput({
    required this.surfaceId,
    required this.key,
    this.code,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final String surfaceId;
  final String key;
  final String? code;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool meta;

  factory RemotePluginKeyInput.fromPayload(JsonObject payload) {
    return RemotePluginKeyInput(
      surfaceId: _requireString(payload, 'surfaceId'),
      key: _requireString(payload, 'key'),
      code: _readStringOrNull(payload, 'code'),
      ctrl: _readBool(payload, 'ctrl'),
      alt: _readBool(payload, 'alt'),
      shift: _readBool(payload, 'shift'),
      meta: _readBool(payload, 'meta'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostInputKey;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    'key': key,
    if (code != null) 'code': code,
    if (ctrl) 'ctrl': ctrl,
    if (alt) 'alt': alt,
    if (shift) 'shift': shift,
    if (meta) 'meta': meta,
  };
}

final class RemotePluginClipboardReadRequest extends RemotePluginMessage {
  const RemotePluginClipboardReadRequest({
    required this.requestId,
    this.selection = 'c',
  });

  final String requestId;
  final String selection;

  factory RemotePluginClipboardReadRequest.fromPayload(JsonObject payload) {
    return RemotePluginClipboardReadRequest(
      requestId: _requireString(payload, 'requestId'),
      selection: _readStringOrNull(payload, 'selection') ?? 'c',
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginClipboardRead;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    if (selection != 'c') 'selection': selection,
  };
}

final class RemotePluginClipboardWriteRequest extends RemotePluginMessage {
  const RemotePluginClipboardWriteRequest({
    required this.requestId,
    required this.text,
    this.selection = 'c',
  });

  final String requestId;
  final String text;
  final String selection;

  factory RemotePluginClipboardWriteRequest.fromPayload(JsonObject payload) {
    return RemotePluginClipboardWriteRequest(
      requestId: _requireString(payload, 'requestId'),
      text: _requireString(payload, 'text', allowEmpty: true),
      selection: _readStringOrNull(payload, 'selection') ?? 'c',
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginClipboardWrite;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    'text': text,
    if (selection != 'c') 'selection': selection,
  };
}

final class RemotePluginOpenUrlRequest extends RemotePluginMessage {
  const RemotePluginOpenUrlRequest({
    required this.requestId,
    required this.url,
  });

  final String requestId;
  final String url;

  factory RemotePluginOpenUrlRequest.fromPayload(JsonObject payload) {
    return RemotePluginOpenUrlRequest(
      requestId: _requireString(payload, 'requestId'),
      url: _requireUriString(payload, 'url'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginUrlOpen;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    'url': url,
  };
}

final class RemotePluginNotificationRequest extends RemotePluginMessage {
  const RemotePluginNotificationRequest({
    required this.requestId,
    required this.message,
    this.title,
    this.level = RemotePluginNotificationLevel.info,
  });

  final String requestId;
  final String message;
  final String? title;
  final RemotePluginNotificationLevel level;

  factory RemotePluginNotificationRequest.fromPayload(JsonObject payload) {
    final levelValue = payload['level'];
    return RemotePluginNotificationRequest(
      requestId: _requireString(payload, 'requestId'),
      message: _requireString(payload, 'message'),
      title: _readStringOrNull(payload, 'title'),
      level: levelValue is String
          ? RemotePluginNotificationLevel.parse(levelValue)
          : RemotePluginNotificationLevel.info,
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.pluginNotify;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    'message': message,
    if (title != null) 'title': title,
    if (level != RemotePluginNotificationLevel.info)
      'level': level.wireName,
  };
}

final class RemotePluginMouseInput extends RemotePluginMessage {
  const RemotePluginMouseInput({
    required this.surfaceId,
    required this.action,
    required this.button,
    required this.column,
    required this.row,
    this.ctrl = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  final String surfaceId;
  final RemotePluginMouseAction action;
  final RemotePluginMouseButton button;
  final int column;
  final int row;
  final bool ctrl;
  final bool alt;
  final bool shift;
  final bool meta;

  factory RemotePluginMouseInput.fromPayload(JsonObject payload) {
    return RemotePluginMouseInput(
      surfaceId: _requireString(payload, 'surfaceId'),
      action: RemotePluginMouseAction.parse(_requireString(payload, 'action')),
      button: RemotePluginMouseButton.parse(_requireString(payload, 'button')),
      column: _requireInt(payload, 'column'),
      row: _requireInt(payload, 'row'),
      ctrl: _readBool(payload, 'ctrl'),
      alt: _readBool(payload, 'alt'),
      shift: _readBool(payload, 'shift'),
      meta: _readBool(payload, 'meta'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostInputMouse;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'surfaceId': surfaceId,
    'action': action.wireName,
    'button': button.wireName,
    'column': column,
    'row': row,
    if (ctrl) 'ctrl': ctrl,
    if (alt) 'alt': alt,
    if (shift) 'shift': shift,
    if (meta) 'meta': meta,
  };
}

final class RemotePluginFocusInput extends RemotePluginMessage {
  const RemotePluginFocusInput({required this.surfaceId});

  final String surfaceId;

  factory RemotePluginFocusInput.fromPayload(JsonObject payload) {
    return RemotePluginFocusInput(
      surfaceId: _requireString(payload, 'surfaceId'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostInputFocus;

  @override
  JsonObject get payloadJson => <String, Object?>{'surfaceId': surfaceId};
}

final class RemotePluginBlurInput extends RemotePluginMessage {
  const RemotePluginBlurInput({required this.surfaceId});

  final String surfaceId;

  factory RemotePluginBlurInput.fromPayload(JsonObject payload) {
    return RemotePluginBlurInput(
      surfaceId: _requireString(payload, 'surfaceId'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostInputBlur;

  @override
  JsonObject get payloadJson => <String, Object?>{'surfaceId': surfaceId};
}

final class RemotePluginClipboardReadResponse extends RemotePluginMessage {
  const RemotePluginClipboardReadResponse({
    required this.requestId,
    this.selection = 'c',
    this.text,
    this.error,
  });

  final String requestId;
  final String selection;
  final String? text;
  final String? error;

  factory RemotePluginClipboardReadResponse.fromPayload(JsonObject payload) {
    return RemotePluginClipboardReadResponse(
      requestId: _requireString(payload, 'requestId'),
      selection: _readStringOrNull(payload, 'selection') ?? 'c',
      text: _readStringOrNull(payload, 'text', allowEmpty: true),
      error: _readStringOrNull(payload, 'error'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostClipboardRead;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    if (selection != 'c') 'selection': selection,
    if (text != null) 'text': text,
    if (error != null) 'error': error,
  };
}

final class RemotePluginClipboardWriteResponse extends RemotePluginMessage {
  const RemotePluginClipboardWriteResponse({
    required this.requestId,
    this.selection = 'c',
    this.accepted = true,
    this.error,
  });

  final String requestId;
  final String selection;
  final bool accepted;
  final String? error;

  factory RemotePluginClipboardWriteResponse.fromPayload(JsonObject payload) {
    return RemotePluginClipboardWriteResponse(
      requestId: _requireString(payload, 'requestId'),
      selection: _readStringOrNull(payload, 'selection') ?? 'c',
      accepted: _readBool(payload, 'accepted', fallback: true),
      error: _readStringOrNull(payload, 'error'),
    );
  }

  @override
  RemotePluginMessageType get messageType =>
      RemotePluginMessageType.hostClipboardWrite;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    if (selection != 'c') 'selection': selection,
    if (!accepted) 'accepted': accepted,
    if (error != null) 'error': error,
  };
}

final class RemotePluginOpenUrlResponse extends RemotePluginMessage {
  const RemotePluginOpenUrlResponse({
    required this.requestId,
    this.accepted = true,
    this.error,
  });

  final String requestId;
  final bool accepted;
  final String? error;

  factory RemotePluginOpenUrlResponse.fromPayload(JsonObject payload) {
    return RemotePluginOpenUrlResponse(
      requestId: _requireString(payload, 'requestId'),
      accepted: _readBool(payload, 'accepted', fallback: true),
      error: _readStringOrNull(payload, 'error'),
    );
  }

  @override
  RemotePluginMessageType get messageType => RemotePluginMessageType.hostUrlOpen;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    if (!accepted) 'accepted': accepted,
    if (error != null) 'error': error,
  };
}

final class RemotePluginNotificationResponse extends RemotePluginMessage {
  const RemotePluginNotificationResponse({
    required this.requestId,
    this.accepted = true,
    this.error,
  });

  final String requestId;
  final bool accepted;
  final String? error;

  factory RemotePluginNotificationResponse.fromPayload(JsonObject payload) {
    return RemotePluginNotificationResponse(
      requestId: _requireString(payload, 'requestId'),
      accepted: _readBool(payload, 'accepted', fallback: true),
      error: _readStringOrNull(payload, 'error'),
    );
  }

  @override
  RemotePluginMessageType get messageType => RemotePluginMessageType.hostNotify;

  @override
  JsonObject get payloadJson => <String, Object?>{
    'requestId': requestId,
    if (!accepted) 'accepted': accepted,
    if (error != null) 'error': error,
  };
}

final class RemotePluginProtocolSchemas {
  RemotePluginProtocolSchemas._();

  static final Schema anchorRect = S.object(
    required: const ['column', 'row', 'width', 'height'],
    properties: <String, Schema>{
      'column': S.integer(minimum: 0),
      'row': S.integer(minimum: 0),
      'width': S.integer(minimum: 1),
      'height': S.integer(minimum: 1),
    },
    additionalProperties: false,
  );

  static final Schema cellAttributes = S.object(
    properties: <String, Schema>{
      'bold': S.boolean(),
      'dim': S.boolean(),
      'italic': S.boolean(),
      'underline': S.boolean(),
      'inverse': S.boolean(),
    },
    additionalProperties: false,
  );

  static final Schema frameCell = S.object(
    required: const ['column', 'row', 'symbol'],
    properties: <String, Schema>{
      'column': S.integer(minimum: 0),
      'row': S.integer(minimum: 0),
      'symbol': S.string(minLength: 1),
      'width': S.integer(minimum: 1),
      'foreground': S.string(minLength: 1),
      'background': S.string(minLength: 1),
      'attributes': cellAttributes,
    },
    additionalProperties: false,
  );

  static final Schema cursor = S.object(
    required: const ['column', 'row'],
    properties: <String, Schema>{
      'column': S.integer(minimum: 0),
      'row': S.integer(minimum: 0),
      'visible': S.boolean(),
      'shape': _enumString(
        RemotePluginCursorShape.values.map((value) => value.wireName),
      ),
      'blink': S.boolean(),
    },
    additionalProperties: false,
  );

  static final Schema hostHelloPayload = S.object(
    required: const ['hostName', 'hostVersion'],
    properties: <String, Schema>{
      'hostName': S.string(minLength: 1),
      'hostVersion': S.string(minLength: 1),
      'capabilities': _stringList(),
    },
    additionalProperties: false,
  );

  static final Schema pluginHelloPayload = S.object(
    required: const ['pluginId', 'pluginVersion'],
    properties: <String, Schema>{
      'pluginId': S.string(minLength: 1),
      'pluginVersion': S.string(minLength: 1),
      'displayName': S.string(minLength: 1),
      'capabilities': _stringList(),
    },
    additionalProperties: false,
  );

  static final Schema pluginSurfaceOpenPayload = S.object(
    required: const ['surfaceId', 'kind', 'width', 'height'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'kind': _enumString(
        RemotePluginSurfaceKind.values.map((value) => value.wireName),
      ),
      'width': S.integer(minimum: 1),
      'height': S.integer(minimum: 1),
      'title': S.string(minLength: 1),
      'slot': S.string(minLength: 1),
      'parentSurfaceId': S.string(minLength: 1),
      'anchor': anchorRect,
    },
    additionalProperties: false,
  );

  static final Schema pluginSurfaceResizePayload = S.object(
    required: const ['surfaceId', 'width', 'height'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'width': S.integer(minimum: 1),
      'height': S.integer(minimum: 1),
    },
    additionalProperties: false,
  );

  static final Schema pluginSurfaceClosePayload = S.object(
    required: const ['surfaceId'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'reason': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema pluginSurfaceFramePayload = S.object(
    required: const ['surfaceId', 'width', 'height', 'cells'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'width': S.integer(minimum: 1),
      'height': S.integer(minimum: 1),
      'cells': S.list(items: frameCell),
      'cursor': cursor,
    },
    additionalProperties: false,
  );

  static final Schema pluginClipboardReadPayload = S.object(
    required: const ['requestId'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'selection': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema pluginClipboardWritePayload = S.object(
    required: const ['requestId', 'text'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'text': S.string(),
      'selection': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema pluginUrlOpenPayload = S.object(
    required: const ['requestId', 'url'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'url': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema pluginNotifyPayload = S.object(
    required: const ['requestId', 'message'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'message': S.string(minLength: 1),
      'title': S.string(minLength: 1),
      'level': _enumString(
        RemotePluginNotificationLevel.values.map((value) => value.wireName),
      ),
    },
    additionalProperties: false,
  );

  static final Schema hostInputKeyPayload = S.object(
    required: const ['surfaceId', 'key'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'key': S.string(minLength: 1),
      'code': S.string(minLength: 1),
      'ctrl': S.boolean(),
      'alt': S.boolean(),
      'shift': S.boolean(),
      'meta': S.boolean(),
    },
    additionalProperties: false,
  );

  static final Schema hostInputMousePayload = S.object(
    required: const ['surfaceId', 'action', 'button', 'column', 'row'],
    properties: <String, Schema>{
      'surfaceId': S.string(minLength: 1),
      'action': _enumString(
        RemotePluginMouseAction.values.map((value) => value.wireName),
      ),
      'button': _enumString(
        RemotePluginMouseButton.values.map((value) => value.wireName),
      ),
      'column': S.integer(minimum: 0),
      'row': S.integer(minimum: 0),
      'ctrl': S.boolean(),
      'alt': S.boolean(),
      'shift': S.boolean(),
      'meta': S.boolean(),
    },
    additionalProperties: false,
  );

  static final Schema hostInputFocusPayload = S.object(
    required: const ['surfaceId'],
    properties: <String, Schema>{'surfaceId': S.string(minLength: 1)},
    additionalProperties: false,
  );

  static final Schema hostInputBlurPayload = S.object(
    required: const ['surfaceId'],
    properties: <String, Schema>{'surfaceId': S.string(minLength: 1)},
    additionalProperties: false,
  );

  static final Schema hostClipboardReadPayload = S.object(
    required: const ['requestId'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'selection': S.string(minLength: 1),
      'text': S.string(),
      'error': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema hostClipboardWritePayload = S.object(
    required: const ['requestId'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'selection': S.string(minLength: 1),
      'accepted': S.boolean(),
      'error': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema hostUrlOpenPayload = S.object(
    required: const ['requestId'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'accepted': S.boolean(),
      'error': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Schema hostNotifyPayload = S.object(
    required: const ['requestId'],
    properties: <String, Schema>{
      'requestId': S.string(minLength: 1),
      'accepted': S.boolean(),
      'error': S.string(minLength: 1),
    },
    additionalProperties: false,
  );

  static final Map<RemotePluginMessageType, Schema> byType =
      <RemotePluginMessageType, Schema>{
        RemotePluginMessageType.hostHello: _typedEnvelope(
          RemotePluginMessageType.hostHello,
          hostHelloPayload,
        ),
        RemotePluginMessageType.pluginHello: _typedEnvelope(
          RemotePluginMessageType.pluginHello,
          pluginHelloPayload,
        ),
        RemotePluginMessageType.pluginSurfaceOpen: _typedEnvelope(
          RemotePluginMessageType.pluginSurfaceOpen,
          pluginSurfaceOpenPayload,
        ),
        RemotePluginMessageType.pluginSurfaceResize: _typedEnvelope(
          RemotePluginMessageType.pluginSurfaceResize,
          pluginSurfaceResizePayload,
        ),
        RemotePluginMessageType.pluginSurfaceClose: _typedEnvelope(
          RemotePluginMessageType.pluginSurfaceClose,
          pluginSurfaceClosePayload,
        ),
        RemotePluginMessageType.pluginSurfaceFrame: _typedEnvelope(
          RemotePluginMessageType.pluginSurfaceFrame,
          pluginSurfaceFramePayload,
        ),
        RemotePluginMessageType.pluginClipboardRead: _typedEnvelope(
          RemotePluginMessageType.pluginClipboardRead,
          pluginClipboardReadPayload,
        ),
        RemotePluginMessageType.pluginClipboardWrite: _typedEnvelope(
          RemotePluginMessageType.pluginClipboardWrite,
          pluginClipboardWritePayload,
        ),
        RemotePluginMessageType.pluginUrlOpen: _typedEnvelope(
          RemotePluginMessageType.pluginUrlOpen,
          pluginUrlOpenPayload,
        ),
        RemotePluginMessageType.pluginNotify: _typedEnvelope(
          RemotePluginMessageType.pluginNotify,
          pluginNotifyPayload,
        ),
        RemotePluginMessageType.hostInputKey: _typedEnvelope(
          RemotePluginMessageType.hostInputKey,
          hostInputKeyPayload,
        ),
        RemotePluginMessageType.hostInputMouse: _typedEnvelope(
          RemotePluginMessageType.hostInputMouse,
          hostInputMousePayload,
        ),
        RemotePluginMessageType.hostInputFocus: _typedEnvelope(
          RemotePluginMessageType.hostInputFocus,
          hostInputFocusPayload,
        ),
        RemotePluginMessageType.hostInputBlur: _typedEnvelope(
          RemotePluginMessageType.hostInputBlur,
          hostInputBlurPayload,
        ),
        RemotePluginMessageType.hostClipboardRead: _typedEnvelope(
          RemotePluginMessageType.hostClipboardRead,
          hostClipboardReadPayload,
        ),
        RemotePluginMessageType.hostClipboardWrite: _typedEnvelope(
          RemotePluginMessageType.hostClipboardWrite,
          hostClipboardWritePayload,
        ),
        RemotePluginMessageType.hostUrlOpen: _typedEnvelope(
          RemotePluginMessageType.hostUrlOpen,
          hostUrlOpenPayload,
        ),
        RemotePluginMessageType.hostNotify: _typedEnvelope(
          RemotePluginMessageType.hostNotify,
          hostNotifyPayload,
        ),
      };

  static final Schema message = S.combined(
    $id: 'https://artisanal.dev/schemas/remote-surface-plugin-message.json',
    $schema: 'https://json-schema.org/draft/2020-12/schema',
    title: 'Artisanal Remote Surface Plugin Message',
    oneOf: byType.values.toList(growable: false),
  );

  static Schema schemaForType(RemotePluginMessageType type) {
    return byType[type] ??
        (throw ArgumentError.value(
          type,
          'type',
          'Unsupported remote plugin message type',
        ));
  }

  static Schema _typedEnvelope(RemotePluginMessageType type, Schema payload) {
    return S.object(
      required: const ['protocol', 'type', 'payload'],
      properties: <String, Schema>{
        'protocol': S.string(constValue: remotePluginProtocolVersion),
        'type': S.string(constValue: type.wireName),
        'payload': payload,
      },
      additionalProperties: false,
    );
  }
}

final class RemotePluginProtocolValidator {
  const RemotePluginProtocolValidator();

  Future<List<ValidationError>> validateJson(JsonObject json) {
    return RemotePluginProtocolSchemas.message.validate(json);
  }

  Future<List<ValidationError>> validateMessage(RemotePluginMessage message) {
    return validateJson(message.toJson());
  }

  Future<void> validateJsonOrThrow(JsonObject json) async {
    final errors = await validateJson(json);
    if (errors.isEmpty) {
      return;
    }
    throw RemotePluginProtocolValidationException(errors);
  }

  Future<void> validateMessageOrThrow(RemotePluginMessage message) {
    return validateJsonOrThrow(message.toJson());
  }
}

final class RemotePluginProtocolValidationException implements Exception {
  RemotePluginProtocolValidationException(this.errors);

  final List<ValidationError> errors;

  @override
  String toString() {
    final buffer = StringBuffer(
      'Remote plugin protocol validation failed with ${errors.length} error(s):',
    );
    for (final error in errors) {
      buffer
        ..write('\n- ')
        ..write(error.toErrorString());
    }
    return buffer.toString();
  }
}

Schema _enumString(Iterable<String> values) {
  return S.string(enumValues: values.cast<Object?>().toList(growable: false));
}

Schema _stringList() {
  return S.list(items: S.string(minLength: 1));
}

JsonObject _castJsonObject(Map<Object?, Object?> value) {
  return value.cast<String, Object?>();
}

JsonObject _requireObject(JsonObject json, String key) {
  final value = json[key];
  if (value is Map<Object?, Object?>) {
    return _castJsonObject(value);
  }
  throw FormatException('Expected "$key" to be a JSON object');
}

String _requireString(JsonObject json, String key, {bool allowEmpty = false}) {
  final value = json[key];
  if (value is String && (allowEmpty || value.isNotEmpty)) {
    return value;
  }
  throw FormatException(
    'Expected "$key" to be ${allowEmpty ? 'a string' : 'a non-empty string'}',
  );
}

String _requireUriString(JsonObject json, String key) {
  final value = _requireString(json, key);
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return value;
  }
  throw FormatException('Expected "$key" to be an absolute URI string');
}

String? _readStringOrNull(
  JsonObject json,
  String key, {
  bool allowEmpty = false,
}) {
  final value = json[key];
  return value is String && (allowEmpty || value.isNotEmpty) ? value : null;
}

int _requireInt(JsonObject json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('Expected "$key" to be an integer');
}

int _readInt(JsonObject json, String key, {required int fallback}) {
  final value = json[key];
  return value is int ? value : fallback;
}

bool _readBool(JsonObject json, String key, {bool fallback = false}) {
  final value = json[key];
  return value is bool ? value : fallback;
}

List<String> _readStringList(JsonObject json, String key) {
  final value = json[key];
  if (value is! List) {
    return const <String>[];
  }
  return value.whereType<String>().toList(growable: false);
}

List<JsonObject> _readObjectList(JsonObject json, String key) {
  final value = json[key];
  if (value is! List) {
    return const <JsonObject>[];
  }
  return value
      .whereType<Map<Object?, Object?>>()
      .map(_castJsonObject)
      .toList(growable: false);
}
