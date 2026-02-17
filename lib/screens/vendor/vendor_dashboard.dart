import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/app_logo.dart';
import 'add_menu_item_page.dart';
import 'view_menu_page.dart';
import 'orders_history_page.dart';
import 'vendor_order_details_page.dart';
import 'vendor_profile_page.dart';
import 'todays_menu_page.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notifications = [];
  bool _profileIncomplete = false;

  int _lastOrderCount = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
    _setupOrderNotificationListener();
  }

  void _setupOrderNotificationListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: uid)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snapshot) {
      if (_isFirstLoad) {
        _lastOrderCount = snapshot.docs.length;
        _isFirstLoad = false;
        return;
      }

      if (snapshot.docs.length > _lastOrderCount) {
        // New order arrived!
        _showNewOrderNotification();
      }
      _lastOrderCount = snapshot.docs.length;
    });
  }

  void _showNewOrderNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New Order Received!',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFA5211),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('vendors').doc(user.uid).get();
      final menuSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(user.uid)
          .collection('menu')
          .limit(1)
          .get();

      if (doc.exists) {
        final data = doc.data();
        List<Map<String, dynamic>> newNotifications = [];
        List<String> missingFields = [];

        final requiredFields = {
          'name': 'Owner Name',
          'businessName': 'Business Name',
          'businessCategory': 'Category',
          'address': 'Address',
          'phone': 'Phone',
          'bankAccount': 'Bank Details',
          'upiId': 'UPI ID',
          'fssai': 'FSSAI License',
          'businessImage': 'Business Image',
          'profileImage': 'Profile Image',
        };

        requiredFields.forEach((key, label) {
          if (data?[key] == null || data![key].toString().trim().isEmpty) {
            missingFields.add(label);
          }
        });

        bool missingMenu = menuSnapshot.docs.isEmpty;
        
        if (missingFields.isNotEmpty) {
          String fieldsText = missingFields.take(3).join(', ');
          if (missingFields.length > 3) fieldsText += ' and ${missingFields.length - 3} more';
          
          newNotifications.add({
            'id': 'profile_incomplete',
            'message': "Missing: $fieldsText. Complete your profile to improve visibility.",
            'isRead': false,
            'type': 'profile',
            'missingCount': missingFields.length,
            'allMissingFields': missingFields,
          });
        }

        if (missingMenu) {
          newNotifications.add({
            'id': 'menu_empty',
            'message': "Your menu is empty! Add items to start receiving orders.",
            'isRead': false,
            'type': 'menu',
          });
        }
        
        if (mounted) {
          setState(() {
            _profileIncomplete = missingFields.isNotEmpty || missingMenu;
            _notifications = newNotifications;
          });
          
          bool criticalMissing = data?['address'] == null || data?['businessImage'] == null || data?['businessName'] == null;
          if (criticalMissing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showWelcomeDialog();
            });
          }
        }
      }
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Welcome, Partner! 🎉', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Thank you for joining iCuisine.\n\nTo get started, please go to your Profile and update:\n- Business Address\n- Business Image\n- Opening Hours\n\nThis helps customers find you easily!',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VendorProfilePage()),
              );
            },
            child: Text('Go to Profile', style: GoogleFonts.outfit(color: const Color(0xFFFA5211))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'Notifications',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var note in _notifications) {
                            note['isRead'] = true;
                          }
                        });
                        setModalState(() {});
                      },
                      child: Text('Mark all as read', style: GoogleFonts.outfit(color: const Color(0xFFFA5211))),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_notifications.isEmpty)
                 Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white24),
                        const SizedBox(height: 15),
                        Text('No new notifications', style: GoogleFonts.outfit(color: Colors.white38)),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white10, height: 24),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      bool isRead = item['isRead'] ?? false;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white.withOpacity(0.05) : const Color(0xFFFA5211).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['type'] == 'profile' ? Icons.person_outline : Icons.restaurant_menu_outlined,
                            color: isRead ? Colors.white38 : const Color(0xFFFA5211),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['message'],
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            color: isRead ? Colors.white54 : Colors.white,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            item['isRead'] = true;
                          });
                          
                          if (item['type'] == 'profile') {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const VendorProfilePage()),
                            ).then((_) => _checkProfileStatus());
                          } else if (item['type'] == 'menu') {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ViewMenuPage()),
                            ).then((_) => _checkProfileStatus());
                          }
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                          onPressed: () {
                            setState(() {
                              _notifications.removeAt(index);
                            });
                            setModalState(() {});
                            if (_notifications.isEmpty) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await _checkProfileStatus(),
          color: const Color(0xFFFA5211),
          backgroundColor: const Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header (Same as Customer Dashboard)
                _buildTopHeader(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Warning
                      if (_profileIncomplete) _buildProfileWarning(),
                      
                      const SizedBox(height: 15),
                      _buildLiveStatusCard(FirebaseAuth.instance.currentUser?.uid),

                      const SizedBox(height: 25),
                      
                      // Dashboard Heading & Action Menu
                      _buildDashboardTitleAction(),

                      const SizedBox(height: 30),

                      // Today's Orders Section
                      _buildSectionHeader('Orders Management', 'View History', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersHistoryPage()));
                      }),
                      
                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .where('vendorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                             return const Center(child: CircularProgressIndicator(color: Color(0xFFFA5211)));
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text('Error: ${snapshot.error}', 
                                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          
                          final allOrders = snapshot.data?.docs ?? [];
                          // Sort manually in Flutter to avoid needing a composite index in Firestore
                          final sortedOrders = List<QueryDocumentSnapshot>.from(allOrders);
                          sortedOrders.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime == null || bTime == null) return 0;
                            return bTime.compareTo(aTime);
                          });

                          final incompleteOrders = sortedOrders.where((doc) {
                            final status = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
                            return status != 'delivered' && status != 'cancelled';
                          }).toList();
                          
                          final completedOrders = sortedOrders.where((doc) {
                            final status = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
                            return status == 'delivered' || status == 'cancelled';
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Incomplete Orders
                              _buildSubSectionTitle('Incomplete Orders (${incompleteOrders.length})'),
                              const SizedBox(height: 15),
                              incompleteOrders.isEmpty 
                                ? _buildNoOrdersPlaceholder('No active orders')
                                : _buildOrderList(incompleteOrders),

                              const SizedBox(height: 30),

                              // Completed Orders
                              _buildSectionHeader('Recently Completed', 'View All', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OrdersHistoryPage()),
                                );
                              }),
                              const SizedBox(height: 15),
                              completedOrders.isEmpty
                                ? _buildNoOrdersPlaceholder('No recent history')
                                : _buildOrderList(completedOrders.take(5).toList()),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoOrdersPlaceholder(String text) {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(30),
       decoration: BoxDecoration(
         color: const Color(0xFF1E1E1E),
         borderRadius: BorderRadius.circular(25),
         border: Border.all(color: Colors.white10),
       ),
       child: Column(
         children: [
           const Icon(Icons.receipt_long_outlined, color: Colors.white10, size: 40),
           const SizedBox(height: 10),
           Text(text, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13)),
         ],
       ),
     );
  }


  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const AppLogo(size: 40, showBackground: false),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ICuisine',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(context, Icons.notifications_none, 
                badge: _notifications.isEmpty ? null : _notifications.length.toString(),
                onTap: _showNotifications),
              const SizedBox(width: 12),
              _buildPopupMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(BuildContext context, IconData icon, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: Color(0xFFFA5211), shape: BoxShape.circle),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 22),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await _authService.signOut();
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (value == 'history') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersHistoryPage()));
        } else if (value == 'profile') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorProfilePage())).then((_) => _checkProfileStatus());
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('profile', Icons.person_outline, 'Profile'),
        _buildPopupItem('history', Icons.history, 'Order History'),
        const PopupMenuDivider(height: 1),
        _buildPopupItem('logout', Icons.logout, 'Logout', color: Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.outfit(color: color ?? Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfileWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFA5211).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFA5211).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFA5211)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Incomplete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  _notifications.isNotEmpty ? _notifications.first['message'] : 'Update your details to start selling.',
                  style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const VendorProfilePage())).then((_) => _checkProfileStatus());
            },
            child: Text('Resolve', style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTitleAction() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFA5211), shape: BoxShape.circle),
            child: SvgPicture.asset('images/list-icon.svg', colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), height: 20),
          ),
          onSelected: (value) {
            if (value == 'add') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMenuItemPage())).then((_) => _checkProfileStatus());
            } else if (value == 'view') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewMenuPage())).then((_) => _checkProfileStatus());
            } else if (value == 'today') {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TodaysMenuPage())).then((_) => _checkProfileStatus());
            }
          },
          itemBuilder: (context) => [
            _buildPopupItem('add', Icons.add_circle_outline, 'Add Menu'),
            _buildPopupItem('view', Icons.restaurant_menu, 'View Menu'),
            _buildPopupItem('today', Icons.star_outline, 'Today\'s Menu'),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onTap,
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

  Widget _buildSubSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w600));
  }

  Widget _buildOrderList(List<QueryDocumentSnapshot> orderDocs) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: orderDocs.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final order = doc.data() as Map<String, dynamic>;
          
          final String status = order['status'] ?? 'Pending';
          final Color statusColor = _getStatusColor(status);
          final List items = order['items'] ?? [];
          final String itemsSummary = '${order['customerName'] ?? 'Customer'} • ${items.length} items';

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.shopping_bag_outlined, color: statusColor, size: 22),
                ),
                title: Text('Order #${doc.id.substring(0, 6).toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(itemsSummary, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change',
                      style: GoogleFonts.outfit(color: const Color(0xFFFA5211), fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                onTap: () {
                  final s = status.toLowerCase();
                  if (s == 'delivered' || s == 'cancelled') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorOrderDetailsPage(orderId: doc.id),
                      ),
                    );
                  } else {
                    _showStatusUpdateOptions(doc.id, status);
                  }
                },
              ),
              if (index < orderDocs.length - 1) Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 20, endIndent: 20),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showStatusUpdateOptions(String orderId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Order Status',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Order ID: #${orderId.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 25),
              _buildStatusOption(orderId, 'View Full Details',
                  Icons.visibility_outlined, Colors.white70, isDetails: true),
              const Divider(color: Colors.white10, height: 30),
              if (currentStatus == 'Pending')
                _buildStatusOption(orderId, 'Received',
                    Icons.check_circle_outline, Colors.orange),
              if (currentStatus == 'Received')
                _buildStatusOption(
                    orderId, 'Cooking', Icons.restaurant, Colors.blue),
              if (currentStatus == 'Cooking')
                _buildStatusOption(
                    orderId, 'Ready', Icons.done_all, Colors.purple),
              if (currentStatus == 'Ready')
                _buildStatusOption(
                    orderId, 'Delivered', Icons.delivery_dining, Colors.green),
              if (currentStatus != 'Delivered' && currentStatus != 'Cancelled')
                _buildStatusOption(
                    orderId, 'Cancelled', Icons.cancel_outlined, Colors.red),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(
      String orderId, String status, IconData icon, Color color, {bool isDetails = false}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w600)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
      onTap: () async {
        Navigator.pop(context);
        
        if (isDetails) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorOrderDetailsPage(orderId: orderId),
            ),
          );
          return;
        }

        if (status == 'Cancelled') {
          _showCancellationDialog(orderId);
          return;
        }

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': status,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Order Status Updated: $status'),
                backgroundColor: color.withOpacity(0.8)),
          );
        }
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'received': return Colors.orangeAccent;
      case 'cooking': return Colors.blue;
      case 'ready': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.white54;
    }
  }

  void _showCancellationDialog(String orderId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Cancel Order', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for cancellation:', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Out of stock, Shop closed',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Back', style: GoogleFonts.outfit(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                'status': 'Cancelled',
                'cancellationReason': reason,
              });
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order Cancelled'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm Cancellation', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  Widget _buildLiveStatusCard(String? uid) {
    if (uid == null) return const SizedBox.shrink();
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isLive = data['hasLiveItems'] == true;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLive ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLive ? Icons.check_circle : Icons.offline_bolt_outlined,
                  color: isLive ? Colors.greenAccent : Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLive ? 'You are LIVE' : 'You are OFFLINE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isLive 
                        ? 'Customers can see your menu and place orders.' 
                        : 'Tap "Go Live" to select items and start selling.',
                      style: GoogleFonts.outfit(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TodaysMenuPage()),
                  ).then((_) => _checkProfileStatus());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive ? Colors.white10 : const Color(0xFFFA5211),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isLive ? 'Manage' : 'Go Live',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
