/// =============================================================================
/// KithLy Global Protocol - DELIVERY DISPATCH CARD (Phase IV)
/// delivery_dispatch_card.dart - The "Sleeper" Delivery Bridge
/// =============================================================================
/// 
/// Hidden behind FeatureFlags.enableManualDelivery.
/// Allows shops to manually dispatch via Yango/Ulendo tracking links.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/alpha_theme.dart';
import '../../config/feature_flags.dart';

/// Delivery Dispatch Card - Manual delivery tracking integration
/// 
/// Usage: Wrap in `if (FeatureFlags.enableManualDelivery) DeliveryDispatchCard(...)`
class DeliveryDispatchCard extends StatefulWidget {
  final String txId;
  final String recipientName;
  final String productName;
  final VoidCallback? onDispatched;
  
  const DeliveryDispatchCard({
    super.key,
    required this.txId,
    required this.recipientName,
    required this.productName,
    this.onDispatched,
  });
  
  /// Helper to conditionally render based on feature flag
  static Widget? maybeShow({
    required String txId,
    required String recipientName,
    required String productName,
    VoidCallback? onDispatched,
  }) {
    if (!FeatureFlags.enableManualDelivery) return null;
    
    return DeliveryDispatchCard(
      txId: txId,
      recipientName: recipientName,
      productName: productName,
      onDispatched: onDispatched,
    );
  }
  
  @override
  State<DeliveryDispatchCard> createState() => _DeliveryDispatchCardState();
}

class _DeliveryDispatchCardState extends State<DeliveryDispatchCard> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  // Supported tracking URL patterns
  final List<_DeliveryProvider> _providers = [
    _DeliveryProvider(
      name: 'Yango',
      icon: Icons.local_taxi,
      color: const Color(0xFFFFCC00),
      pattern: RegExp(r'yango\.com|yandex\.com'),
    ),
    _DeliveryProvider(
      name: 'Ulendo',
      icon: Icons.delivery_dining,
      color: const Color(0xFF00C853),
      pattern: RegExp(r'ulendo\.'),
    ),
    _DeliveryProvider(
      name: 'Bolt',
      icon: Icons.electric_bolt,
      color: const Color(0xFF34D186),
      pattern: RegExp(r'bolt\.eu|bolt\.com'),
    ),
    _DeliveryProvider(
      name: 'Other',
      icon: Icons.link,
      color: AlphaTheme.accentBlue,
      pattern: RegExp(r'.*'),
    ),
  ];
  
  _DeliveryProvider? _detectedProvider;
  
  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }
  
  void _onTrackingLinkChanged(String value) {
    setState(() {
      _error = null;
      _detectedProvider = _detectProvider(value);
    });
  }
  
  _DeliveryProvider? _detectProvider(String link) {
    if (link.isEmpty) return null;
    
    for (final provider in _providers) {
      if (provider.pattern.hasMatch(link.toLowerCase())) {
        return provider;
      }
    }
    return null;
  }
  
  Future<void> _markDispatched() async {
    final link = _trackingController.text.trim();
    
    if (link.isEmpty) {
      setState(() => _error = 'Please paste a tracking link');
      return;
    }
    
    if (!Uri.tryParse(link)!.hasScheme) {
      setState(() => _error = 'Please enter a valid URL');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // TODO: Call API to update order with delivery tracking
      // await ApiService.markDispatched(widget.txId, link);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      HapticFeedback.heavyImpact();
      widget.onDispatched?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_detectedProvider?.icon ?? Icons.check_circle,
                    color: AlphaTheme.accentGreen),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Order marked as dispatched!'),
                ),
              ],
            ),
            backgroundColor: AlphaTheme.backgroundCard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to update: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AlphaTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AlphaTheme.accentBlue.withOpacity(0.2),
                    borderRadius: AlphaTheme.buttonRadius,
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AlphaTheme.accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispatch Delivery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'For ${widget.recipientName}',
                        style: AlphaTheme.captionText,
                      ),
                    ],
                  ),
                ),
                // Detected provider badge
                if (_detectedProvider != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _detectedProvider!.color.withOpacity(0.2),
                      borderRadius: AlphaTheme.chipRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _detectedProvider!.icon,
                          color: _detectedProvider!.color,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _detectedProvider!.name,
                          style: TextStyle(
                            color: _detectedProvider!.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          
          // Product info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AlphaTheme.backgroundGlass,
                borderRadius: AlphaTheme.chipRadius,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    color: AlphaTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: AlphaTheme.bodyText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tracking link input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste tracking link from:',
                  style: TextStyle(
                    color: AlphaTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Provider chips
                Wrap(
                  spacing: 8,
                  children: _providers.take(3).map((p) => Chip(
                    avatar: Icon(p.icon, size: 16, color: p.color),
                    label: Text(p.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AlphaTheme.backgroundGlass,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _trackingController,
                  onChanged: _onTrackingLinkChanged,
                  decoration: InputDecoration(
                    hintText: 'https://yango.com/track/...',
                    hintStyle: TextStyle(
                      color: AlphaTheme.textMuted.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      _detectedProvider?.icon ?? Icons.link,
                      color: _detectedProvider?.color ?? AlphaTheme.textMuted,
                    ),
                    suffixIcon: _trackingController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _trackingController.clear();
                              setState(() {
                                _detectedProvider = null;
                                _error = null;
                              });
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.paste, size: 20),
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null) {
                                _trackingController.text = data!.text!;
                                _onTrackingLinkChanged(data.text!);
                              }
                            },
                          ),
                    filled: true,
                    fillColor: AlphaTheme.backgroundGlass,
                    border: OutlineInputBorder(
                      borderRadius: AlphaTheme.buttonRadius,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AlphaTheme.buttonRadius,
                      borderSide: const BorderSide(
                        color: AlphaTheme.accentBlue,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AlphaTheme.buttonRadius,
                      borderSide: const BorderSide(
                        color: AlphaTheme.accentRed,
                        width: 2,
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                
                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AlphaTheme.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _markDispatched,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(_isLoading ? 'Dispatching...' : 'Mark Dispatched'),
                style: AlphaTheme.primaryButton.copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryProvider {
  final String name;
  final IconData icon;
  final Color color;
  final RegExp pattern;
  
  const _DeliveryProvider({
    required this.name,
    required this.icon,
    required this.color,
    required this.pattern,
  });
}
