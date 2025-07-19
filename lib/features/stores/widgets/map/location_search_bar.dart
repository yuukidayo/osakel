import 'package:flutter/material.dart';

/// 位置検索バーコンポーネント
/// 
/// マップ画面の上部に表示される検索バーと候補リスト
class LocationSearchBar extends StatefulWidget {
  final List<String> locationSuggestions;
  final Function(String) onLocationSearch;
  final VoidCallback onClose;

  const LocationSearchBar({
    Key? key,
    required this.locationSuggestions,
    required this.onLocationSearch,
    required this.onClose,
  }) : super(key: key);

  @override
  State<LocationSearchBar> createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    // 自動フォーカス
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 候補をフィルタリング
  void _filterSuggestions(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSuggestions = [];
      } else {
        _filteredSuggestions = widget.locationSuggestions
            .where((location) => location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// 検索をクリア
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _filteredSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Column(
        children: [
          // 検索バー
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              right: 8,
              bottom: 8,
            ),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onClose,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _filterSuggestions,
                    decoration: InputDecoration(
                      hintText: '場所を検索（例：東京都渋谷区）',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    ),
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
          
          // 候補リスト
          Expanded(
            child: Container(
              color: Colors.white,
              child: _filteredSuggestions.isEmpty && _searchQuery.isNotEmpty
                ? const Center(
                    child: Text('検索結果がありません'),
                  )
                : ListView.builder(
                    itemCount: _searchQuery.isEmpty
                      ? widget.locationSuggestions.length
                      : _filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      final String location = _searchQuery.isEmpty
                        ? widget.locationSuggestions[index]
                        : _filteredSuggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(location),
                        onTap: () => widget.onLocationSearch(location),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
