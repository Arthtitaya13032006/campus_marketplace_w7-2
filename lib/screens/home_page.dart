import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;

  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;
  final Set<int> _likedItemIds = {};

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await widget.favoritesRepository.getAllFavorites();
      if (mounted) {
        setState(() {
          _likedItemIds.clear();
          _likedItemIds.addAll(favs.map((f) => f.itemId));
        });
      }
    } catch (_) {}
  }

  Future<void> _testGemini() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังส่งคำขอไปยัง Gemini API...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final response = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );
      // ignore: avoid_print
      print('=== Gemini Response ===');
      // ignore: avoid_print
      print(response);
      // ignore: avoid_print
      print('=======================');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('=== Gemini Error ===');
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print('====================');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = widget.repository.getItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'ทดสอบ Gemini',
            onPressed: _testGemini,
          ),
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshItems,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่อีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return RefreshIndicator(
            onRefresh: () async => _refreshItems(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final item = items[index];
                return ListTile(
                  leading: Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                  title: Text(item.title),
                  subtitle: Text('${item.price} บาท'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _likedItemIds.contains(item.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _likedItemIds.contains(item.id)
                              ? Colors.red
                              : null,
                        ),
                        tooltip: 'ถูกใจ',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final alreadyLiked = _likedItemIds.contains(item.id);
                          try {
                            await widget.favoritesRepository.addFavorite(
                              item.id,
                              item.title,
                              item.price,
                              item.imageUrl,
                            );
                            if (!mounted) return;
                            setState(() {
                              _likedItemIds.add(item.id);
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  alreadyLiked
                                      ? '"${item.title}" อยู่ในรายการโปรดแล้ว'
                                      : 'เพิ่ม "${item.title}" ในรายการโปรดแล้ว',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        tooltip: 'เพิ่มลงตะกร้า',
                        onPressed: () {
                          context.read<CartModel>().add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testGemini,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('ทดสอบ Gemini'),
      ),
    );
  }
}
