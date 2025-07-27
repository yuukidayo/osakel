
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerGenerator {
  /// Airbnb風の金額を表示するカスタムマーカーを生成する
  static Future<BitmapDescriptor> createPriceMarker({
    required double price,
    bool isSelected = false,
    bool isCluster = false,
    int? clusterCount,
  }) async {
    // マーカーのサイズを設定 (元のサイズの約2.1倍 = 3.5 * 0.6)
    const double width = 210; // 100 * 2.1
    const double height = 92; // 44 * 2.1
    
    // マーカーのデザインを作成
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // モノトーンのマーカーの背景色を設定
    final Color markerColor = isSelected
        ? const Color(0xFF000000) // 選択時: 黒背景
        : (isCluster ? const Color(0xFF333333) : const Color(0xFFFFFFFF)); // 未選択時: 白背景
    
    final Paint paint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;
    
    // 影の設定 (0.6倍に調整)
    const shadowOffset = Offset(0, 4); // 7 * 0.6 ≈ 4
    const shadowBlur = 8.0; // 14 * 0.6 ≈ 8
    final shadowPaint = Paint()
      ..color = const Color(0xFF8A8A8A).withValues(alpha: 0.3) // グレーの影
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, shadowBlur);
    
    // 影を描画 (Airbnb風の丸みを帯びた長方形)
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, width, height),
      const Radius.circular(46), // 77 * 0.6 ≈ 46 (より丸みを帯びたコーナー)
    );
    canvas.drawRRect(shadowRect, shadowPaint);
    
    // マーカー本体を描画 (Airbnb風の丸みを帯びた長方形)
    final markerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(46), // 77 * 0.6 ≈ 46 (より丸みを帯びたコーナー)
    );
    canvas.drawRRect(markerRect, paint);
    
    // 金額テキストのスタイル (パディングを半分にするためフォントサイズを大きく)
    final textStyle = TextStyle(
      color: isSelected ? Colors.white : const Color(0xFF000000), // 選択時: 白テキスト、未選択時: 黒テキスト
      fontSize: isCluster ? 40 : 46, // パディングを半分にするためサイズを大きく調整
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0, // Airbnb風のテキスト間隔を維持
    );
    
    // 金額テキストを描画
    final String priceText = isCluster
        ? '¥${price.toInt()}〜'
        : '¥${price.toInt()}';
    
    final textSpan = TextSpan(
      text: priceText,
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    textPainter.layout();
    
    // テキストを中央に配置
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );
    
    // クラスターの場合、店舗数を小さく表示
    if (isCluster && clusterCount != null) {
      // クラスター数を示す円を右上に描画 (バランスを調整)
      final circlePaint = Paint()
        ..color = const Color(0xFFFFFFFF) // 白色の円
        ..style = PaintingStyle.fill;
      
      const double circleRadius = 24; // 円のサイズを少し大きく調整
      const double circleX = width - circleRadius - 6; // 右端からの位置を調整
      const double circleY = circleRadius + 6; // 上端からの位置を調整
      
      canvas.drawCircle(const Offset(circleX, circleY), circleRadius, circlePaint);
      
      // 円の中に数字を描画 (バランスを調整)
      final countTextStyle = TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF000000), // 選択状態に応じたテキスト色
        fontSize: 24, // フォントサイズを円の大きさに合わせて調整
        fontWeight: FontWeight.bold,
      );
      
      final countText = clusterCount > 99 ? '99+' : clusterCount.toString();
      final countTextSpan = TextSpan(
        text: countText,
        style: countTextStyle,
      );
      
      final countTextPainter = TextPainter(
        text: countTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      countTextPainter.layout();
      
      countTextPainter.paint(
        canvas,
        Offset(
          circleX - countTextPainter.width / 2,
          circleY - countTextPainter.height / 2,
        ),
      );
    }
    
    // 描画結果をイメージに変換
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
}
