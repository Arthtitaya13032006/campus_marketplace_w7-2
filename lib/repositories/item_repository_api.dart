import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
      }
      return _mockItems;
    } catch (_) {
      // กรณี Fake Store API ล่ม/Timeout/Cloudflare บล็อก (ตามที่ระบุใน Troubleshooting ของใบงาน)
      return _mockItems;
    }
  }

  static const List<Item> _mockItems = [
    Item(
      id: 1,
      title: 'Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops',
      price: 109.95,
      description: 'Your perfect pack for everyday use and walks in the forest.',
      category: "men's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/81fPKd-2AYL._AC_SL1500_.jpg',
    ),
    Item(
      id: 2,
      title: 'Mens Casual Premium Slim Fit T-Shirts',
      price: 22.30,
      description: 'Slim-fitting style, contrast raglan long sleeve.',
      category: "men's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg',
    ),
    Item(
      id: 3,
      title: 'Mens Cotton Jacket',
      price: 55.99,
      description: 'Great outerwear jackets for Spring/Autumn/Winter.',
      category: "men's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/71li-ujtlUL._AC_UX679_.jpg',
    ),
    Item(
      id: 4,
      title: 'Mens Casual Slim Fit',
      price: 15.99,
      description: 'The color could be slightly different between on the screen and in practice.',
      category: "men's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/71YXzeOuslL._AC_UY879_.jpg',
    ),
    Item(
      id: 5,
      title: "John Hardy Women's Legends Naga Gold & Silver Dragon Station Chain Bracelet",
      price: 695.00,
      description: 'From our Legends Collection, the Naga was inspired by the mythical water dragon.',
      category: 'jewelery',
      imageUrl: 'https://m.media-amazon.com/images/I/71pWzhdJNwL._AC_UL640_QL65_ML3_.jpg',
    ),
    Item(
      id: 6,
      title: 'Solid Gold Petite Micropave',
      price: 168.00,
      description: 'Satisfaction Guaranteed. Return or exchange any order within 30 days.',
      category: 'jewelery',
      imageUrl: 'https://m.media-amazon.com/images/I/61sbMiUnoGL._AC_UL640_QL65_ML3_.jpg',
    ),
    Item(
      id: 7,
      title: 'White Gold Plated Princess',
      price: 9.99,
      description: 'Classic Created Wedding Engagement Solitaire Diamond Promise Ring for Her.',
      category: 'jewelery',
      imageUrl: 'https://m.media-amazon.com/images/I/71YAIFU48IL._AC_UL640_QL65_ML3_.jpg',
    ),
    Item(
      id: 8,
      title: 'Pierced Owl Rose Gold Plated Stainless Steel Double',
      price: 10.99,
      description: 'Rose Gold Plated Flared Tunnel Plug Earrings.',
      category: 'jewelery',
      imageUrl: 'https://m.media-amazon.com/images/I/51UDEzMJVpL._AC_UL640_QL65_ML3_.jpg',
    ),
    Item(
      id: 9,
      title: 'WD 2TB Elements Portable External Hard Drive - USB 3.0',
      price: 64.00,
      description: 'USB 3.0 and USB 2.0 Compatibility Fast data transfers.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/61IBBVJvSDL._AC_SY879_.jpg',
    ),
    Item(
      id: 10,
      title: 'SanDisk SSD PLUS 1TB Internal SSD - SATA III 6 Gb/s',
      price: 109.00,
      description: 'Easy upgrade for faster boot up, shutdown, application load and response.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/61U7T1koQqL._AC_SX679_.jpg',
    ),
    Item(
      id: 11,
      title: 'Silicon Power 256GB SSD 3D NAND A55 SLC Cache Performance Boost SATA III 2.5',
      price: 109.00,
      description: '3D NAND flash are applied to deliver high transfer speeds.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/71kWymZJnCL._AC_SX679_.jpg',
    ),
    Item(
      id: 12,
      title: 'WD 4TB Gaming Drive Works with Playstation 4 Portable External Hard Drive',
      price: 114.00,
      description: 'Expand your PS4 gaming experience, Play anywhere Fast and easy, setup.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/61mtL65D4cL._AC_SX679_.jpg',
    ),
    Item(
      id: 13,
      title: 'Acer SB220Q bi 21.5 inches Full HD (1920 x 1080) IPS Ultra-Thin',
      price: 599.00,
      description: '21.5 inches Full HD widescreen IPS display and Radeon free Sync technology.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/81QpkIctqPL._AC_SX679_.jpg',
    ),
    Item(
      id: 14,
      title: 'Samsung 49-Inch CHG90 144Hz Curved Gaming Monitor',
      price: 999.99,
      description: '49 INCH SUPER ULTRAWIDE 32:9 CURVED GAMING MONITOR with dual 27 inch screen side by side.',
      category: 'electronics',
      imageUrl: 'https://m.media-amazon.com/images/I/81Zt42ioCgL._AC_SX679_.jpg',
    ),
    Item(
      id: 15,
      title: "BIYLACLESEN Women's 3-in-1 Snowboard Jacket Winter Coats",
      price: 56.99,
      description: 'Note:The Jackets is US standard size, Please choose size as your usual wear.',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/51Y5NI-I5jL._AC_UX679_.jpg',
    ),
    Item(
      id: 16,
      title: "Lock and Love Women's Removable Hooded Faux Leather Moto Biker Jacket",
      price: 29.95,
      description: '100% POLYURETHANE(shell) 100% POLYESTER(lining) 75% POLYESTER 25% COTTON (SWEATER).',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/81XH0e8fefL._AC_UY879_.jpg',
    ),
    Item(
      id: 17,
      title: 'Rain Jacket Women Windbreaker Striped Climbing Raincoats',
      price: 39.99,
      description: 'Lightweight perfet for trip or casual wear---Long sleeve with hooded, adjustable drawstring waist design.',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/71HblAHs5xL._AC_UY879_-2.jpg',
    ),
    Item(
      id: 18,
      title: "MBJ Women's Solid Short Sleeve Boat Neck V",
      price: 9.85,
      description: '95% RAYON 5% SPANDEX, Made in USA or Imported, Do Not Bleach, Lightweight fabric with great stretch.',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/71z3kpMAYsL._AC_UY879_.jpg',
    ),
    Item(
      id: 19,
      title: "Opna Women's Short Sleeve Moisture",
      price: 7.95,
      description: '100% Polyester, Machine wash, 100% cationic polyester interlock, Lightweight, roomy and highly breathable.',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/51eg55uWmdL._AC_UX679_.jpg',
    ),
    Item(
      id: 20,
      title: 'DANVOUY Womens T Shirt Casual Cotton Short',
      price: 12.99,
      description: '95%Cotton,5%Spandex, Features: Casual, Short Sleeve, Letter Print,V-Neck,Fashion Tees.',
      category: "women's clothing",
      imageUrl: 'https://m.media-amazon.com/images/I/61pHAEJ4NML._AC_UX679_.jpg',
    ),
  ];
}
