import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showNotFound = false;
  String _currentQuery = '';

  
  final List<String> _trendingSearches = [
    'Biriyani', 'Pizza', 'Burger', 'Chicken Fried Rice', 'Dosa'
  ];

  final List<String> _recentSearches = [
    'Egg Rolls', 'Arroz con Pollo', 'Margherita Pizza'
  ];

  final List<Map<String, String>> _categories = [
    {
      'name': 'Biriyani',
      'image': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=400&q=80'
    },
    {
      'name': 'Pizza',
      'image': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80'
    },
    {
      'name': 'Burger',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80'
    },
    {
      'name': 'Chicken Fried Rice',
      'image': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=400&q=80'
    },
    {
      'name': 'Dosa',
      'image': 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=400&q=80'
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _currentQuery = query;
      if (query.isEmpty) {
        _showNotFound = false;
      } else {
        // Combined list of searchable items
        final allItems = [
          ..._trendingSearches.map((s) => s.toLowerCase()),
          ..._recentSearches.map((s) => s.toLowerCase()),
          ..._categories.map((c) => c['name']!.toLowerCase()),
        ];
        
        _showNotFound = !allItems.any((item) => item.contains(query));
      }
    });
  }

  void _onItemTap(String name) {
    _searchController.text = name;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    final chipHintColor = isDark ? Colors.white24 : Colors.black26;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Search Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: iconColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        cursorColor: const Color(0xFFFA5211),
                        style: GoogleFonts.outfit(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Restaurant name or a dish...',
                          hintStyle: GoogleFonts.outfit(color: hintColor, fontSize: 16),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _showNotFound 
                ? _buildNotFoundView(surfaceColor, textColor, hintColor)
                : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trending Searches
                    _buildSectionHeader('TRENDING SEARCHES', hintColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _trendingSearches.map((tag) => _buildChip(tag, surfaceColor, borderColor, hintColor, iconColor, isTrending: true)).toList(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Recent Searches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader('YOUR RECENT SEARCHES', hintColor),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: TextButton(
                            onPressed: () => setState(() => _recentSearches.clear()),
                            child: Text(
                              'Clear',
                              style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_recentSearches.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _recentSearches.map((tag) => _buildChip(tag, surfaceColor, borderColor, hintColor, iconColor)).toList(),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'No recent searches',
                          style: GoogleFonts.outfit(color: chipHintColor, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 40),

                    // What's on your mind?
                    _buildSectionHeader('WHAT\'S ON YOUR MIND?', hintColor),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () => _onItemTap(category['name']!),
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E1E1E),
                                  image: DecorationImage(
                                    image: NetworkImage(category['image']!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category['name']!,
                                style: GoogleFonts.outfit(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: hintColor,
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color surfaceColor, Color borderColor, Color hintColor, Color iconColor, {bool isTrending = false}) {
    return GestureDetector(
      onTap: () => _onItemTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTrending ? Icons.trending_up : Icons.history,
              color: hintColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(color: iconColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundView(Color surfaceColor, Color textColor, Color hintColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 60, color: const Color(0xFFFA5211).withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'Item Not Found',
            style: GoogleFonts.outfit(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'We couldn\'t find any match for "$_currentQuery". Try searching for Biriyani or Pizza!',
              style: GoogleFonts.outfit(color: hintColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          TextButton(
            onPressed: () => _searchController.clear(),
            child: Text(
              'Clear Search',
              style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
