import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- DATA MODELS ---
class DeviceCategory {
  final String id;
  final String name;
  final IconData icon;

  const DeviceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class Brand {
  final String name;
  final bool isPopular;

  const Brand({required this.name, this.isPopular = false});
}

// --- MAIN DEVICE SELECTION SCREEN ---
class DevicePage extends StatefulWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? _selectedCategoryId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // 1. Device Categories matching your grid look
  final List<DeviceCategory> _categories = [
    const DeviceCategory(
      id: 'mitv',
      name: 'Mi TV/Mi Box',
      icon: Icons.tv_rounded,
    ),
    const DeviceCategory(id: 'tv', name: 'TV', icon: Icons.tv_off_rounded),
    const DeviceCategory(
      id: 'stb',
      name: 'Set-top box',
      icon: Icons.developer_board,
    ),
    const DeviceCategory(id: 'ac', name: 'AC', icon: Icons.air_rounded),
    const DeviceCategory(id: 'fan', name: 'Fan', icon: Icons.toys_rounded),
    const DeviceCategory(
      id: 'smartbox',
      name: 'Smart box',
      icon: Icons.dns_rounded,
    ),
    const DeviceCategory(
      id: 'av',
      name: 'A/V receiver',
      icon: Icons.speaker_group_rounded,
    ),
    const DeviceCategory(
      id: 'dvd',
      name: 'DVD Player',
      icon: Icons.album_rounded,
    ),
    const DeviceCategory(
      id: 'projector',
      name: 'Projector',
      icon: Icons.cast_connected_rounded,
    ),
    const DeviceCategory(
      id: 'sat',
      name: 'Chinese satellite TV',
      icon: Icons.router_rounded,
    ),
    const DeviceCategory(
      id: 'camera',
      name: 'Camera',
      icon: Icons.camera_alt_rounded,
    ),
  ];

  final List<Brand> _brands = [
    const Brand(name: 'Xiaomi', isPopular: true),
    const Brand(name: 'Gree', isPopular: true),
    const Brand(name: 'Midea', isPopular: true),
    const Brand(name: 'Haier', isPopular: true),
    const Brand(name: 'Aux', isPopular: true),
    const Brand(name: 'Chigo', isPopular: true),
    const Brand(name: 'TCL', isPopular: true),
    const Brand(name: 'Hisense', isPopular: true),
    const Brand(name: 'Kelon', isPopular: true),
    const Brand(name: 'Changhong', isPopular: true),
    const Brand(name: 'Galanz', isPopular: true),
    const Brand(name: 'Chunlan', isPopular: true),
    const Brand(name: '3M'),
    const Brand(name: 'ACL'),
    const Brand(name: 'Aidelong'),
    const Brand(name: 'Airwell'),
    const Brand(name: 'Aite'),
    const Brand(name: 'Akira'),
    const Brand(name: 'Altus'),
    const Brand(name: 'Amico'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic title based on app state
    String title = 'IR remote';
    if (_selectedCategoryId != null) {
      final selectedCat = _categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
      title = 'Select ${selectedCat.name}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure AMOLED dark backgrounds
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (_selectedCategoryId != null) {
              setState(() {
                _selectedCategoryId = null; // Step back to category grid
                _searchQuery = "";
                _searchController.clear();
              });
            } else {
              // Standard route pop for exit
            }
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _selectedCategoryId == null
            ? _buildCategoryGrid()
            : _buildBrandSelectionSection(),
      ),
    );
  }

  // --- VIEW 1: THE DEVICE TYPE GRID ---
  Widget _buildCategoryGrid() {
    return GridView.builder(
      key: const ValueKey('CategoryGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4, // Matches wide tiles from screenshot 1
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Slate dark grey tile
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: const Color(0xFFB3B3B3), size: 36),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- VIEW 2: THE BRAND BRAND DISCOVERY SCREEN ---
  Widget _buildBrandSelectionSection() {
    // Dynamic filter logic based on the user's active keystrokes
    final searchFiltered = _brands
        .where((b) => b.name.toLowerCase().contains(_searchQuery))
        .toList();
    final popularBrands = searchFiltered.where((b) => b.isPopular).toList();
    final allBrands = searchFiltered.where((b) => !b.isPopular).toList();

    return Column(
      key: const ValueKey('BrandSection'),
      children: [
        // Search Input Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.grey,
            decoration: InputDecoration(
              hintText: 'Search brands',
              hintStyle: const TextStyle(color: Color(0), fontSize: 16),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              if (popularBrands.isNotEmpty) ...[
                const Text(
                  'Popular brands',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: popularBrands.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio:
                        2.2, // Clean aspect ratio for rounded capsules
                  ),
                  itemBuilder: (context, idx) {
                    return _buildBrandCapsule(popularBrands[idx].name);
                  },
                ),
                const SizedBox(height: 24),
              ],

              if (allBrands.isNotEmpty) ...[
                const Text(
                  'All',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allBrands.length,
                  itemBuilder: (context, idx) {
                    return _buildBrandListTile(allBrands[idx].name);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- BRAND COMPONENT MINI-BUILDERS ---

  Widget _buildBrandCapsule(String name) {
    return GestureDetector(
      onTap: () => _handleBrandTap(name),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          name,
          style: const TextStyle(
            color: Color(0xFFEFEFEF),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBrandListTile(String name) {
    return InkWell(
      onTap: () => _handleBrandTap(name),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          name,
          style: const TextStyle(
            color: Color(0xFFDDDDDD),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _handleBrandTap(String brandName) {
    HapticFeedback.lightImpact();
    // Route execution down to firmware setup step
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Text(
          'Connecting to $brandName hardware system...',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
