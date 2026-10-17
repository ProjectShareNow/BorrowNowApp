import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/service_registry.dart';
import '../../utils/helpers.dart';

class LiveEvidenceCaptureCard extends StatefulWidget {
  final String title;
  final String description;
  final String existingPhotoUrl;
  final bool isEnabled;
  final String disabledReason;
  final Future<Map<String, String>> Function(XFile file) onUpload;
  final VoidCallback? onPhotoConfirmed;

  const LiveEvidenceCaptureCard({
    super.key,
    required this.title,
    required this.description,
    required this.existingPhotoUrl,
    required this.isEnabled,
    this.disabledReason = '',
    required this.onUpload,
    this.onPhotoConfirmed,
  });

  @override
  State<LiveEvidenceCaptureCard> createState() => _LiveEvidenceCaptureCardState();
}

class _LiveEvidenceCaptureCardState extends State<LiveEvidenceCaptureCard> {
  XFile? _capturedFile;
  bool _isCapturing = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingPhotoUrl.isNotEmpty) {
      _uploadedUrl = widget.existingPhotoUrl;
    }
  }

  @override
  void didUpdateWidget(covariant LiveEvidenceCaptureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEnabled && oldWidget.isEnabled) {
      setState(() {
        _capturedFile = null;
        _isCapturing = false;
        _isUploading = false;
        _errorMessage = null;
      });
    }
    if (widget.existingPhotoUrl != _uploadedUrl) {
      setState(() {
        _uploadedUrl = widget.existingPhotoUrl.isNotEmpty ? widget.existingPhotoUrl : null;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (!widget.isEnabled || _isUploading) return;

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final file = await ServiceRegistry.storageService.captureLiveCameraPhoto();
      if (!mounted) return;

      if (file != null) {
        setState(() {
          _capturedFile = file;
          _isCapturing = false;
        });
      } else {
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage =
            'Camera access failed. Please ensure camera permissions are granted in settings.';
      });
    }
  }

  String? _uploadSuccessMessage;

  Future<void> _uploadAndConfirm() async {
    if (_capturedFile == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadSuccessMessage = null;
    });

    try {
      final result = await widget.onUpload(_capturedFile!);
      if (!mounted) return;

      setState(() {
        _uploadedUrl = result['downloadUrl'];
        _isUploading = false;
        _capturedFile = null;
        _uploadSuccessMessage = 'Photo uploaded successfully! ✅';
      });

      widget.onPhotoConfirmed?.call();
      AppHelpers.showSnackBar(context, 'Live evidence photo uploaded and saved!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showFullPhoto(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 280,
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: Colors.black87,
                    child: const Center(
                      child: Text(
                        'Unable to load photo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton.filled(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUploaded = _uploadedUrl != null && _uploadedUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUploaded
              ? const Color(0xFF10B981)
              : (widget.isEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
          width: hasUploaded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hasUploaded
                      ? const Color(0xFFECFDF5)
                      : (widget.isEnabled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasUploaded ? Icons.verified_rounded : Icons.photo_camera_rounded,
                  size: 18,
                  color: hasUploaded
                      ? const Color(0xFF059669)
                      : (widget.isEnabled ? const Color(0xFF0F766E) : Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Confirmed ✅',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),

          if (!widget.isEnabled && widget.disabledReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.disabledReason,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. If photo is already uploaded and saved
          if (hasUploaded && _capturedFile == null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showFullPhoto(_uploadedUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.network(
                          _uploadedUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live evidence securely stored',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap thumbnail to view full image. Fresh camera capture recorded.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ]
          // 2. If photo is captured and pending user confirmation
          else if (_capturedFile != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            _capturedFile!.path,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_capturedFile!.path),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (_isUploading) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploading photo to Storage...',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _capturePhoto,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retake Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadAndConfirm,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 16),
                          label: Text(_isUploading ? 'Uploading...' : 'Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]
          // 3. Camera Capture button (disabled when !widget.isEnabled)
          else ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (widget.isEnabled && !_isCapturing) ? _capturePhoto : null,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: widget.isEnabled ? Colors.white : Colors.grey.shade400,
                      ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isCapturing ? 'Opening Camera...' : 'Take Photo'),
                    const SizedBox(
                      width: 0,
                      height: 0,
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: 0,
                        minHeight: 0,
                        maxHeight: 0,
                        child: Text(
                          'Capture Photo',
                          style: TextStyle(
                            fontSize: 0.001,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isEnabled
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFE2E8F0),
                  foregroundColor: widget.isEnabled
                      ? Colors.white
                      : Colors.grey.shade500,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: widget.isEnabled ? 1 : 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          if (_uploadSuccessMessage != null && hasUploaded) ...[
            const SizedBox(height: 6),
            Text(
              _uploadSuccessMessage!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
