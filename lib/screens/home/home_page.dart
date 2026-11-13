import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/section_title.dart';
import '../../widgets/category_strip.dart';
import '../../widgets/product_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.user,
    required this.category,
    required this.collectionKey,
    required this.onCategorySelected,
    required this.onSeeAllCategories,
    super.key,
  });

  final User? user;
  final String category;
  final GlobalKey collectionKey;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onSeeAllCategories;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _newsletterController = TextEditingController();
  final _homeScrollController = ScrollController();
  String _search = '';
  String _selectedStage = '';

  @override
  void dispose() {
    _searchController.dispose();
    _newsletterController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  void _onStageSelected(String stage, String keyword) {
    setState(() {
      if (_selectedStage == stage) {
        _selectedStage = '';
        _search = '';
        _searchController.clear();
      } else {
        _selectedStage = stage;
        _search = keyword;
        _searchController.text = keyword;
      }
    });
  }

  void _handleSubscribe() {
    final email = _newsletterController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _newsletterController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for joining the BabyShop list, $email.'),
        backgroundColor: AppColors.darkGreen,
      ),
    );
  }

  Future<void> _scrollToCollection() async {
    final targetContext = widget.collectionKey.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    thumbVisibility: true,
    interactive: true,
    controller: _homeScrollController,
    child: CustomScrollView(
      controller: _homeScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A World of Little Wonders.',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 25,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.midnight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Premium quality for every precious moment.',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {
                    _search = value.trim();
                    if (_selectedStage.isNotEmpty &&
                        !_search.contains(_selectedStage.toLowerCase())) {
                      _selectedStage = '';
                    }
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search baby clothes, toys, nursery, brands...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.navy,
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                                _selectedStage = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                const _TrustBadgesStrip(),
                const SizedBox(height: 16),

                _HeroBanner(onExplore: _scrollToCollection),
                const SizedBox(height: 22),

                const SectionTitle(title: 'Shop by baby stage'),
                const SizedBox(height: 10),
                _StageSelector(
                  selectedStage: _selectedStage,
                  onStageTap: _onStageSelected,
                ),
                const SizedBox(height: 22),

                SectionTitle(
                  title: 'Shop by category',
                  action: 'See all',
                  onTap: widget.onSeeAllCategories,
                ),
                const SizedBox(height: 10),
                CategoryStrip(
                  selected: widget.category,
                  onSelected: (category) => widget.onCategorySelected(
                    category == widget.category ? '' : category,
                  ),
                ),
                const SizedBox(height: 22),

                SectionTitle(
                  key: widget.collectionKey,
                  title: _search.isNotEmpty
                      ? 'Search results for "$_search"'
                      : widget.category.isNotEmpty
                      ? 'Category: ${widget.category}'
                      : 'Featured products',
                  action: (_search.isNotEmpty || widget.category.isNotEmpty)
                      ? 'Clear filter'
                      : null,
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _search = '';
                      _selectedStage = '';
                    });
                    if (widget.category.isNotEmpty) {
                      widget.onCategorySelected('');
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        ProductGrid(category: widget.category, search: _search),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpecialBundleBanner(onExplore: widget.onSeeAllCategories),
                const SizedBox(height: 28),

                const SectionTitle(title: 'Why choose BabyShop'),
                const SizedBox(height: 12),
                const _WhyChooseBabyShop(),
                const SizedBox(height: 28),

                _ParentingTipCard(
                  onSupportTap: () =>
                      AppRoutes.push<void>(context, AppRoutes.support),
                ),
                const SizedBox(height: 28),

                _NewsletterBox(
                  controller: _newsletterController,
                  onSubscribe: _handleSubscribe,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _ShopFooter(
            onCategories: widget.onSeeAllCategories,
            onOrders: () {
              if (widget.user == null) {
                openAuth(context);
              } else {
                AppRoutes.push<void>(context, AppRoutes.orders);
              }
            },
            onSupport: () {
              if (widget.user == null) {
                openAuth(context);
              } else {
                AppRoutes.push<void>(context, AppRoutes.support);
              }
            },
          ),
        ),
      ],
    ),
  );
}

