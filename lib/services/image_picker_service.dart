import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

// Web-specific imports
import 'dart:html' as html;

class PickedImage {
  final dynamic file; // File for mobile, null for web
  final Uint8List? bytes; // For web
  final String? fileName;
  final String? mimeType;

  PickedImage({
    this.file,
    this.bytes,
    this.fileName,
    this.mimeType,
  });

  bool get isWeb => kIsWeb;
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<PickedImage?> pickImage(BuildContext context, {ImageSource? source}) async {
    if (kIsWeb) {
      return await _pickImageWeb(context);
    } else {
      return await _pickImageMobile(context, source: source);
    }
  }

  Future<PickedImage?> _pickImageMobile(BuildContext context, {ImageSource? source}) async {
    try {
      ImageSource imageSource = source ?? ImageSource.gallery;

      // Request permissions for mobile
      PermissionStatus permissionStatus;
      if (imageSource == ImageSource.camera) {
        permissionStatus = await Permission.camera.request();
      } else {
        permissionStatus = await Permission.photos.request();
      }

      if (permissionStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied. Please enable ${imageSource == ImageSource.camera ? 'camera' : 'photo library'} permission in settings.')),
        );
        return null;
      } else if (permissionStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission permanently denied. Please enable in app settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return null;
      }

      final pickedFile = await _picker.pickImage(
        source: imageSource,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        // Compress image
        final compressedFile = await _compressImage(file);
        if (compressedFile != null) {
          file = compressedFile;
        }

        return PickedImage(
          file: file,
          fileName: pickedFile.name,
        );
      }
    } catch (e) {
      print('Error picking image on mobile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
    return null;
  }

  Future<PickedImage?> _pickImageWeb(BuildContext context) async {
    final completer = Completer<PickedImage?>();
    StreamSubscription? onChangeSubscription;
    StreamSubscription? onLoadEndSubscription;
    StreamSubscription? onErrorSubscription;

    try {
      // Create file input element
      final input = html.FileUploadInputElement();
      input.accept = 'image/*';
      input.click();

      // Single onChange listener dengan cleanup
      onChangeSubscription = input.onChange.listen((e) async {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];

          // Check file size (limit to 10MB)
          if (file.size > 10 * 1024 * 1024) {
            if (!completer.isCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('File size too large. Please select an image under 10MB.')),
              );
              completer.complete(null);
            }
            _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
            return;
          }

          // Read file as bytes
          final reader = html.FileReader();
          
          // Single onLoadEnd listener
          onLoadEndSubscription = reader.onLoadEnd.listen((e) async {
            try {
              if (completer.isCompleted) return; // Prevent multiple completions
              
              final bytes = reader.result as Uint8List?;
              
              if (bytes != null && bytes.isNotEmpty) {
                // Compress image if needed
                final compressedBytes = await _compressImageWeb(bytes, file.name);
                final finalBytes = compressedBytes ?? bytes;

                if (!completer.isCompleted) {
                  completer.complete(PickedImage(
                    bytes: finalBytes,
                    fileName: file.name,
                    mimeType: file.type,
                  ));
                }
              } else {
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              }
            } catch (error) {
              print('Error processing web image: $error');
              if (!completer.isCompleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error processing image: $error')),
                );
                completer.complete(null);
              }
            } finally {
              _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
            }
          });

          // Single onError listener
          onErrorSubscription = reader.onError.listen((e) {
            if (!completer.isCompleted) {
              print('Error reading file: ${reader.error}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error reading file')),
              );
              completer.complete(null);
            }
            _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
          });

          reader.readAsArrayBuffer(file);
        } else {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
        }
      });

      // Timeout handler - hanya complete jika belum selesai
      Future.delayed(Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete(null);
          _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
        }
      });

      return completer.future;
    } catch (e) {
      print('Error picking image on web: $e');
      if (!completer.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
        completer.complete(null);
      }
      _cleanupSubscriptions(onChangeSubscription, onLoadEndSubscription, onErrorSubscription);
      return null;
    }
  }

  // Helper method untuk cleanup subscriptions
  void _cleanupSubscriptions(
    StreamSubscription? sub1, 
    StreamSubscription? sub2, 
    StreamSubscription? sub3
  ) {
    try {
      sub1?.cancel();
      sub2?.cancel();
      sub3?.cancel();
    } catch (e) {
      print('Error cleaning up subscriptions: $e');
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        // Resize if too large
        if (image.width > 1024 || image.height > 1024) {
          image = img.copyResize(image, width: 1024, height: 1024, maintainAspect: true);
        }

        // Compress
        final compressedBytes = img.encodeJpg(image, quality: 85);

        // Save to temp file
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);

        return tempFile;
      }
    } catch (e) {
      print('Error compressing mobile image: $e');
    }
    return null;
  }

  Future<Uint8List?> _compressImageWeb(Uint8List bytes, String fileName) async {
    try {
      img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        // Resize if too large
        if (image.width > 1024 || image.height > 1024) {
          image = img.copyResize(image, width: 1024, height: 1024, maintainAspect: true);
        }

        // Compress
        return img.encodeJpg(image, quality: 85);
      }
    } catch (e) {
      print('Error compressing web image: $e');
    }
    return null;
  }

  Widget buildImagePreview(PickedImage? image, {double width = 150, double height = 150}) {
    if (image == null) return SizedBox.shrink();

    if (image.isWeb && image.bytes != null) {
      return Container(
        width: width,
        height: height,
        child: Image.memory(
          image.bytes!,
          fit: BoxFit.cover,
        ),
      );
    } else if (!image.isWeb && image.file != null) {
      return Container(
        width: width,
        height: height,
        child: Image.file(
          image.file,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox.shrink();
  }

  String? getImageBase64(PickedImage? image) {
    if (image == null || image.bytes == null) return null;
    return base64Encode(image.bytes!);
  }
}