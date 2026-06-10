import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_notifier.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              fontFamily: 'Manrope',
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your session?',
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontFamily: 'Inter',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authNotifierProvider.notifier).logout();
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final String username = authState.currentUserId ?? 'Guest';
    final String email = username;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: AppTheme.borderColor,
            height: 1.0,
            thickness: 1.0,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: AppTheme.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutConfirmation(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
