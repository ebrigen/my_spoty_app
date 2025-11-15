class YoutubeSearchResult {
  final String videoId;
  final String title;
  final String? channel;
  final int? durationSeconds;
  final String? thumbnail;

  YoutubeSearchResult({
    required this.videoId,
    required this.title,
    this.channel,
    this.durationSeconds,
    this.thumbnail,
  });

  factory YoutubeSearchResult.fromJson(Map<String, dynamic> json) {
    return YoutubeSearchResult(
      videoId: json['video_id'] as String,
      title: json['title'] as String,
      channel: json['channel'] as String?,
      durationSeconds: json['duration'] as int?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}
