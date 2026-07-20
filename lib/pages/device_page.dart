import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_control/models/device_models.dart';
import '../data/hardware_database.dart';
import '../pages/setup_verification_page.dart';

const _bg = Color(0xFF080810);
const _surface = Color(0xFF10101C);
const _surfaceAlt = Color(0xFF18182A);
const _border = Color(0xFF22223A);
const _accent = Color(0xFF6C63FF);
const _textPri = Color(0xFFF2F2FA);
const _textSec = Color(0xFF7070A0);

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Per-category tint — hardware product aesthetic
  Color _tintForCategory(String id) {
    switch (id) {
      case 'tv':
      case 'mitv':
      case 'smartbox':
        return const Color(0xFF6C63FF);
      case 'ac':
        return const Color(0xFF00D2FF);
      case 'fan':
        return const Color(0xFF3ECF8E);
      default:
        return const Color(0xFFFFB547);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inCategory = _selectedCategoryId != null;
    final categoryName = inCategory
        ? HardwareDatabase.categories
              .firstWhere((c) => c.id == _selectedCategoryId)
              .name
        : null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (inCategory) {
              setState(() {
                _selectedCategoryId = null;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _textPri,
              size: 18,
            ),
          ),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(_selectedCategoryId),
            children: [
              if (inCategory)
                Text(
                  'SELECT BRAND',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              Text(
                inCategory ? categoryName! : 'Add Device',
                style: const TextStyle(
                  color: _textPri,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: inCategory
            ? _BrandView(
                key: ValueKey(_selectedCategoryId),
                categoryId: _selectedCategoryId!,
                tint: _tintForCategory(_selectedCategoryId!),
                searchQuery: _searchQuery,
                searchController: _searchController,
                onSearch: (q) => setState(() => _searchQuery = q),
                onBrandTap: (brand) {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SetupVerificationPage(
                        categoryId: _selectedCategoryId!,
                        brandName: brand,
                      ),
                    ),
                  );
                },
              )
            : _CategoryGrid(
                key: const ValueKey('grid'),
                tintForCategory: _tintForCategory,
                onCategoryTap: (id) {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedCategoryId = id);
                },
              ),
      ),
    );
  }
}

// ─── Category grid ────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final Color Function(String) tintForCategory;
  final void Function(String) onCategoryTap;

  const _CategoryGrid({
    super.key,
    required this.tintForCategory,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final cats = HardwareDatabase.categories;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: cats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) => _CategoryCard(
        category: cats[i],
        tint: tintForCategory(cats[i].id),
        onTap: () => onCategoryTap(cats[i].id),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final DeviceCategory category;
  final Color tint;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.tint,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _pressed ? widget.tint.withValues(alpha: 0.08) : _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed ? widget.tint.withValues(alpha: 0.35) : _border,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.tint.withValues(alpha: 0.15),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with category tint
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.tint.withValues(alpha: 0.2)),
                ),
                child: Icon(widget.category.icon, color: widget.tint, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                widget.category.name,
                style: const TextStyle(
                  color: _textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Brand view ───────────────────────────────────────────────────
class _BrandView extends StatelessWidget {
  final String categoryId;
  final Color tint;
  final String searchQuery;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final void Function(String) onBrandTap;

  const _BrandView({
    super.key,
    required this.categoryId,
    required this.tint,
    required this.searchQuery,
    required this.searchController,
    required this.onSearch,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    final all = HardwareDatabase.getBrandsForCategory(categoryId);
    final filtered = searchQuery.isEmpty
        ? all
        : all
              .where(
                (b) => b.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();
    final popular = filtered.where((b) => b.isPopular).toList();
    final rest = filtered.where((b) => !b.isPopular).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              style: const TextStyle(color: _textPri, fontSize: 14),
              cursorColor: tint,
              decoration: InputDecoration(
                hintText: 'Search brands…',
                hintStyle: const TextStyle(color: _textSec, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _textSec,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // Popular
              if (popular.isNotEmpty) ...[
                _SectionLabel(label: 'Popular', tint: tint),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popular
                      .map(
                        (b) => _BrandPill(
                          name: b.name,
                          tint: tint,
                          onTap: () => onBrandTap(b.name),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 28),
              ],

              // All brands
              if (rest.isNotEmpty) ...[
                _SectionLabel(label: 'All Brands', tint: tint),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rest.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, indent: 56, color: _border),
                      itemBuilder: (_, i) => _BrandRow(
                        name: rest[i].name,
                        tint: tint,
                        onTap: () => onBrandTap(rest[i].name),
                      ),
                    ),
                  ),
                ),
              ],

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No brands match "$searchQuery"',
                      style: const TextStyle(color: _textSec, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color tint;
  const _SectionLabel({required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: tint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BrandPill extends StatelessWidget {
  final String name;
  final Color tint;
  final VoidCallback onTap;
  const _BrandPill({
    required this.name,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: tint,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final String name;
  final Color tint;
  final VoidCallback onTap;
  const _BrandRow({
    required this.name,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.memory_rounded, color: tint, size: 14),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: _textPri, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textSec, size: 18),
          ],
        ),
      ),
    );
  }
}
