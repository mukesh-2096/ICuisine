import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyFavoritesPage extends StatelessWidget {
  const MyFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtextColor = isDark ? Colors.white38 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final iconBackground = isDark ? Colors.white10 : Colors.black12;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF252525) : Colors.grey[200]!;
    final borderColor = isDark ? Colors.white10 : Colors.black12;
    
    // Sample favorites
    final List<Map<String, dynamic>> favorites = [
      {'name': 'Spicy Tacos', 'category': 'Mexican', 'rating': '4.5', 'price': '₹180', 'icon': '🌮'},
      {'name': 'Pav Bhaji', 'category': 'Indian', 'rating': '4.8', 'price': '₹120', 'icon': '🥘'},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('My Favorites', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: iconBackground),
                  const SizedBox(height: 20),
                  Text('No favorites yet', style: GoogleFonts.outfit(color: subtextColor, fontSize: 18)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Text(item['icon'], style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'],
                              style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item['category'], style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['price'], style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(item['rating'], style: TextStyle(color: iconColor, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
