import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reducer/core/theme/app_spacing.dart';
import 'package:reducer/core/theme/app_text_styles.dart';
import 'package:reducer/shared/widgets/app_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AlreadyProState extends StatelessWidget {
  const AlreadyProState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Stack(
        children: [
          // Premium Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: const Text('PRO MEMBERSHIP', style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFACC15).withValues(alpha: 0.1),
                              border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.2)),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 80,
                              color: Color(0xFFFACC15),
                            ),
                          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 32),
                          const Text(
                            "You're an Elite Member",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 16),
                          Text(
                            "Thank you for your support! You have full access to all Pro tools, AI upscaling, and an ad-free experience.",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: Colors.white60,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 400.ms),
                          const SizedBox(height: 48),
                          AppButton(
                            label: 'Manage Subscription',
                            icon: Icons.settings,
                            style: AppButtonStyle.outline,
                            onPressed: () => _openSubscriptionManagement(),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
