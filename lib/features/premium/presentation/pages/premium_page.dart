import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:reducer/features/premium/premium.dart';
import 'package:reducer/core/theme/design_tokens.dart';


class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final notifier = ref.read(premiumControllerProvider.notifier);

    if (state.errorMessage.isNotEmpty) {
      return _buildErrorState(context, notifier, state.errorMessage);
    }

    if (state.availablePackages.isEmpty) {
      return const Center(
        child: Text(
          "No plans available",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/premium_screen/bg_image.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue.shade50),
            ),
          ),

          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: _buildCloseButton(context),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 255, 16, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                   Center(
                    child: Text(
                      "Unlock Premium",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Benefits
                  _infoRow("Unlimited access"),
                  _infoRow("Ad-free experience"),
                  _infoRow("Priority support"),

                  const SizedBox(height: 10),

                  // Packages
                  Flexible(child: _buildPackagesList(state, notifier)),
                  _buildSubscribeButton(context, state, notifier),
                  const SizedBox(height: 10),

                  // Auto-renew
                  const Center(
                    child: Text(
                      "Subscriptions auto-renew. Cancel anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Center(child: _buildFooterLinks(notifier, context)),
                ],
              ),
            ),
          ),

          if (state.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Image.asset(
        "assets/premium_screen/close_icon.png", 
        width: 35,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.close, size: 35),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, PurchaseNotifier notifier, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: notifier.fetchOffersAndCheckStatus,
              icon: const Icon(Icons.refresh),
              label: const Text("Try again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList(PurchaseState state, PurchaseNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: state.availablePackages
          .map(
            (package) => _PackageCard(
              package: package,
              isSelected: package == state.selectedPackage,
              onTap: () => notifier.selectPackage(package),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSubscribeButton(BuildContext context, PurchaseState state, PurchaseNotifier notifier) {
    final selected = state.selectedPackage;
    final isLoading = state.isLoading;

    return GestureDetector(
      onTap: () async {
        if (selected == null || isLoading) return;
        final success = await notifier.purchaseSelectedPackage();
        if (!success) return;
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        height: 43,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [DesignTokens.accentBlue, DesignTokens.primaryBlue],
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/common/king_icon.png",
                color: Colors.white,
                width: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                "Subscribe Now",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.75),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLinks(PurchaseNotifier notifier, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(
          child: Text(
            "Terms of use",
            style: TextStyle(fontSize: 14, color: Color(0xFF6C6C6C)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "|",
            style: TextStyle(fontSize: 16, color: Color(0xFF6C6C6C)),
          ),
        ),
        const Flexible(
          child: Text(
            "Privacy Policy",
            style: TextStyle(fontSize: 13, color: Color(0xFF6C6C6C)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "|",
            style: TextStyle(fontSize: 16, color: Color(0xFF6C6C6C)),
          ),
        ),
        Flexible(
          child: GestureDetector(
            onTap: () async {
              await notifier.restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Restore completed")),
                );
              }
            },
            child: const Text(
              "Restore",
              style: TextStyle(fontSize: 13, color: Color(0xFF6C6C6C)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          "assets/premium_screen/black_check_icon.png", 
          width: 22,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, size: 22, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ProductDetails package;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isYearly => _containsAny(
    package.title,
    package.id,
    ['year', 'annual', '12month', 'yr'],
  );

  bool get _isWeekly => _containsAny(
    package.title,
    package.id,
    ['week', 'weekly', '7day', '7d'],
  );

  bool get _isMonthly =>
      !_isWeekly &&
          !_isYearly &&
          _containsAny(
            package.title,
            package.id,
            ['month', 'monthly', '1month', 'mo'],
          );

  static bool _containsAny(String a, String b, List<String> terms) {
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    return terms.any((t) => lowerA.contains(t) || lowerB.contains(t));
  }

  String _getTitleText() {
    if (_isYearly) return "Yearly Plan";
    if (_isMonthly) return "Monthly Plan";
    if (_isWeekly) return "Weekly Plan";
    return package.price;
  }

  String _getPeriodText() {
    final price = package.price;
    if (_isYearly) return "Pay For $price Year";
    if (_isMonthly) return "Pay For $price Monthly";
    if (_isWeekly) return "Pay For $price Week";
    return price;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? DesignTokens.primaryBlue.withOpacity(0.5) : const Color(0xFFE9E9E9),
              width: 1.5,
            ),
            gradient: isSelected
                ? const LinearGradient(
              colors: [
                DesignTokens.accentBlue,
                DesignTokens.lightBg,
                DesignTokens.accentBlue,
                DesignTokens.lightBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? null : Colors.white,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Image.asset(
                      isSelected
                          ? "assets/premium_screen/check_icon.png"
                          : "assets/premium_screen/uncheck_icon.png",
                      width: 28,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? DesignTokens.primaryBlue : Colors.grey,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTitleText(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPeriodText(),
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.black : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      package.price,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: isSelected ? Colors.black : const Color(0xFF6C6C6C),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isYearly)
                Positioned(
                  top: -15,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DesignTokens.accentBlue, DesignTokens.primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "20% OFF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
