/// =============================================================================
/// KithLy Global Protocol - SENDER CATALOG (Phase IV Enhanced)
/// sender_catalog.dart - Product Gallery with Shimmer & Consumer
/// =============================================================================
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_machine/gift_provider.dart';
import '../services/currency_service.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/proof_card.dart';
import '../state_machine/protocol_mapper.dart';

/// Product model
class Product {
  final String skuId;
  final String shopId;
  final String shopName;
  final String shopCity;
  final String name;
  final double priceZmw;
  final int stockLevel;
  final String? imageUrl;
  final String category;
  
  Product({
    required this.skuId,
    required this.shopId,
    required this.shopName,
    required this.shopCity,
    required this.name,
    required this.priceZmw,
    required this.stockLevel,
    this.imageUrl,
    this.category = 'General',
  });
}

/// Sender catalog screen with Consumer-based reactivity
class SenderCatalogScreen extends StatefulWidget {
  const SenderCatalogScreen({super.key});
  
  @override
  State<SenderCatalogScreen> createState() => _SenderCatalogScreenState();
}

class _SenderCatalogScreenState extends State<SenderCatalogScreen> {
  final CurrencyService _currencyService = CurrencyService.instance;
  String _displayCurrency = 'USD';
  bool _isLoading = true;
  List<Product> _products = [];
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    // Simulate network delay for shimmer effect demo
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _products = [
        Product(
          skuId: 'SKU-SHOP-001',
          shopId: 'shop-1',
          shopName: 'Shoprite Manda Hill',
          shopCity: 'Lusaka',
          name: 'Coca-Cola 2L',
          priceZmw: 45.00,
          stockLevel: 150,
          category: 'Beverages',
        ),
        Product(
          skuId: 'SKU-SHOP-002',
          shopId: 'shop-1',
          shopName: 'Shoprite Manda Hill',
          shopCity: 'Lusaka',
          name: 'White Bread Loaf',
          priceZmw: 32.00,
          stockLevel: 80,
          category: 'Bakery',
        ),
        Product(
          skuId: 'SKU-HW-001',
          shopId: 'shop-2',
          shopName: 'Chilenje Hardware',
          shopCity: 'Lusaka',
          name: 'Hammer 500g',
          priceZmw: 85.00,
          stockLevel: 25,
          category: 'Tools',
        ),
        Product(
          skuId: 'SKU-PHARM-001',
          shopId: 'shop-3',
          shopName: 'Rhodes Park Pharmacy',
          shopCity: 'Lusaka',
          name: 'Paracetamol 500mg',
          priceZmw: 28.00,
          stockLevel: 200,
          category: 'Medicine',
        ),
        Product(
          skuId: 'SKU-GROC-001',
          shopId: 'shop-1',
          shopName: 'Shoprite Manda Hill',
          shopCity: 'Lusaka',
          name: '5kg Mealie Meal',
          priceZmw: 120.00,
          stockLevel: 60,
          category: 'Groceries',
        ),
      ];
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Active gift status overlay (Consumer-reactive)
          Consumer<GiftProvider>(
            builder: (context, provider, _) {
              if (provider.activeGift != null) {
                return _buildActiveGiftOverlay(provider);
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Product list
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _buildProductList(),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send a Gift 🎁', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Deliver love to Zambia',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
      actions: [
        // Currency switcher
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
            initialValue: _displayCurrency,
            onSelected: (value) => setState(() => _displayCurrency = value),
            offset: const Offset(0, 40),
            itemBuilder: (context) => [
              _buildCurrencyMenuItem('USD', '🇺🇸'),
              _buildCurrencyMenuItem('GBP', '🇬🇧'),
              _buildCurrencyMenuItem('EUR', '🇪🇺'),
              _buildCurrencyMenuItem('ZMW', '🇿🇲'),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _currencyService.getFlag(_displayCurrency),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _displayCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  PopupMenuItem<String> _buildCurrencyMenuItem(String code, String flag) {
    return PopupMenuItem(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(code),
        ],
      ),
    );
  }
  
  /// Active gift status overlay with Consumer-reactive updates
  Widget _buildActiveGiftOverlay(GiftProvider provider) {
    final gift = provider.activeGift!;
    final uiState = gift.uiState;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _showGiftTracking(gift),
        child: StatusOverlay(
          statusCode: gift.status,
          message: uiState.message,
          color: uiState.color,
          icon: uiState.icon,
          isPulsing: uiState.isPulsing,
        ),
      ),
    );
  }
  
  /// Shimmer loading list
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => const ShimmerProductCard(),
    );
  }
  
  /// Product list
  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }
  
  Widget _buildProductCard(Product product) {
    final displayPrice = _displayCurrency == 'ZMW'
        ? 'K${product.priceZmw.toStringAsFixed(2)}'
        : _currencyService.format(product.priceZmw, _displayCurrency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSendDialog(product),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.2),
                        const Color(0xFF8B5CF6).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              product.shopName,
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            displayPrice,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_displayCurrency != 'ZMW')
                            Text(
                              '(K${product.priceZmw.toStringAsFixed(0)})',
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showSendDialog(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSendDialog(Product product) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Send ${product.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'to someone in ${product.shopCity}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            
            // Form fields
            _buildTextField(nameController, 'Receiver Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              phoneController, 
              'Phone Number', 
              Icons.phone,
              prefix: '+260 ',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            
            // Pay button
            Consumer<GiftProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isProcessingPayment
                      ? null
                      : () => _processGift(product, nameController.text, phoneController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0xFF10B981).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isProcessingPayment
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Pay ${_currencyService.format(product.priceZmw, _displayCurrency)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white12),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Future<void> _processGift(Product product, String name, String phone) async {
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    Navigator.pop(context); // Close bottom sheet
    
    final provider = context.read<GiftProvider>();
    
    try {
      // Create gift (Status 100)
      final gift = await provider.createGift(
        receiverPhone: '+260$phone',
        receiverName: name,
        shopId: product.shopId,
        productId: product.skuId,
        productName: product.name,
        unitPrice: product.priceZmw,
      );
      
      // Process payment (100 → 200)
      await provider.processPayment(
        txId: gift.txId,
        zmwAmount: product.priceZmw,
        displayCurrency: _displayCurrency,
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  void _showGiftTracking(Gift gift) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GiftTrackingScreen(txId: gift.txId),
      ),
    );
  }
}

/// Gift tracking screen with proof card
class GiftTrackingScreen extends StatelessWidget {
  final String txId;
  
  const GiftTrackingScreen({super.key, required this.txId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gift Tracking'),
      ),
      body: Consumer<GiftProvider>(
        builder: (context, provider, _) {
          final gift = provider.gifts.firstWhere(
            (g) => g.txId == txId,
            orElse: () => throw Exception('Gift not found'),
          );
          
          final uiState = gift.uiState;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status overlay
                StatusOverlay(
                  statusCode: gift.status,
                  message: uiState.message,
                  color: uiState.color,
                  icon: uiState.icon,
                  isPulsing: uiState.isPulsing,
                ),
                const SizedBox(height: 24),
                
                // Progress
                LinearProgressIndicator(
                  value: gift.progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(uiState.color),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 32),
                
                // Details
                _buildDetailCard('Product', gift.productName),
                _buildDetailCard('Receiver', gift.receiverName),
                _buildDetailCard('Amount', 'K${gift.totalAmount.toStringAsFixed(2)}'),
                _buildDetailCard('Order ID', gift.txRef),
                
                // Proof card (only shows at status 400)
                if (gift.status == 400) ...[
                  const SizedBox(height: 24),
                  ProofCard(
                    proofUrl: gift.proofUrl,
                    zraRef: gift.zraRef,
                    zraResultCode: gift.zraResultCode,
                    aiConfidence: gift.aiConfidence ?? 0.95,
                    isVerified: gift.isVerified,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
