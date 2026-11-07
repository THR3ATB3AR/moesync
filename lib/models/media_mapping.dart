import 'media_item.dart';

class MediaMappingIdentity {
  const MediaMappingIdentity({
    required this.mediaType,
    required this.service,
    required this.id,
  });

  final MediaType mediaType;
  final ServiceType service;
  final int id;

  String get key => '${mediaType.name}:${service.name}:$id';

  Map<String, Object> toJson() => {
    'mediaType': mediaType.name,
    'service': service.name,
    'id': id,
  };

  factory MediaMappingIdentity.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final mediaType = MediaType.values.where(
      (type) => type.name == json['mediaType'],
    );
    final service = ServiceType.values.where(
      (type) => type.name == json['service'],
    );
    if (id == null || id <= 0 || mediaType.isEmpty || service.isEmpty) {
      throw const FormatException('Invalid media mapping identity.');
    }
    return MediaMappingIdentity(
      mediaType: mediaType.first,
      service: service.first,
      id: id,
    );
  }

  factory MediaMappingIdentity.fromItem(MediaItem item) => MediaMappingIdentity(
    mediaType: item.mediaType,
    service: item.service,
    id: item.id,
  );
}

class ManualMediaMapping {
  ManualMediaMapping(Iterable<MediaMappingIdentity> members)
    : members = List.unmodifiable(
        {for (final member in members) member.key: member}.values,
      );

  final List<MediaMappingIdentity> members;

  Map<String, Object> toJson() => {
    'members': members.map((member) => member.toJson()).toList(),
  };

  factory ManualMediaMapping.fromJson(Map<String, dynamic> json) {
    final members = json['members'];
    if (members is! List<dynamic>) {
      throw const FormatException('Invalid manual media mapping.');
    }
    final mapping = ManualMediaMapping(
      members.map(
        (member) =>
            MediaMappingIdentity.fromJson(member as Map<String, dynamic>),
      ),
    );
    if (mapping.members.length < 2) {
      throw const FormatException('A media mapping needs two or more items.');
    }
    final mediaTypes = mapping.members
        .map((member) => member.mediaType)
        .toSet();
    if (mediaTypes.length != 1) {
      throw const FormatException('Media mappings cannot mix media types.');
    }
    if (mapping.members.map((member) => member.service).toSet().length !=
        mapping.members.length) {
      throw const FormatException(
        'Media mappings cannot contain multiple items from one service.',
      );
    }
    return mapping;
  }
}

class ManualMediaMappingIndex {
  ManualMediaMappingIndex(
    Iterable<ManualMediaMapping> mappings,
    MediaType mediaType,
  ) {
    var groupIndex = 0;
    for (final mapping in mappings) {
      if (mapping.members.first.mediaType != mediaType) continue;
      final groupKey = -(++groupIndex);
      for (final member in mapping.members) {
        _groupByIdentity[member.key] = groupKey;
      }
      final malMember = mapping.members
          .where((member) => member.service == ServiceType.mal)
          .firstOrNull;
      final shikimoriMember = mapping.members
          .where((member) => member.service == ServiceType.shikimori)
          .firstOrNull;
      final canonicalMalMember = malMember ?? shikimoriMember;
      if (canonicalMalMember != null) {
        _malIdByGroup[groupKey] = canonicalMalMember.id;
      }
    }
  }

  final Map<String, int> _groupByIdentity = {};
  final Map<int, int> _malIdByGroup = {};

  int? groupKeyFor(MediaItem item) =>
      _groupByIdentity[MediaMappingIdentity.fromItem(item).key];

  int? malIdFor(MediaItem item) {
    final groupKey = groupKeyFor(item);
    return groupKey == null ? null : _malIdByGroup[groupKey];
  }
}
