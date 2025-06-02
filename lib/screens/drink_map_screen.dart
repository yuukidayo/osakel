import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import '../models/shop.dart';
import '../models/shop_with_price.dart';
import '../models/drink_shop_link.dart';
import '../widgets/store_bottom_sheet.dart';

class DrinkMapScreen extends StatefulWidget {
  final String drinkId;
  final String drinkName;

  const DrinkMapScreen({
    Key? key,
    required this.drinkId,
    required this.drinkName,
  }) : super(key: key);

  @override
  State<DrinkMapScreen> createState() => _DrinkMapScreenState();
}

class _DrinkMapScreenState extends State<DrinkMapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  GoogleMapController? _mapController;
  ShopWithPrice? _selectedShopWithPrice;
  bool _isLoading = true;
  List<ShopWithPrice> _stores = [];
  Set<Marker> _markers = {};
  
  // Initial camera position centered on Tokyo Station
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(35.681236, 139.767125),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShopWithPricesForDrink();
    });
  }

  // Mock data for testing when Firestore is unavailable
  List<ShopWithPrice> _getMockShopWithPrices() {
    return [
      ShopWithPrice(
        shop: Shop(
          id: '1',
          name: 'Tokyo Beer Hall',
          address: 'Popular beer hall with a wide selection of domestic and imported beers.',
          lat: 35.681236 + 0.003,
          lng: 139.767125 + 0.002,
          imageUrl: 'https://images.unsplash.com/photo-1584225064785-c62a8b43d148?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        ),
        drinkShopLink: DrinkShopLink(
          id: '1',
          drinkId: widget.drinkId,
          shopId: '1',
          price: 650.0,
          isAvailable: true,
          note: '',
        ),
      ),
      ShopWithPrice(
        shop: Shop(
          id: '2',
          name: 'Izakaya Sakura',
          address: 'Traditional Japanese pub with an excellent drink selection.',
          lat: 35.681236 - 0.002,
          lng: 139.767125 + 0.004,
          imageUrl: 'https://images.unsplash.com/photo-1554502078-ef0fc409efce?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        ),
        drinkShopLink: DrinkShopLink(
          id: '2',
          drinkId: widget.drinkId,
          shopId: '2',
          price: 580.0,
          isAvailable: true,
          note: '',
        ),
      ),
      ShopWithPrice(
        shop: Shop(
          id: '3',
          name: 'Convenience Store',
          address: 'Open 24/7 with a wide selection of drinks and snacks.',
          lat: 35.681236 + 0.001,
          lng: 139.767125 - 0.003,
          imageUrl: 'https://images.unsplash.com/photo-1608270586620-248524c67de9?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=60',
        ),
        drinkShopLink: DrinkShopLink(
          id: '3',
          drinkId: widget.drinkId,
          shopId: '3',
          price: 320.0,
          isAvailable: true,
          note: '',
        ),
      ),
    ];
  }

  Future<void> _loadShopWithPricesForDrink() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Loading stores for drink: ${widget.drinkId}');
      // 本番環境ではFirestoreからデータを取得
      // import '../services/firestore_service.dart';
      // final shopsWithPrices = await FirestoreService().getShopsWithPricesForDrink(widget.drinkId);
      
      // 開発用にモックデータを使用
      final List<ShopWithPrice> stores = _getMockShopWithPrices();
      
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
      
      if (_mapController != null) {
        _createMarkers();
      }
    } catch (e) {
      print('Error loading shops: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createMarkers() async {
    final Set<Marker> markers = {};
    
    for (final store in _stores) {
      final markerId = MarkerId(store.shop.id);
      
      // Create a custom marker with the price
      final BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
      
      markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(store.shop.lat, store.shop.lng),
          icon: markerIcon,
          onTap: () => _showShopWithPriceDetails(store),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _showShopWithPriceDetails(ShopWithPrice store) {
    setState(() {
      _selectedShopWithPrice = store;
    });
    
    _scaffoldKey.currentState?.showBottomSheet(
      (context) => StoreBottomSheet(
        shopWithPrice: store,
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _selectedShopWithPrice = null;
          });
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('${widget.drinkName} Locations'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
              // Create markers once the map is created
              if (_stores.isNotEmpty) {
                _createMarkers();
              }
            },
            markers: _markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_stores.isEmpty && !_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.store_mall_directory_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No shops found for ${widget.drinkName}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
