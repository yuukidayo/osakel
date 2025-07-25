import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 最高画質の画像マーカー生成器（業界標準）
/// Airbnb・サウナイキタイレベルの画質を実現
class UltraHighQualityMarkerGenerator {
  
  /// 最高画質のAirbnb風マーカーを生成
  static Future<BitmapDescriptor> createUltraHighQualityMarker({
    required double price,
    bool isSelected = false,
    bool isCluster = false,
    int? clusterCount,
  }) async {
    // 最高画質設定（サイズそのまま・画質重視）
    const double pixelRatio = 5.0; // 最高画質（5倍密度）
    const double logicalWidth = 24; // 超小さなサイズ
    const double logicalHeight = 12; // 超小さな高さ
    final double physicalWidth = logicalWidth * pixelRatio;
    final double physicalHeight = logicalHeight * pixelRatio;
    
    // 最高品質Canvas設定
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // 最高品質レンダリング設定
    canvas.clipRect(Rect.fromLTWH(0, 0, physicalWidth, physicalHeight));
    
    // キャンバス全体を透明でクリア（アーティファクト防止）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, physicalWidth, physicalHeight),
      Paint()..color = Colors.transparent..blendMode = BlendMode.clear,
    );
    
    // Airbnb風カラーパレット
    final Color backgroundColor = isSelected 
        ? const Color(0xFF222222) // Airbnb風ダークグレー
        : const Color(0xFFFFFFFF); // 純白
    
    final Color textColor = isSelected 
        ? const Color(0xFFFFFFFF) // 純白テキスト
        : const Color(0xFF222222); // Airbnb風ダークグレー
    
    final Color borderColor = isSelected 
        ? Colors.transparent 
        : const Color(0xFFDDDDDD); // 上品なライトグレー
    
    // 最高品質のPaint設定
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * pixelRatio // より細い枠線で精密に
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // 完璧な角丸四角形（Airbnb風）
    final RRect markerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, physicalWidth, physicalHeight),
      Radius.circular(6 * pixelRatio), // 超小サイズに適した角丸
    );
    
    // 背景描画
    canvas.drawRRect(markerRect, backgroundPaint);
    
    // 枠線描画（選択時は無し）
    if (!isSelected) {
      canvas.drawRRect(markerRect, borderPaint);
    }
    
    // 最高品質テキスト設定
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 6 * pixelRatio, // 超小サイズに適したフォント
      fontWeight: FontWeight.w600,
      letterSpacing: -0.05 * pixelRatio, // より精密なスペース調整
      fontFamily: 'SF Pro Text', // iOS最高品質フォント
      height: 1.0, // ライン高さ最適化
      textBaseline: TextBaseline.alphabetic, // ベースライン最適化
    );
    
    // 価格テキスト準備
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
      maxLines: 1,
      textScaler: TextScaler.noScaling, // スケーリング無効で精密制御
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
    
    textPainter.layout(maxWidth: physicalWidth - (6 * pixelRatio));
    
    // テキストを完璧に中央配置
    final double textX = (physicalWidth - textPainter.width) / 2;
    final double textY = (physicalHeight - textPainter.height) / 2;
    
    textPainter.paint(canvas, Offset(textX, textY));
    
    // クラスター表示（高品質）
    if (isCluster && clusterCount != null) {
      await _drawClusterBadge(
        canvas, 
        physicalWidth, 
        physicalHeight, 
        clusterCount, 
        pixelRatio,
        isSelected,
      );
    }
    
    // 最高品質で画像生成（PNG最高品質）
    final picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      physicalWidth.toInt(), 
      physicalHeight.toInt(),
    );
    
    // PNG最高品質設定で書き出し（ロスレス圧縮）
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
  
  /// クラスターバッジを高品質で描画
  static Future<void> _drawClusterBadge(
    Canvas canvas,
    double markerWidth,
    double markerHeight,
    int clusterCount,
    double pixelRatio,
    bool isSelected,
  ) async {
    // バッジ設定
    final double badgeRadius = 12 * pixelRatio;
    final double badgeX = markerWidth - badgeRadius - (4 * pixelRatio);
    final double badgeY = badgeRadius + (4 * pixelRatio);
    
    // バッジ背景
    final Paint badgePaint = Paint()
      ..color = isSelected ? const Color(0xFFFF5A5F) : const Color(0xFFFF5A5F) // Airbnb風レッド
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    
    // バッジ枠線
    final Paint badgeBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * pixelRatio
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    
    canvas.drawCircle(Offset(badgeX, badgeY), badgeRadius, badgePaint);
    canvas.drawCircle(Offset(badgeX, badgeY), badgeRadius, badgeBorderPaint);
    
    // バッジテキスト
    final String badgeText = clusterCount > 99 ? '99+' : clusterCount.toString();
    final badgeTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 10 * pixelRatio,
      fontWeight: FontWeight.bold,
      fontFamily: 'System',
    );
    
    final badgeTextSpan = TextSpan(text: badgeText, style: badgeTextStyle);
    final badgeTextPainter = TextPainter(
      text: badgeTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    badgeTextPainter.layout();
    
    final double badgeTextX = badgeX - badgeTextPainter.width / 2;
    final double badgeTextY = badgeY - badgeTextPainter.height / 2;
    
    badgeTextPainter.paint(canvas, Offset(badgeTextX, badgeTextY));
  }
  
  /// 選択状態変更時の高速再生成（キャッシュ活用）
  static final Map<String, BitmapDescriptor> _markerCache = {};
  
  static Future<BitmapDescriptor> createCachedMarker({
    required double price,
    bool isSelected = false,
    bool isCluster = false,
    int? clusterCount,
  }) async {
    // キャッシュキー生成
    final String cacheKey = '${price}_${isSelected}_${isCluster}_${clusterCount ?? 0}';
    
    // キャッシュ確認
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }
    
    // 新規生成
    final marker = await createUltraHighQualityMarker(
      price: price,
      isSelected: isSelected,
      isCluster: isCluster,
      clusterCount: clusterCount,
    );
    
    // キャッシュ保存（メモリ効率を考慮して最大100個まで）
    if (_markerCache.length >= 100) {
      _markerCache.clear();
    }
    _markerCache[cacheKey] = marker;
    
    return marker;
  }
  
  /// キャッシュクリア（メモリ解放）
  static void clearCache() {
    _markerCache.clear();
  }
}