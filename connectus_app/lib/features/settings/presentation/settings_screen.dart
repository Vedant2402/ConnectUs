import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final displayNameController = TextEditingController();
  final bioController = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingAvatar = false;
  String username = '';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('username, display_name, bio, avatar_url')
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        username = profile['username']?.toString() ?? '';
        displayNameController.text = profile['display_name']?.toString() ?? '';
        bioController.text = profile['bio']?.toString() ?? '';
        avatarUrl = profile['avatar_url']?.toString();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load your profile: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> chooseAvatar() async {
    if (isUploadingAvatar) return;

    final selectedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (selectedImage == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => isUploadingAvatar = true);
    try {
      final bytes = await selectedImage.readAsBytes();
      final extension = _safeImageExtension(selectedImage.name);
      final path = '$userId/profile.$extension';
      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              cacheControl: '3600',
              contentType: contentType,
            ),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);
      final refreshedUrl =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': refreshedUrl})
          .eq('id', userId);

      if (!mounted) return;
      setState(() => avatarUrl = refreshedUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to upload your photo: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isUploadingAvatar = false);
    }
  }

  String _safeImageExtension(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp') return extension;
    return 'jpg';
  }

  String get profileInitial {
    final displayName = displayNameController.text.trim();
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    if (username.isNotEmpty) return username[0].toUpperCase();
    return '?';
  }

  Future<void> saveProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final displayName = displayNameController.text.trim();
    if (userId == null || displayName.isEmpty || isSaving) return;

    setState(() => isSaving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': displayName,
            'bio': bioController.text.trim(),
          })
          .eq('id', userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save your profile: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: InkWell(
                            onTap: isUploadingAvatar ? null : chooseAvatar,
                            borderRadius: BorderRadius.circular(54),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  backgroundImage:
                                      avatarUrl != null && avatarUrl!.isNotEmpty
                                      ? NetworkImage(avatarUrl!)
                                      : null,
                                  child: avatarUrl == null || avatarUrl!.isEmpty
                                      ? Text(
                                          profileInitial,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: -3,
                                  bottom: -3,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    child: isUploadingAvatar
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: isUploadingAvatar ? null : chooseAvatar,
                            child: const Text('Change profile photo'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: displayNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: bioController,
                          maxLength: 160,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : saveProfile,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(isSaving ? 'Saving…' : 'Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppThemeController.mode,
                      builder: (context, mode, _) {
                        return SwitchListTile(
                          secondary: Icon(
                            mode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                          ),
                          title: const Text('Dark mode'),
                          subtitle: const Text('Light mode is the default'),
                          value: mode == ThemeMode.dark,
                          onChanged: AppThemeController.setDark,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Account security'),
                      subtitle: Text(
                        Supabase.instance.client.auth.currentUser?.email ?? '',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
