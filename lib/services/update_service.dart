import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateService {
  static const String _repoUrl =
      'https://api.github.com/repos/CarlosEvCode/gastos_casa/releases/latest';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final dio = Dio();
      final response = await dio.get(_repoUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String latestVersionTag = data['tag_name'] as String;
        final String latestVersion = latestVersionTag.replaceAll('v', '');

        final packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Encuentra el asset adecuado
          final List<dynamic> assets = data['assets'];
          String? downloadUrl;

          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          final List<String> supportedAbis = androidInfo.supportedAbis;

          // Intentamos buscar por arquitectura primero
          for (var asset in assets) {
            String assetName = asset['name'].toString().toLowerCase();
            if (supportedAbis.contains('arm64-v8a') &&
                assetName.contains('arm64-v8a')) {
              downloadUrl = asset['browser_download_url'];
              break;
            } else if (supportedAbis.contains('armeabi-v7a') &&
                assetName.contains('armeabi-v7a')) {
              downloadUrl = asset['browser_download_url'];
              break;
            }
          }

          // Fallback a un apk generico o el primero si no hace match
          if (downloadUrl == null && assets.isNotEmpty) {
            downloadUrl = assets.first['browser_download_url'];
          }

          if (downloadUrl != null && context.mounted) {
            _showUpdateDialog(
              context,
              latestVersion,
              downloadUrl,
              data['body'] ?? '¡Nueva versión disponible!',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current
        .split('+')
        .first
        .split('.')
        .map(int.parse)
        .toList();
    List<int> latestParts = latest
        .split('+')
        .first
        .split('.')
        .map(int.parse)
        .toList();

    for (int i = 0; i < currentParts.length && i < latestParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String downloadUrl,
    String releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Actualización Disponible (v$version)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hay una nueva y mejor versión de la aplicación disponible. ¿Deseas instalarla ahora?',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Novedades:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(releaseNotes),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Más tarde'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Actualizar ahora'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _downloadAndInstall(context, downloadUrl);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    String url,
  ) async {
    ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
    ValueNotifier<String> statusNotifier = ValueNotifier('Iniciando...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return ValueListenableBuilder<String>(
                valueListenable: statusNotifier,
                builder: (context, status, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Descargando actualización',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(status),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';

      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progressNotifier.value = received / total;
            statusNotifier.value =
                '${(received / 1024 / 1024).toStringAsFixed(2)} MB / ${(total / 1024 / 1024).toStringAsFixed(2)} MB';
          } else {
            statusNotifier.value =
                '${(received / 1024 / 1024).toStringAsFixed(2)} MB descargados';
          }
        },
      );

      statusNotifier.value = 'Instalando...';

      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Open APK
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al abrir el archivo: ${result.message}'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error en la descarga: $e')));
      }
    }
  }
}
