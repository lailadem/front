class Category {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Content {
  final int id;
  final int professionalId;
  final String title;
  final String description;
  final String type;
  final String? category;
  final String? filePath;
  final String createdAt;
  final String updatedAt;
  final int? contentTypeId;
  final List<Category> categories;

  Content({
    required this.id,
    required this.professionalId,
    required this.title,
    required this.description,
    required this.type,
    this.category,
    this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.contentTypeId,
    required this.categories,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    List<Category> categoriesList = [];

    // Handle different possible formats for categories
    if (json['categories'] != null) {
      if (json['categories'] is List) {
        categoriesList = List<Category>.from(
            json['categories'].map((x) => Category.fromJson(x)));
      } else if (json['categories'] is Map) {
        // If categories is a single object, convert it to a list
        categoriesList = [Category.fromJson(json['categories'])];
      }
    }

    return Content(
      id: json['id'],
      professionalId: json['professional_id'],
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      type: json['type'] ?? 'article',
      category: json['category'],
      filePath: json['file_path'],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      contentTypeId: json['content_type_id'],
      categories: categoriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professional_id': professionalId,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'file_path': filePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'content_type_id': contentTypeId,
      'categories': categories.map((x) => x.toJson()).toList(),
    };
  }

  Content copyWith({
    int? id,
    int? professionalId,
    String? title,
    String? description,
    String? type,
    String? category,
    String? filePath,
    String? createdAt,
    String? updatedAt,
    int? contentTypeId,
    List<Category>? categories,
  }) {
    return Content(
      id: id ?? this.id,
      professionalId: professionalId ?? this.professionalId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentTypeId: contentTypeId ?? this.contentTypeId,
      categories: categories ?? this.categories,
    );
  }
}
