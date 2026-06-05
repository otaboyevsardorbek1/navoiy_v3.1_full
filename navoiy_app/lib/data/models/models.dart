// lib/data/models/models.dart

// ─── User ─────────────────────────────────────────────────────────────────────

class UserModel {
  final int? id;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final String? avatarUrl;

  const UserModel({
    this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.role = 'user',
    this.isActive = true,
    this.lastLogin,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        username: j['username'] ?? '',
        email: j['email'] ?? '',
        fullName: j['full_name'],
        role: j['role'] ?? 'user',
        isActive: j['is_active'] ?? true,
        lastLogin: j['last_login'] != null ? DateTime.tryParse(j['last_login']) : null,
        avatarUrl: j['avatar_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'username': username, 'email': email,
        'full_name': fullName, 'role': role, 'is_active': isActive,
        'last_login': lastLogin?.toIso8601String(), 'avatar_url': avatarUrl,
      };
}

// ─── Asar ─────────────────────────────────────────────────────────────────────

class AsarModel {
  final int? id;
  final String title;
  final String titleUz;
  final String? slug;
  final String? description;
  final String category;
  final String? content;
  final String? imageUrl;
  final int? year;
  final String? language;
  final bool isFavorite;
  final int readCount;
  final List<String> tags;
  final int totalPages;
  final int version;
  final String? checksum;
  final bool isDownloaded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AsarModel({
    this.id,
    required this.title,
    required this.titleUz,
    this.slug,
    this.description,
    required this.category,
    this.content,
    this.imageUrl,
    this.year,
    this.language = 'uz',
    this.isFavorite = false,
    this.readCount = 0,
    this.tags = const [],
    this.totalPages = 1,
    this.version = 0,
    this.checksum,
    this.isDownloaded = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AsarModel.fromJson(Map<String, dynamic> j) => AsarModel(
        id: j['id'],
        title: j['title'] ?? '',
        titleUz: j['title_uz'] ?? j['title'] ?? '',
        slug: j['slug'],
        description: j['description'],
        category: j['category'] ?? 'boshqa',
        content: j['content'],
        imageUrl: j['image_url'],
        year: j['year'],
        language: j['language'] ?? 'uz',
        isFavorite: j['is_favorite'] == true || j['is_favorite'] == 1,
        readCount: j['read_count'] ?? 0,
        tags: List<String>.from(j['tags'] ?? []),
        totalPages: j['total_pages'] ?? 1,
        version: j['version'] ?? 0,
        checksum: j['checksum'],
        isDownloaded: j['is_downloaded'] == true || j['is_downloaded'] == 1,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
        updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
      );

  AsarModel copyWith({
    int? id, String? title, String? titleUz, String? slug, String? description,
    String? category, String? content, String? imageUrl, int? year, String? language,
    bool? isFavorite, int? readCount, List<String>? tags, int? totalPages,
    int? version, String? checksum, bool? isDownloaded,
  }) => AsarModel(
    id: id ?? this.id, title: title ?? this.title, titleUz: titleUz ?? this.titleUz,
    slug: slug ?? this.slug, description: description ?? this.description,
    category: category ?? this.category, content: content ?? this.content,
    imageUrl: imageUrl ?? this.imageUrl, year: year ?? this.year,
    language: language ?? this.language, isFavorite: isFavorite ?? this.isFavorite,
    readCount: readCount ?? this.readCount, tags: tags ?? this.tags,
    totalPages: totalPages ?? this.totalPages, version: version ?? this.version,
    checksum: checksum ?? this.checksum, isDownloaded: isDownloaded ?? this.isDownloaded,
  );
}

// ─── Sher ─────────────────────────────────────────────────────────────────────

class SherModel {
  final int? id;
  final String title;
  final String? slug;
  final String content;
  final String type;
  final String? description;
  final int? asarId;
  final String? asarTitle;
  final bool isFavorite;
  final int likeCount;
  final String? audioUrl;
  final int version;
  final DateTime? createdAt;

  const SherModel({
    this.id,
    required this.title,
    this.slug,
    required this.content,
    required this.type,
    this.description,
    this.asarId,
    this.asarTitle,
    this.isFavorite = false,
    this.likeCount = 0,
    this.audioUrl,
    this.version = 1,
    this.createdAt,
  });

  factory SherModel.fromJson(Map<String, dynamic> j) => SherModel(
        id: j['id'],
        title: j['title'] ?? '',
        slug: j['slug'],
        content: j['content'] ?? '',
        type: j['type'] ?? 'gazal',
        description: j['description'],
        asarId: j['asar_id'],
        asarTitle: j['asar_title'],
        isFavorite: j['is_favorite'] == true || j['is_favorite'] == 1,
        likeCount: j['like_count'] ?? 0,
        audioUrl: j['audio_url'],
        version: j['version'] ?? 1,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      );
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        accessToken: j['access_token'] ?? '',
        refreshToken: j['refresh_token'],
        expiresIn: j['expires_in'] ?? 86400,
        user: UserModel.fromJson(j['user'] ?? {}),
      );
}

class LoginRequest {
  final String username;
  final String password;
  final bool rememberMe;

  const LoginRequest({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() => {
        'username': username, 'password': password, 'remember_me': rememberMe,
      };
}
