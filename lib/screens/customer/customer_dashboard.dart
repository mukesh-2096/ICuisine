import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'customer_profile_page.dart';
import 'notification_page.dart';
import 'search_page.dart';
import 'manage_addresses_page.dart';
import 'cart_page.dart';
import 'customer_vendor_menu_page.dart';
import 'my_orders_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  late PageController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  final List<Widget> _pages = [
    const ExplorePage(),
    const SearchPage(),
    const CartPage(),
    const CustomerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          PageView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildActiveOrderPin(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _tabController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFFFA5211),
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildActiveOrderPin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter and sort in Dart to avoid index issues
        final activeOrders = snapshot.data!.docs.where((doc) {
          final status = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
          return status != 'delivered' && status != 'cancelled';
        }).toList();

        if (activeOrders.isEmpty) return const SizedBox.shrink();

        activeOrders.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        final orderDoc = activeOrders.first;
        final order = orderDoc.data() as Map<String, dynamic>;
        final String status = order['status'] ?? 'Pending';
        final String vendorName = order['vendorName'] ?? 'Vendor';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyOrdersPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFA5211).withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA5211).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant,
                      color: Color(0xFFFA5211), size: 18),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track Order from $vendorName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFA5211),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFA5211),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFA5211),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VIEW',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _isVegOnly = false;
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Welcome!',
      'message': 'What\'s your craving today? Explore hundreds of delicious dishes near you.',
      'icon': Icons.local_fire_department,
      'color': const Color(0xFFFA5211),
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'New Offer! 🎉',
      'message': 'Get 20% off on your first order from Royal Kitchen.',
      'icon': Icons.local_offer_outlined,
      'color': Colors.blue,
      'isRead': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < 4) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleRefresh() async {
    // Simulate a network delay or data refresh
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // You can re-fetch data here if needed, 
        // though StreamBuilder handles most real-time updates.
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? FirebaseFirestore.instance.collection('customers').doc(user.uid).snapshots()
              : null,
          builder: (context, snapshot) {
            final userName = (snapshot.hasData && snapshot.data!.data() != null)
                ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'User'
                : 'User';

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFFFA5211),
              backgroundColor: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingWithAvatar(context, userName),
                        const SizedBox(height: 10),
                        
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('customers')
                              .doc(user!.uid)
                              .collection('addresses')
                              .where('isDefault', isEqualTo: true)
                              .snapshots(),
                          builder: (context, addressSnapshot) {
                            String addressText = 'Add address';
                            if (addressSnapshot.hasData && addressSnapshot.data!.docs.isNotEmpty) {
                              final addressData = addressSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                              addressText = '${addressData['label']}: ${addressData['address']}';
                            }
                            
                            return GestureDetector(
                              onTap: () => _animatedNav(context, const ManageAddressesPage()),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFFFA5211), size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      addressText,
                                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 14),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 25),
                        
                        // Search Bar + Small Veg Toggle
                        Row(
                          children: [
                            Expanded(child: _buildSearchBar()),
                            const SizedBox(width: 15),
                            _buildVegToggle(),
                          ],
                        ),
                        const SizedBox(height: 25),

                        _buildSectionHeader('Categories', null),
                        const SizedBox(height: 15),
                        _buildCategories(),
                        const SizedBox(height: 30),


                        _buildTrendingItems(),
                        const SizedBox(height: 30),

                        _buildSectionHeader('Nearby Vendors', 'View Map'),
                        const SizedBox(height: 15),
                        _buildNearbyVendors(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVegToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isVegOnly ? 'VEG' : 'NON-VEG',
            style: GoogleFonts.outfit(
              color: _isVegOnly ? Colors.green : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _isVegOnly = !_isVegOnly),
            child: Container(
              width: 32,
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                   AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: _isVegOnly ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isVegOnly ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: _isVegOnly ? Colors.green : Colors.red, width: 1.5),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(color: _isVegOnly ? Colors.green : Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildGreetingWithAvatar(BuildContext context, String name) {
    String greeting = 'Good morning';
    int hour = DateTime.now().hour;
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    if (hour >= 17) greeting = 'Good evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$greeting 👋', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
          ],
        ),
        GestureDetector(
          onTap: () => _animatedNav(context, const NotificationPage()),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
              ),
              if (_notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFA5211),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black26, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              readOnly: true,
              onTap: () => _animatedNav(context, const SearchPage()),
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search for \'ICuisine\'',
                hintStyle: GoogleFonts.outfit(color: Colors.black26, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        if (actionText != null)
          TextButton(
            onPressed: () {},
            child: Row(
              children: [
                Text(actionText, style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, color: Color(0xFFFA5211), size: 18),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Main Course', 'icon': '🍳', 'color': Colors.orange},
      {'name': 'Snacks', 'icon': '🍔', 'color': Colors.red},
      {'name': 'Drinks', 'icon': '☕', 'color': Colors.blue},
      {'name': 'Desserts', 'icon': '🍰', 'color': Colors.pink},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            width: 85,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (categories[index]['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    categories[index]['icon'] as String,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  categories[index]['name'] as String,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Today\'s Specials', null),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('menu')
                .where('isTodaySpecial', isEqualTo: true)
                .where('isAvailable', isEqualTo: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // If the error is an index error, it will contain a URL. 
                // We display it so the user can copy-paste it to their browser to create the index.
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText(
                      'This feature requires a Firestore Index.\n\n${snapshot.error}', 
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text('No specials today. Check back later!', style: GoogleFonts.outfit(color: Colors.white38)),
                );
              }

              final items = snapshot.data!.docs;

              return PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  final item = items[index].data() as Map<String, dynamic>;
                  final doc = items[index];
                  // Derive vendor ID from the document reference path
                  // Path structure: vendors/{vendorId}/menu/{menuId}
                  final vendorId = doc.reference.parent.parent!.id;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerVendorMenuPage(vendorId: vendorId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Full Bleed Image Placeholder/Background
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                image: item['image'] != null && item['image'].toString().isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(item['image']),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                                      )
                                    : null,
                              ),
                              child: item['image'] == null || item['image'].toString().isEmpty
                                  ? const Icon(Icons.fastfood, size: 50, color: Colors.white10)
                                  : null,
                            ),
                            
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Unknown',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${item['price'] ?? 0}',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFA5211),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'SPECIAL',
                                          style: GoogleFonts.outfit(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildNearbyVendors() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          // .where('hasLiveItems', isEqualTo: true) // Temporarily disabled for debugging
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading nearby vendors: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
        }

        final vendors = snapshot.data!.docs;
        
        return Column(
          children: [
            if (vendors.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text("No vendors found in database.", style: GoogleFonts.outfit(color: Colors.redAccent)),
                      const SizedBox(height: 8),
                      Text("Collection: 'vendors'", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Showing ${vendors.length} vendors found",
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final vendor = vendors[index].data() as Map<String, dynamic>;
                final vendorId = vendors[index].id;
                final vendorName = vendor['businessName'] ?? 'Unknown Vendor';
                final vendorImage = vendor['businessImage'] ?? '';
                final vendorAddress = vendor['businessAddress'] ?? 'Address not available';
                final isLive = vendor['hasLiveItems'] == true;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => CustomerVendorMenuPage(
                        vendorId: vendorId, 
                        vendorName: vendorName,
                        vendorImage: vendorImage
                      ))
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity, padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                          child: vendorImage.isNotEmpty 
                            ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(vendorImage, fit: BoxFit.cover))
                            : const Icon(Icons.store, color: Colors.blue, size: 30),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendorName, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      vendorAddress,
                                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLive ? "● LIVE" : "○ OFFLINE",
                                  style: GoogleFonts.outfit(
                                    color: isLive ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _animatedNav(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var trailer = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(trailer),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
