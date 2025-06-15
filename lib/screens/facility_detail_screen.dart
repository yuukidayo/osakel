import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sauna_facility.dart';

class FacilityDetailScreen extends StatelessWidget {
  const FacilityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SaunaFacility facility = ModalRoute.of(context)!.settings.arguments as SaunaFacility;

    return Scaffold(
      appBar: AppBar(
        title: Text(facility.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 施設画像
            if (facility.imageUrl != null && facility.imageUrl!.isNotEmpty)
              Image.network(
                facility.imageUrl!,
                height: 200.0,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200.0,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 60.0),
                  );
                },
              )
            else
              Container(
                height: 200.0,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.hot_tub, size: 60.0, color: Colors.grey),
                ),
              ),

            // 施設情報
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 施設名
                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 住所
                  _buildInfoRow(Icons.location_on, facility.address),
                  const SizedBox(height: 12.0),

                  // サウナ温度
                  _buildInfoRow(
                    Icons.whatshot,
                    'サウナ温度: ${facility.saunaTemperature.toStringAsFixed(1)}℃',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12.0),

                  // 水風呂温度
                  _buildInfoRow(
                    Icons.water_drop,
                    '水風呂温度: ${facility.waterBathTemperature.toStringAsFixed(1)}℃',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12.0),

                  // 距離（あれば表示）
                  if (facility.distance != null) ...[
                    _buildInfoRow(
                      Icons.directions_walk,
                      '現在地からの距離: ${facility.distance!.toStringAsFixed(1)} km',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12.0),
                  ],

                  const Divider(),
                  const SizedBox(height: 16.0),

                  // 施設情報（仮のデータ）
                  const Text(
                    '施設情報',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoTable(),
                  const SizedBox(height: 24.0),

                  // 経路案内ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('経路を検索'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: () => _openInGoogleMaps(facility),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 情報行ウィジェット
  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: color),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }

  // 情報テーブルウィジェット（仮のデータ）
  Widget _buildInfoTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      children: [
        _buildTableRow('営業時間', '平日: 10:00-23:00\n土日祝: 10:00-22:00'),
        _buildTableRow('定休日', '毎週水曜日'),
        _buildTableRow('料金', '大人: 1,000円\n子供: 500円'),
        _buildTableRow('設備', 'サウナ、水風呂、外気浴スペース、休憩室'),
        _buildTableRow('電話番号', '03-1234-5678'),
      ],
    );
  }

  // テーブル行ウィジェット
  TableRow _buildTableRow(String title, String content) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(content),
        ),
      ],
    );
  }

  // Google マップで施設への経路を開く
  void _openInGoogleMaps(SaunaFacility facility) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${facility.lat},${facility.lng}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
