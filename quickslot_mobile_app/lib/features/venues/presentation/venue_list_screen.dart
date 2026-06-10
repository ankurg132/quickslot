import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/venues_notifier.dart';
import 'widgets/venue_card.dart';
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
    final venuesAsync = ref.watch(venuesNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // New Header (racket icon, brand name, user avatar)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_tennis_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'QuickSlot',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE6F3EE),
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200',
                    ),
                  ),
                ],
              ),
            ),

            // Shorter Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search venues, sports, or location',
                    hintStyle: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.secondaryTextColor,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : Container(
                            margin: const EdgeInsets.all(4.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // Soft blue tint
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFF006C49), // AppTheme.primaryColor
                              size: 16,
                            ),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

          // Horizontal Categories Timeline
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : AppTheme.borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                );
              },
            ),
          ),

          // Venue List content
          Expanded(
            child: venuesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 60,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load venues',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(venuesNotifierProvider.notifier).refresh(),
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
                  final matchesSearch =
                      venue.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      venue.location.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                      venue.sport.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: AppTheme.secondaryTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No venues match your criteria',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final venue = filtered[index];
                    return VenueCard(venue: venue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
   );
  }
}