class _TrustBadgesStrip extends StatelessWidget {
  const _TrustBadgesStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warmBeige),
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceAround,
        runAlignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          _TrustItem(
            icon: Icons.local_shipping_outlined,
            title: 'Thoughtfully chosen',
            subtitle: 'Little details, big care',
          ),
          _TrustItem(
            icon: Icons.inventory_2_outlined,
            title: 'Live availability',
            subtitle: 'See current product stock',
          ),
          _TrustItem(
            icon: Icons.lock_outline,
            title: 'Secure checkout',
            subtitle: 'A simple, safe order flow',
          ),
          _TrustItem(
            icon: Icons.support_agent_outlined,
            title: 'Here to help',
            subtitle: 'Contact our support team',
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.midnight),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.midnight,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.navy.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// HERO PROMOTIONAL BANNER
// -------------------------------------------------------------
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.midnight, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Text(
                    'BABYSHOP',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A World of\nLittle Wonders.',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: compact ? 25 : 30,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Premium quality for every precious moment.',
                  style: TextStyle(
                    color: AppColors.ivory,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: onExplore,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Shop collection'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.midnight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ivory.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 15,
                            color: AppColors.gold,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Lovingly curated',
                            style: TextStyle(
                              color: AppColors.ivory,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: compact ? 68 : 106,
            height: compact ? 78 : 120,
            decoration: BoxDecoration(
              color: AppColors.ivory.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(compact ? 34 : 52),
            ),
            child: Icon(
              Icons.child_care_rounded,
              color: AppColors.gold,
              size: compact ? 36 : 52,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SHOP BY STAGE / AGE SELECTOR
// -------------------------------------------------------------
class _StageSelector extends StatelessWidget {
  const _StageSelector({required this.selectedStage, required this.onStageTap});

  final String selectedStage;
  final void Function(String stage, String keyword) onStageTap;

  @override
  Widget build(BuildContext context) {
    final stages = [
      {
        'title': 'Newborn (0-3M)',
        'keyword': 'newborn',
        'icon': Icons.baby_changing_station,
      },
      {
        'title': 'Infant (3-12M)',
        'keyword': 'infant',
        'icon': Icons.child_friendly,
      },
      {
        'title': 'Toddler (1-3Y)',
        'keyword': 'toddler',
        'icon': Icons.toys_outlined,
      },
      {
        'title': 'Little Steps (3Y+)',
        'keyword': 'clothing',
        'icon': Icons.directions_walk_rounded,
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = stages[index];
          final title = item['title'] as String;
          final keyword = item['keyword'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selectedStage == title;

          return InkWell(
            onTap: () => onStageTap(title, keyword),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : AppColors.ivory,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.warmBeige,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? AppColors.midnight : AppColors.navy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.midnight,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// SPECIAL BUNDLE PROMO BANNER
// -------------------------------------------------------------
class _SpecialBundleBanner extends StatelessWidget {
  const _SpecialBundleBanner({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'SPECIAL COLLECTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnight,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Little things, thoughtfully chosen',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Explore special collections made for the milestones, routines and everyday moments that matter.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onExplore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.midnight,
                    side: const BorderSide(color: AppColors.midnight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Explore categories'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.midnight.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.gold,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyChooseBabyShop extends StatelessWidget {
  const _WhyChooseBabyShop();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (
        Icons.auto_awesome_outlined,
        'Thoughtful picks',
        'A considered edit for little ones.',
      ),
      (
        Icons.inventory_2_outlined,
        'Live availability',
        'Product stock shown as it changes.',
      ),
      (
        Icons.favorite_border,
        'Save your favorites',
        'Keep special finds close at hand.',
      ),
      (
        Icons.support_agent_outlined,
        'Personal support',
        'Our team is here when you need us.',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: benefits.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) {
            final benefit = benefits[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warmBeige,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(benefit.$1, size: 22, color: AppColors.navy),
                  const SizedBox(height: 8),
                  Text(
                    benefit.$2,
                    style: const TextStyle(
                      color: AppColors.midnight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    benefit.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.navy, fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// PARENTING ADVICE TIP CARD
// -------------------------------------------------------------
class _ParentingTipCard extends StatelessWidget {
  const _ParentingTipCard({required this.onSupportTap});

  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For every little moment',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'From first days to new routines, discover thoughtful essentials for your family and the moments you will treasure.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.navy,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onSupportTap,
                  child: const Text(
                    'Need advice? Ask our boutique support team →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
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
}

// -------------------------------------------------------------
// NEWSLETTER / VIP CLUB SIGNUP BOX
// -------------------------------------------------------------
class _NewsletterBox extends StatelessWidget {
  const _NewsletterBox({required this.controller, required this.onSubscribe});

  final TextEditingController controller;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmBeige),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnight.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                color: AppColors.gold,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Join the BabyShop Family',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Join us for considered updates and little moments of inspiration.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.navy.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.warmBeige),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.warmBeige),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onSubscribe,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.ivory,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Subscribe'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// FOOTER
// -------------------------------------------------------------
class _ShopFooter extends StatelessWidget {
  const _ShopFooter({
    required this.onCategories,
    required this.onOrders,
    required this.onSupport,
  });

  final VoidCallback onCategories;
  final VoidCallback onOrders;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.darkGreen,
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BabyShop • A World of Little Wonders.',
              style: TextStyle(
                fontFamily: 'Georgia',
                color: AppColors.ivory,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _FooterFact(
                  icon: Icons.inventory_2_outlined,
                  label: 'Live product availability',
                ),
                _FooterFact(
                  icon: Icons.support_agent,
                  label: 'Dedicated customer support',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: onCategories,
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      color: AppColors.ivory.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOrders,
                  child: Text(
                    'My orders',
                    style: TextStyle(
                      color: AppColors.ivory.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSupport,
                  child: Text(
                    'Contact support',
                    style: TextStyle(
                      color: AppColors.ivory.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _FooterFact extends StatelessWidget {
  const _FooterFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.gold),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(color: AppColors.ivory.withValues(alpha: 0.75)),
      ),
    ],
  );
}
