import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/premium_provider.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumProvider);
    final notifier = ref.read(premiumProvider.notifier);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (Using gradient as fallback for image)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3FDFD), Color(0xFFCBF1F5)],
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: InkWell(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.close, size: 30, color: Colors.black54),
                ),
              ),
            ),
          ),

          // Main content
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
            _buildErrorState(ref, state.errorMessage!)
          else if (state.availablePackages.isEmpty && !state.isLoading)
            const Center(child: Text("No plans available at the moment."))
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Center(
                      child: Text(
                        "Unlock Premium Features",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Benefits
                    _infoRow("Unlimited Access to all features"),
                    const SizedBox(height: 10),
                    _infoRow("Ad-Free Experience"),
                    const SizedBox(height: 10),
                    _infoRow("Priority Support"),

                    const SizedBox(height: 30),

                    // Packages
                    Flexible(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: state.availablePackages.length,
                        itemBuilder: (context, index) {
                          final package = state.availablePackages[index];
                          return _PackageCard(
                            package: package,
                            isSelected: package == state.selectedPackage,
                            onTap: () => notifier.selectPackage(package),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSubscribeButton(context, ref, state),
                    const SizedBox(height: 10),

                    // Auto-renew
                    Text(
                      "Subscription will auto-renew. Cancel anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 15),
                    const Center(child: _FooterLinks()),
                  ],
                ),
              ),
            ),

          if (state.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(premiumProvider.notifier).fetchOffersAndCheckStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(BuildContext context, WidgetRef ref, PremiumState state) {
    return InkWell(
      onTap: () async {
        if (state.isLoading) return;
        final success = await ref.read(premiumProvider.notifier).purchase(null);
        if (success && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome to Premium!")),
          );
          context.pop();
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF7EAAFF), Color(0xFF3973FE)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3973FE).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: state.isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
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
    return Container(
      color: Colors.white54,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _infoRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF3973FE), size: 22),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _linkText("Terms of Use", () {}), // TODO: Add link
        _divider(),
        _linkText("Privacy Policy", () => context.push('/privacy-policy')),
        _divider(),
        Consumer(
          builder: (context, ref, _) => _linkText("Restore", () {
             ref.read(premiumProvider.notifier).restore();
          }),
        ),
      ],
    );
  }

  Widget _linkText(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text("|", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isYearly => _containsAny(
    package.storeProduct.title,
    package.identifier,
    ['year', 'annual', '12month', 'yr'],
  );
  
  static bool _containsAny(String a, String b, List<String> terms) {
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    return terms.any((t) => lowerA.contains(t) || lowerB.contains(t));
  }

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF3973FE) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? const Color(0xFFEFF5FF) : Colors.white,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFF3973FE) : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product.priceString,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isSelected ? const Color(0xFF3973FE) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isYearly)
                Positioned(
                  top: -12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3973FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "BEST VALUE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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


