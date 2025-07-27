import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// シンプルで効率的なマーカー生成器（業界標準）
/// 
/// Google Maps、Uber、Airbnbで使用される標準的なアプローチ
class SimpleMarkerGenerator {
  static final Map<String, BitmapDescriptor> _cache = {};
  
  /// 標準的な価格マーカーを生成
  static Future<BitmapDescriptor> createPriceMarker({
    required double price,
    bool isSelected = false,
  }) async {
    // 固定サイズ設定（全デバイス統一）
    const double width = 240.0;
    const double height = 100.0;
    
    // キャッシュキー（シンプル）
    final key = '${price.toInt()}_$isSelected';
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    // Canvas準備
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // スタイル設定
    final bgColor = isSelected ? Colors.black : Colors.white;
    final textColor = isSelected ? Colors.white : Colors.black;
    final borderColor = Colors.grey.shade300;
    
    // 背景描画
    final rect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));
    
    canvas.drawRRect(rrect, Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill);
    
    // 境界線（非選択時のみ）
    if (!isSelected) {
      canvas.drawRRect(rrect, Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
    }
    
    // テキスト描画
    final textPainter = TextPainter(
      text: TextSpan(
        text: '¥${price.toInt()}',
        style: TextStyle(
          color: textColor,
          fontSize: 40,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      (width - textPainter.width) / 2,
      (height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
    
    // BitmapDescriptor生成（固定サイズで統一）
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    
    // キャッシュ保存
    _cache[key] = bitmap;
    
    return bitmap;
  }
  
  /// キャッシュクリア
  static void clearCache() {
    _cache.clear();
  }
}