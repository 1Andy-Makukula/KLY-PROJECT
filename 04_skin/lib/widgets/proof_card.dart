/// =============================================================================
/// KithLy Global Protocol - PROOF CARD WIDGET (Phase IV Enhanced)
/// proof_card.dart - Evidence Preview with Gemini/ZRA Verification
/// =============================================================================
///
/// This widget ONLY appears when GiftProvider status is 400 (COMPLETED)
/// Displays: Gemini-verified photo URL + ZRA Receipt ID
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Proof card widget for displaying verified delivery evidence
/// Only visible when status == 400
class ProofCard extends StatelessWidget {
  final String? proofUrl;
  final String? zraRef;
  final String? zraResultCode;
  final double? aiConfidence;
  final bool isVerified;
  
  const ProofCard({
    super.key,
    this.proofUrl,
    this.zraRef,
    this.zraResultCode,
    this.aiConfidence,
    this.isVerified = false,
  });
  
  bool get hasZraVerification => zraResultCode == '000' || zraResultCode == '001';
  bool get hasGeminiVerification => aiConfidence != null && aiConfidence! >= 0.85;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            isVerified
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFF1E293B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified 
              ? const Color(0xFF10B981).withOpacity(0.5) 
              : Colors.white.withOpacity(0.05),
          width: isVerified ? 2 : 1,
        ),
        boxShadow: [
          if (isVerified)
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(),
          
          // Photo
          _buildPhoto(),
          
          // Verification details
          _buildVerificationDetails(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF10B981).withOpacity(0.1)
            : Colors.white.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.verified : Icons.receipt_long,
              color: isVerified ? const Color(0xFF10B981) : Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Proof',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'AI & Tax Verified',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPhoto() {
    if (proofUrl != null) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: CachedNetworkImage(
              imageUrl: proofUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFF334155),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF334155),
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white38,
                  size: 48,
                ),
              ),
            ),
          ),
          // Gemini verification overlay
          if (hasGeminiVerification)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF3B82F6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'AI ${(aiConfidence! * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: const Color(0xFF334155),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white38, size: 48),
            SizedBox(height: 8),
            Text(
              'Awaiting proof upload',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gemini AI Verification
          if (aiConfidence != null)
            _buildVerificationRow(
              icon: Icons.psychology,
              iconColor: const Color(0xFF3B82F6),
              label: 'Gemini Vision AI',
              value: '${(aiConfidence! * 100).toStringAsFixed(0)}% Match',
              isVerified: hasGeminiVerification,
            ),
          
          // ZRA Tax Receipt
          if (hasZraVerification) ...[
            const SizedBox(height: 12),
            _buildVerificationRow(
              icon: Icons.receipt,
              iconColor: const Color(0xFF10B981),
              label: 'ZRA Tax Receipt',
              value: zraRef ?? 'Verified',
              isVerified: true,
            ),
          ],
          
          // Full verification badge
          if (isVerified && hasZraVerification && hasGeminiVerification) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.15),
                    const Color(0xFF3B82F6).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF10B981), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dual Verified Delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Confirmed by Gemini Vision AI & ZRA Tax Authority',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Action buttons (Download/Print)
          if (isVerified) ...[
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Download PDF button
        Expanded(
          child: _ActionButton(
            icon: Icons.download,
            label: 'Download PDF',
            color: const Color(0xFF3B82F6),
            onPressed: () {
              // Trigger PDF generation and download
              // ReceiptGenerator.instance.generateReceipt(...)
            },
          ),
        ),
        const SizedBox(width: 12),
        // Print Receipt button
        Expanded(
          child: _ActionButton(
            icon: Icons.print,
            label: 'Print Receipt',
            color: const Color(0xFF10B981),
            onPressed: () {
              // Trigger thermal print
              // ThermalPrinterBridge.generateThermalText(...)
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerificationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isVerified = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isVerified ? iconColor : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (isVerified)
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
      ],
    );
  }
}

/// Compact proof badge for list views
class ProofBadge extends StatelessWidget {
  final bool hasProof;
  final bool isVerified;
  
  const ProofBadge({
    super.key,
    this.hasProof = false,
    this.isVerified = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!hasProof) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVerified
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                .withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.pending,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for Download/Print actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
