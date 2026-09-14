import 'package:flutter/services.dart';

/// Servicio para gestionar los permisos de acceso a archivos en Android.
class PermissionService {
  static const MethodChannel _channel = MethodChannel('otune/permissions');

  /// Solicita acceso a archivos multimedia locales.
  ///
  /// En Android 13+ se solicitan READ_MEDIA_AUDIO y READ_MEDIA_VIDEO.
  /// En versiones anteriores se solicita READ_EXTERNAL_STORAGE. El acceso a
  /// archivos .lrc se obtiene al seleccionar la carpeta mediante el selector
  /// del sistema, no mediante un permiso multimedia independiente.
  Future<bool> requestMediaPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('requestMediaPermissions') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
