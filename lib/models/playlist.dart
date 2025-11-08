class Playlist {
  final String id;
  final String name;
  final List<String> songIds;
  final String icon;

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    this.icon = '🎵',
  });
}
