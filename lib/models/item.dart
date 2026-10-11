import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final title = json['title'] as String;
    final price = (json['price'] as num).toDouble();
    final description = json['description'] as String;
    final category = json['category'] as String;
    final rawUrl = json['image'] as String;
    var imageUrl = rawUrl
        .replaceFirst('https://fakestoreapi.com/img/', 'https://m.media-amazon.com/images/I/')
        .replaceAll('-2t.png', '_.jpg')
        .replaceAll('_t.png', '_.jpg');
    if (imageUrl.endsWith('-2.jpg')) {
      imageUrl = imageUrl.replaceAll('-2.jpg', '.jpg');
    }

    return Item(
      id: id,
      title: title,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final title = data['title'] as String? ?? '';
    var imageUrl = data['imageUrl'] as String? ?? '';
    if (title.contains('มวย') || title.contains('กางเกง')) {
      imageUrl = 'https://files.catbox.moe/6403sx.jpg';
    } else if (title.contains('ไดโนเสาร์') || title.contains('เสื้อ')) {
      imageUrl = 'https://files.catbox.moe/ym62ok.jpg';
    } else if (title.contains('squishy') || title.contains('สกุชชี่') || title.contains('แกะ') || title.contains('ตุ๊กตา') || title.contains('ของเล่น')) {
      imageUrl = 'https://files.catbox.moe/4x7i5d.jpg';
    }

    return Item(
      id: int.tryParse(doc.id) ?? doc.id.hashCode,
      title: title,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: imageUrl,
      sellerId: data['sellerId'] as String?,
    );
  }
}
