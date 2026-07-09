import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_control/models/device_models.dart';
import '../data/hardware_database.dart';
import '../pages/setup_verification_page.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? _selectedCategoryId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // --- Color Palette ---
  static const Color _bgColor = Color(0xFF0A0A0A);
  static const Color _cardColor = Color(0xFF1C1C1E);
  static const Color _accentColor = Color(
    0xFF5E5CE6,
  ); // Modern Purple/Blue Accent
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF8E8E93);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Select Device';
    if (_selectedCategoryId != null) {
      final selectedCat = HardwareDatabase.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
      title = selectedCat.name;
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _textPrimary,
            size: 22,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_selectedCategoryId != null) {
              setState(() {
                _selectedCategoryId = null;
                _searchQuery = "";
                _searchController.clear();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            title,
            key: ValueKey(title),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          // Slide transition from right
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _selectedCategoryId == null
            ? _buildCategoryGrid()
            : _buildBrandSelectionSection(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      key: const ValueKey('CategoryGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: HardwareDatabase.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final category = HardwareDatabase.categories[index];
        return _CategoryCard(
          category: category,
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
        );
      },
    );
  }

  Widget _buildBrandSelectionSection() {
    final activeBrands = HardwareDatabase.getBrandsForCategory(
      _selectedCategoryId!,
    );

    final searchFiltered = activeBrands
        .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final popularBrands = searchFiltered.where((b) => b.isPopular).toList();
    final allBrands = searchFiltered.where((b) => !b.isPopular).toList();

    return Column(
      key: const ValueKey('BrandSection'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: _textPrimary),
              cursorColor: _accentColor,
              decoration: InputDecoration(
                hintText: 'Search brands...',
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                prefixIcon: Icon(
                  Icons.search,
                  color: _textSecondary.withOpacity(0.6),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Popular Brands Section
              if (popularBrands.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: popularBrands
                      .map(
                        (brand) => _BrandPill(
                          name: brand.name,
                          onTap: () => _handleBrandTap(brand.name),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
              ],

              // All Brands Section
              if (allBrands.isNotEmpty) ...[
                const Text(
                  'ALL BRANDS',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allBrands.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 20,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      itemBuilder: (context, idx) {
                        return _BrandListTile(
                          name: allBrands[idx].name,
                          onTap: () => _handleBrandTap(allBrands[idx].name),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _handleBrandTap(String brandName) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetupVerificationPage(
          categoryId: _selectedCategoryId!,
          brandName: brandName,
        ),
      ),
    );
  }
}

// --- Custom Widgets ---

class _CategoryCard extends StatefulWidget {
  final DeviceCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  static const Color _accentColor = Color(0xFF5E5CE6);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: _isPressed
                ? const Color(0xFF2C2C2E)
                : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(_isPressed ? 0.1 : 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? _accentColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.category.icon,
                  color: _isPressed ? _accentColor : const Color(0xFF8E8E93),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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

class _BrandPill extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _BrandPill({required this.name, required this.onTap});

  static const Color _accentColor = Color(0xFF5E5CE6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: _accentColor.withOpacity(0.3)),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: _accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandListTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _BrandListTile({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }
}
