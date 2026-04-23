/// Mock Media URL Service for SafeTrack
class MediaUrlService {
  Future<String> saveImageUrl(
    String imageUrl, {
    Map<String, dynamic>? metadata,
  }) async {
    return 'mock-doc-id';
  }

  Future<List<String>> saveMultipleImageUrls(
    List<String> imageUrls, {
    Map<String, dynamic>? metadata,
  }) async {
    return imageUrls.map((_) => 'mock-doc-id').toList();
  }

  Future<List<Map<String, dynamic>>> getUserImages() async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getAllImages({int limit = 50}) async {
    return [];
  }

  Future<Map<String, dynamic>?> getImageById(String documentId) async {
    return null;
  }

  Future<void> deleteImageRecord(String documentId) async {}

  Future<void> updateImageMetadata(
    String documentId,
    Map<String, dynamic> updates,
  ) async {}

  Stream<List<Map<String, dynamic>>> streamUserImages() {
    return Stream.value([]);
  }
}
