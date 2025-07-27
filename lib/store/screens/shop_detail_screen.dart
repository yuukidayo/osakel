import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shop.dart';

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  final int price;

  const ShopDetailScreen({
    super.key,
    required this.shop,
    required this.price,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isBookmarked = false;

  // 店舗のimageUrls配列を使用（フォールバックでサンプル画像を追加）
  List<String> get _imageUrls {
    List<String> images = List.from(widget.shop.imageUrls);
    
    // imageUrlsが空の場合、フォールバックでサンプル画像を追加
    if (images.isEmpty) {
      images = [
        'https://via.placeholder.com/400x200?text=Shop+Image+1',
        'https://via.placeholder.com/400x200?text=Shop+Image+2',
        'https://via.placeholder.com/400x200?text=Shop+Image+3',
        'https://via.placeholder.com/400x200?text=Shop+Image+4',
        'https://via.placeholder.com/400x200?text=Shop+Image+5',
      ];
    }
    
    return images;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGoogleMaps() async {
    final String urlString = 'https://www.google.com/maps/search/?api=1&query=${widget.shop.lat},${widget.shop.lng}';
    final Uri mapUri = Uri.parse(urlString);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('マップアプリを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // カスタムヘッダー
            _buildHeader(context),
            
            // スクロール可能なコンテンツ
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 店舗情報
                    _buildStoreInfo(),
                    
                    // 画像カルーセル
                    _buildImageCarousel(),
                    
                    // 説明文
                    _buildDescription(),
                    
                    // 平均予算
                    _buildAverageBudget(),
                    
                    // アクションボタン
                    _buildActionButtons(),
                    
                    const SizedBox(height: 32), // 下部余白
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ヘッダー（戻るボタン + ブックマークボタン）
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 戻るボタン
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF1A202C),
                size: 20,
              ),
            ),
          ),
          
          // 中央は空白
          const Spacer(),
          
          // ブックマークボタン
          GestureDetector(
            onTap: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: const Color(0xFF1A202C),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 店舗情報（店舗名 + 位置情報）
  Widget _buildStoreInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店舗名
          Text(
            widget.shop.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 位置情報
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Color(0xFF666666),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.shop.address.isNotEmpty 
                    ? widget.shop.address 
                    : 'Tokyo, Shibuya',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 画像カルーセル
  Widget _buildImageCarousel() {
    return Column(
      children: [
        // 画像スライダー
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF7FAFC),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ページネーションドット
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_imageUrls.length, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index 
                  ? const Color(0xFF1A202C) 
                  : const Color(0xFFE2E8F0),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 説明文
  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '日中からお楽しみいただけるバー&カフェ。ビビットカラーをアクセントにした空間で気軽に語らうひとときをお過ごしください。',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
          height: 1.5,
        ),
      ),
    );
  }

  // 平均予算
  Widget _buildAverageBudget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '平均予算: ¥${widget.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // メニューボタン
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メニュー機能は準備中です')),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A202C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'メニュー',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // クーポンボタン
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('クーポン機能は準備中です')),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A202C),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_activity,
                      color: Color(0xFF1A202C),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'クーポン',
                      style: TextStyle(
                        color: Color(0xFF1A202C),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
