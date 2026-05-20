import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/hardware_database.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? _selectedCategoryId;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = 'IR remote';
    if (_selectedCategoryId != null) {
      final selectedCat = HardwareDatabase.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
      );
      title = 'Select ${selectedCat.name}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
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

  Widget _buildCategoryGrid() {
    return GridView.builder(
      key: const ValueKey('CategoryGrid'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: HardwareDatabase.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final category = HardwareDatabase.categories[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: const Color(0xFFB3B3B3), size: 36),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandSelectionSection() {
    final activeBrands = HardwareDatabase.getBrandsForCategory(
      _selectedCategoryId!,
    );

    final searchFiltered = activeBrands
        .where((b) => b.name.toLowerCase().contains(_searchQuery))
        .toList();
    final popularBrands = searchFiltered.where((b) => b.isPopular).toList();
    final allBrands = searchFiltered.where((b) => !b.isPopular).toList();

    return Column(
      key: const ValueKey('BrandSection'),
      children: [
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
              hintStyle: const TextStyle(
                color: Color(0xFF8A8A8A),
                fontSize: 16,
              ),
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
                    childAspectRatio: 2.2,
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
          style: const TextStyle(color: Color(0xFFEFEFEF), fontSize: 14),
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
          style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 16),
        ),
      ),
    );
  }

  void _handleBrandTap(String brandName) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Text('Loading setup verification matching for $brandName...'),
      ),
    );
  }
}
