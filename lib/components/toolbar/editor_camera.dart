import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:saber/i18n/strings.g.dart';


/// class used to take photo by camera
///
class TakePictureScreen extends StatefulWidget {
  TakePictureScreen({
    super.key,
    required this.camera,     // which camera to use
    required this.onFileNameChanged,   // function called with photo filename when photo is taken
  });

  final log = Logger('Camera');

  final CameraDescription camera;  // camera
  final ValueChanged<String> onFileNameChanged;  // function obtaining photo name

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String? _previewPath; // Stores path of the captured photo for preview

  @override
  void initState() {
    super.initState();

    // Initialize the camera controller using the given camera
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    // Start initializing the controller (async operation)
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the camera controller when the widget is removed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.editor.camera.takePhoto)),

      // Wait until the controller is initialized
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          // Camera is ready
          if (snapshot.connectionState == ConnectionState.done) {
            // If we already captured a photo, show the preview
            if (_previewPath != null) {
              return Column(
                children: [
                  Expanded(child: Image.file(File(_previewPath!))), // Show preview image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        tooltip: 'Use Photo',
                        onPressed: () {
                          widget.onFileNameChanged(_previewPath!);
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.red),
                        tooltip: 'Retake Photo',
                        onPressed: () {
                          setState(() {
                            _previewPath = null;  // reset preview
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            // Show live camera preview
            return CameraPreview(_controller);
          } else {
            // While initializing, show a loading spinner
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // Show floating camera button only when no preview is being shown
      floatingActionButton: _previewPath == null
          ? FloatingActionButton(
        onPressed: () async {
          try {
            // Ensure camera is initialized
            await _initializeControllerFuture;

            // Capture the photo
            final image = await _controller.takePicture();

            // If widget is still mounted, show preview
            if (!context.mounted) return;
            setState(() {
              _previewPath = image.path;
            });
          } catch (e) {
            widget.log.warning('Error taking photo: ${e.toString()}');
          }
        },
        child: const Icon(Icons.camera_alt),
      )
          : null,
    );
  }
}
