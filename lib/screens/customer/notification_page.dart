import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_outlined, size: 80, color: Colors.white10),
                  const SizedBox(height: 20),
                  Text(
                    'All clear!',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have no new notifications.',
                    style: GoogleFonts.outfit(color: Colors.white38),
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
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
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
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  note['time']!,
                                  style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              note['message']!,
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, height: 1.4),
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
