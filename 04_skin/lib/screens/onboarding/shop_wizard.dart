/// =============================================================================
/// KithLy Global Protocol - SHOP ONBOARDING WIZARD (Phase IV)
/// shop_wizard.dart - 5-Step Onboarding with Project Alpha Design
/// =============================================================================
///
/// Steps:
/// 1. Identity: Name, Type, NRC Upload
/// 2. Fiscal: TPIN Entry (Async ZRA validation)
/// 3. Location: Full-screen map picker
/// 4. Settlement: Mobile Money/Bank details
/// 5. Review: Summary + Submit for Approval
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding/location_picker.dart';
import '../../widgets/universal_image_picker.dart';

/// Shop onboarding wizard with Project Alpha glassmorphism design
class ShopWizardScreen extends StatefulWidget {
  const ShopWizardScreen({super.key});
  
  @override
  State<ShopWizardScreen> createState() => _ShopWizardScreenState();
}

class _ShopWizardScreenState extends State<ShopWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Form data
  final _formKey = GlobalKey<FormState>();
  String? _shopName;
  String? _ownerName;
  String _legalType = 'sole_prop';
  String? _nrcImagePath;
  String? _tpin;
  bool _tpinVerified = false;
  double? _latitude;
  double? _longitude;
  String? _address;
  String? _shopfrontImagePath;
  String _settlementType = 'mobile_money';
  String? _mobileMoneyNumber;
  String? _bankAccountNumber;
  String? _bankName;
  
  final List<StepInfo> _steps = [
    StepInfo(icon: Icons.person, title: 'Identity', subtitle: 'Shop & Owner Details'),
    StepInfo(icon: Icons.receipt_long, title: 'Fiscal', subtitle: 'ZRA Registration'),
    StepInfo(icon: Icons.location_on, title: 'Location', subtitle: 'Shop Address'),
    StepInfo(icon: Icons.account_balance_wallet, title: 'Settlement', subtitle: 'Payment Details'),
    StepInfo(icon: Icons.check_circle, title: 'Review', subtitle: 'Submit Application'),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Step content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildIdentityStep(),
                _buildFiscalStep(),
                _buildLocationStep(),
                _buildSettlementStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(),
      ),
      title: const Text('Shop Registration'),
      centerTitle: true,
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                // Step circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompleted || isCurrent
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          )
                        : null,
                    color: !isCompleted && !isCurrent ? const Color(0xFF334155) : null,
                    border: isCurrent
                        ? Border.all(color: const Color(0xFF3B82F6), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                // Connecting line
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF334155),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  // ==========================================================================
  // STEP 1: IDENTITY
  // ==========================================================================
  
  Widget _buildIdentityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(_steps[0]),
            const SizedBox(height: 24),
            
            // Shop name
            _buildGlassTextField(
              label: 'Shop Name',
              hint: 'e.g., Chilenje Hardware Store',
              icon: Icons.store,
              onChanged: (v) => _shopName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Owner name
            _buildGlassTextField(
              label: 'Owner Full Name',
              hint: 'As per NRC',
              icon: Icons.person,
              onChanged: (v) => _ownerName = v,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Legal entity type
            _buildGlassDropdown(
              label: 'Business Type',
              icon: Icons.business,
              value: _legalType,
              items: const [
                DropdownMenuItem(value: 'sole_prop', child: Text('Sole Proprietorship')),
                DropdownMenuItem(value: 'ltd', child: Text('Limited Company (Ltd)')),
                DropdownMenuItem(value: 'partnership', child: Text('Partnership')),
              ],
              onChanged: (v) => setState(() => _legalType = v!),
            ),
            const SizedBox(height: 24),
            
            // NRC Upload
            UniversalImagePicker(
              label: 'National Registration Card (NRC)',
              hint: 'Upload front of your NRC',
              icon: Icons.credit_card,
              onImageSelected: (file, path) {
                setState(() => _nrcImagePath = path);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // ==========================================================================
  // STEP 2: FISCAL (TPIN Validation)
  // ==========================================================================
  
  Widget _buildFiscalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(_steps[1]),
          const SizedBox(height: 24),
          
          // ZRA info card
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'ZRA TPIN Required',
            message: 'Enter your Taxpayer Identification Number. We will verify it with the Zambia Revenue Authority.',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          
          // TPIN input
          _buildGlassTextField(
            label: 'TPIN (10 digits)',
            hint: '0000000000',
            icon: Icons.pin,
            keyboardType: TextInputType.number,
            maxLength: 10,
            onChanged: (v) {
              _tpin = v;
              if (_tpinVerified) setState(() => _tpinVerified = false);
            },
            validator: (v) {
              if (v?.length != 10) return 'TPIN must be 10 digits';
              return null;
            },
            suffixWidget: _tpinVerified
                ? const Icon(Icons.verified, color: Color(0xFF10B981))
                : null,
          ),
          const SizedBox(height: 16),
          
          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyTpin,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _tpinVerified ? Icons.check_circle : Icons.verified_user,
                    ),
              label: Text(_tpinVerified ? 'TPIN Verified' : 'Verify with ZRA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tpinVerified
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          if (_tpinVerified) ...[
            const SizedBox(height: 24),
            _buildSuccessCard(
              title: 'ZRA Verification Successful',
              message: 'Your TPIN has been verified with the Zambia Revenue Authority.',
            ),
          ],
        ],
      ),
    );
  }
  
  // ==========================================================================
  // STEP 3: LOCATION
  // ==========================================================================
  
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(_steps[2]),
          const SizedBox(height: 24),
          
          // Location preview or picker button
          if (_latitude != null && _longitude != null) ...[
            _buildLocationPreview(),
            const SizedBox(height: 16),
          ],
          
          // Open map button
          _buildGlassButton(
            icon: Icons.map,
            label: _latitude != null ? 'Change Location' : 'Select Shop Location',
            onPressed: _openLocationPicker,
          ),
          const SizedBox(height: 24),
          
          // Shopfront photo
          UniversalImagePicker(
            label: 'Shopfront Photo',
            hint: 'Take a photo of your shop',
            icon: Icons.storefront,
            onImageSelected: (file, path) {
              setState(() => _shopfrontImagePath = path);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_pin, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location Selected',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _address ?? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF10B981)),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // STEP 4: SETTLEMENT
  // ==========================================================================
  
  Widget _buildSettlementStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(_steps[3]),
          const SizedBox(height: 24),
          
          // Settlement type selector
          Row(
            children: [
              Expanded(
                child: _buildSettlementTypeCard(
                  type: 'mobile_money',
                  icon: Icons.phone_android,
                  label: 'Mobile Money',
                  selected: _settlementType == 'mobile_money',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSettlementTypeCard(
                  type: 'bank',
                  icon: Icons.account_balance,
                  label: 'Bank Account',
                  selected: _settlementType == 'bank',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Mobile Money fields
          if (_settlementType == 'mobile_money') ...[
            _buildGlassTextField(
              label: 'Mobile Money Number',
              hint: '097XXXXXXX or 096XXXXXXX',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (v) => _mobileMoneyNumber = v,
              validator: (v) {
                if (v?.length != 10) return 'Must be 10 digits';
                if (!v!.startsWith('09') && !v.startsWith('07')) {
                  return 'Must start with 09 or 07';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Supported Networks',
              message: 'MTN, Airtel, Zamtel Mobile Money accounts are supported.',
              color: const Color(0xFFF59E0B),
            ),
          ],
          
          // Bank fields
          if (_settlementType == 'bank') ...[
            _buildGlassTextField(
              label: 'Bank Name',
              hint: 'e.g., Zanaco, Stanbic, FNB',
              icon: Icons.account_balance,
              onChanged: (v) => _bankName = v,
            ),
            const SizedBox(height: 16),
            _buildGlassTextField(
              label: 'Account Number',
              hint: 'Your bank account number',
              icon: Icons.pin,
              keyboardType: TextInputType.number,
              onChanged: (v) => _bankAccountNumber = v,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSettlementTypeCard({
    required String type,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _settlementType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                )
              : null,
          color: selected ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ==========================================================================
  // STEP 5: REVIEW
  // ==========================================================================
  
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(_steps[4]),
          const SizedBox(height: 24),
          
          // Summary card
          _buildSummaryCard(),
          const SizedBox(height: 24),
          
          // Terms acceptance
          _buildInfoCard(
            icon: Icons.gavel,
            title: 'Terms & Conditions',
            message: 'By submitting, you agree to the KithLy Shop Partner Agreement and ZRA compliance requirements.',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitApplication,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('Submit for Approval'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF334155).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Shop Name', _shopName ?? '-'),
          _buildSummaryRow('Owner', _ownerName ?? '-'),
          _buildSummaryRow('Business Type', _legalType.replaceAll('_', ' ').toUpperCase()),
          _buildSummaryRow('TPIN', _tpin ?? '-', verified: _tpinVerified),
          _buildSummaryRow('Location', _address ?? (_latitude != null ? 'Selected' : '-')),
          _buildSummaryRow('Settlement', _settlementType == 'mobile_money'
              ? _mobileMoneyNumber ?? '-'
              : _bankAccountNumber ?? '-'),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool verified = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // REUSABLE WIDGETS
  // ==========================================================================
  
  Widget _buildStepHeader(StepInfo step) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(step.icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              step.subtitle,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildGlassTextField({
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    Widget? suffixWidget,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            prefixIcon: Icon(icon, color: Colors.white38),
            suffixIcon: suffixWidget,
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            counterText: '',
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
  
  Widget _buildGlassDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessCard({
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          if (_currentStep < _steps.length - 1)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _canProceed() ? _nextStep : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // ACTIONS
  // ==========================================================================
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _shopName?.isNotEmpty == true && _ownerName?.isNotEmpty == true;
      case 1:
        return _tpinVerified;
      case 2:
        return _latitude != null && _longitude != null;
      case 3:
        if (_settlementType == 'mobile_money') {
          return _mobileMoneyNumber?.length == 10;
        } else {
          return _bankAccountNumber?.isNotEmpty == true;
        }
      default:
        return true;
    }
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _verifyTpin() async {
    if (_tpin?.length != 10) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Call API to verify TPIN
      // final response = await api.post('/shop/onboard/step-2', { tpin: _tpin });
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      setState(() => _tpinVerified = true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TPIN verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _address = result['address'];
      });
    }
  }
  
  Future<void> _submitApplication() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Call API to submit application
      // await api.post('/shop/onboard/complete', { shop_id: ... });
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showSuccessDialog();
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our team will review your application and approve within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Exit Registration?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will not be saved.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class StepInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  
  StepInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
