import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/error_widget.dart';
import '../../services/shop_repository.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text(
          'Concierge & Support',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.midnight, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnight.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent_outlined,
                        color: AppColors.gold,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How Can We Assist You?',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              color: AppColors.ivory,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Our concierge team is here for your family and every precious question.',
                            style: TextStyle(
                              color: AppColors.ivory.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warmBeige, width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warmBeige,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_mall_outlined,
                        color: AppColors.navy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order, Product, or Delivery Inquiries',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.midnight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share your message below. A dedicated member of our team will review your request promptly.',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _message,
                minLines: 4,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final text = _message.text.trim();
                        if (text.isEmpty) return;
                        setState(() => _busy = true);
                        try {
                          await context.read<ShopRepository>().submitSupport(
                            text,
                          );
                          _message.clear();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message sent to our concierge team.'),
                                backgroundColor: AppColors.midnight,
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) showErrorMessage(context, error);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.ivory,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _busy ? 'Sending Message...' : 'Send Message to Concierge',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
