class NewsArticle {
  final String? title;
  final String? description;
  final String? urlToImage;
  final String? url;
  final String? content;  // Agregando el contenido completo
  final String? author;   // Agregando el autor
  final String? publishedAt; // Agregando la fecha de publicación

  NewsArticle({
    this.title,
    this.description,
    this.urlToImage,
    this.url,
    this.content,
    this.author,
    this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String?,
      description: json['description'] as String?,
      urlToImage: json['urlToImage'] as String?,
      url: json['url'] as String?,
      content: json['content'] as String?,
      author: json['author'] as String?,
      publishedAt: json['publishedAt'] as String?,
    );
  }
}
