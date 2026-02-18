import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;
    final iconColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    // Sample notifications
    final List<Map<String, String>> notifications = [
      {
        'title': 'Welcome to ICuisine!',
        'message': 'What\'s your craving today? Explore hundreds of delicious dishes near you.',
        'time': 'Just now',
        'type': 'system'
      },
      {
        'title': 'New Offer! 🎉',
        'message': 'Get 20% off on your first order from Royal Kitchen.',
        'time': '2 hours ago',
        'type': 'promo'
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 80, color: iconColor),
                  const SizedBox(height: 20),
                  Text(
                    'All clear!',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have no new notifications.',
                    style: GoogleFonts.outfit(color: subtextColor),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final note = notifications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: note['type'] == 'system' 
                              ? const Color(0xFFFA5211).withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          note['type'] == 'system' ? Icons.info_outline : Icons.local_offer_outlined,
                          color: note['type'] == 'system' ? const Color(0xFFFA5211) : Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note['title']!,
                                  style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  note['time']!,
                                  style: GoogleFonts.outfit(color: subtextColor, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              note['message']!,
                              style: GoogleFonts.outfit(color: subtextColor, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
