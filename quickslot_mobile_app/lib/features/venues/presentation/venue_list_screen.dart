import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/venues_notifier.dart';
import '../domain/venue.dart';
import '../../../core/theme/app_theme.dart';

class VenueListScreen extends ConsumerStatefulWidget {
  const VenueListScreen({super.key});

  @override
  ConsumerState<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends ConsumerState<VenueListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Badminton',
    'Football',
    'Tennis',
    'Basketball',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final venuesAsync = ref.watch(venuesNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'QUICKSLOT',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppTheme.borderColor, height: 1.0, thickness: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.accentColor),
            tooltip: 'My Bookings',
            onPressed: () => context.push('/bookings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Greeting
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentColor.withOpacity(0.12),
                  child: const Icon(Icons.person_rounded, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor),
                    ),
                    Text(
                      (authState.currentUserId ?? 'Guest').toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search venues, location...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondaryTextColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : const Icon(Icons.tune_rounded, color: AppTheme.accentColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
                ),
              ),
            ),
          ),

          // Horizontal Categories Timeline
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppTheme.accentColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppTheme.borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 8.0),
            child: Text(
              'Explore Venues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
                color: AppTheme.textColor,
              ),
            ),
          ),

          // Venue List content
          Expanded(
            child: venuesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load venues',
                        style: TextStyle(fontSize: 18, color: AppTheme.textColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppTheme.secondaryTextColor),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(venuesNotifierProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (venues) {
                // Apply search and category filtering
                final filtered = venues.where((venue) {
                  final matchesSearch = venue.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      venue.location.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' ||
                      venue.sport.toLowerCase() == _selectedCategory.toLowerCase();
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: AppTheme.secondaryTextColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No venues match your criteria',
                          style: TextStyle(fontSize: 16, color: AppTheme.textColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final venue = filtered[index];
                    return _VenueCard(venue: venue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/venues/${venue.id}'),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Styled Image / Icon container
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  image: venue.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(venue.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: venue.imageUrl.isEmpty
                    ? const Icon(
                        Icons.sports_rounded,
                        size: 32,
                        color: AppTheme.accentColor,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Venue Text Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sport category label
                    Text(
                      venue.sport.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.secondaryTextColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.location,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
