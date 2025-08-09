import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'valhalla_flutter_bindings_generated.dart' as native;

const String _libName = 'valhalla_flutter';

/// The dynamic library in which the symbols for [ValhallaFlutterBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final _bindings = native.ValhallaFlutterBindings(_dylib);

class ValhallaActor implements Finalizable {
  static final _finalizer =
      NativeFinalizer(_bindings.addresses.valhalla_actor_destroy.cast());

  final Pointer<native.ValhallaActor> _nativeInstance;

  bool _destroyed = false;

  ValhallaActor._(this._nativeInstance);

  factory ValhallaActor(String config) {
    final nativeInstance =
        _bindings.valhalla_actor_create(config.toNativeUtf8().cast<Char>());
    final actor = ValhallaActor._(nativeInstance);
    _finalizer.attach(actor, nativeInstance.cast(), detach: actor);
    return actor;
  }

  String act(native.ValhallaAction action, String request) {
    if (_destroyed) {
      throw StateError("Actor has been destroyed");
    }

    var cStr = _bindings.valhalla_actor_act(
        _nativeInstance, action, request.toNativeUtf8().cast<Char>());
    final result = cStr.cast<Utf8>().toDartString();
    malloc.free(cStr);
    return result;
  }

  void destroy() {
    if (_destroyed) {
      return;
    }

    _destroyed = true;
    _finalizer.detach(this);
    _bindings.valhalla_actor_destroy(_nativeInstance);
  }
}
