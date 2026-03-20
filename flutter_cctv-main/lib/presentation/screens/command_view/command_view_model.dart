// ─── Shared constants & data models for CommandView ──────────────────────────

const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://se-lab.aboutblank.in.th',
);

// =============================================================================
// CameraInfo
// =============================================================================

class CameraInfo {
  final String id;
  final String name;
  final String rtspUrl;

  CameraInfo({
    required this.id,
    required this.name,
    required this.rtspUrl,
  });

  factory CameraInfo.fromJson(Map<String, dynamic> data, {String? docId}) {
    return CameraInfo(
      id: docId ?? data['id']?.toString() ?? '',
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String)
          : 'Camera',
      rtspUrl: (data['rtspUrl'] as String? ??
              data['url'] as String? ??
              data['URL'] as String? ??
              data['rtsp_url'] as String? ??
              '')
          .trim(),
    );
  }
}

// =============================================================================
// HlsResult — URL หรือ error reason
// =============================================================================

class HlsResult {
  final String? url;
  final String? error;
  const HlsResult({this.url, this.error});
}