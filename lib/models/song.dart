class Song {
  final String id;
  final String title;
  final String artist;
  final String youtubeUrl;
  String? localPath;
  bool isDownloading;
  double downloadProgress;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeUrl,
    this.localPath,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isFavorite = false,
  });
}
