import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme_controller.dart';
import '../../profile/presentation/avatar_crop_screen.dart';

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
  DateTime? usernameChangedAt;

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
          .select(
            'username, display_name, bio, avatar_url, username_changed_at',
          )
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        username = profile['username']?.toString() ?? '';
        displayNameController.text = profile['display_name']?.toString() ?? '';
        bioController.text = profile['bio']?.toString() ?? '';
        avatarUrl = profile['avatar_url']?.toString();
        usernameChangedAt = DateTime.tryParse(
          profile['username_changed_at']?.toString() ?? '',
        )?.toLocal();
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
      final selectedBytes = await selectedImage.readAsBytes();
      if (!mounted) return;

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => AvatarCropScreen(imageData: selectedBytes),
        ),
      );
      if (croppedBytes == null || !mounted) return;

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
            croppedBytes,
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

  Future<void> removeAvatar() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || isUploadingAvatar) return;

    setState(() => isUploadingAvatar = true);
    try {
      final files = await Supabase.instance.client.storage
          .from('avatars')
          .list(path: userId);
      if (files.isNotEmpty) {
        await Supabase.instance.client.storage
            .from('avatars')
            .remove(files.map((file) => '$userId/${file.name}').toList());
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId);

      if (!mounted) return;
      setState(() => avatarUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo removed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to remove your photo: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isUploadingAvatar = false);
    }
  }

  Future<void> showAvatarActions() async {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(hasAvatar ? 'Choose a new photo' : 'Choose photo'),
              subtitle: const Text('Crop and reposition before uploading'),
              onTap: () {
                Navigator.pop(sheetContext);
                chooseAvatar();
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Remove current photo',
                  style: TextStyle(color: Colors.redAccent),
                ),
                subtitle: const Text('Return to your profile initial'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  removeAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  DateTime? get nextUsernameChangeAt {
    final changedAt = usernameChangedAt;
    if (changedAt == null) return null;
    return changedAt.add(const Duration(days: 7));
  }

  bool get canChangeUsername {
    final nextChange = nextUsernameChangeAt;
    return nextChange == null || !DateTime.now().isBefore(nextChange);
  }

  String get usernameCooldownText {
    final nextChange = nextUsernameChangeAt;
    if (nextChange == null || canChangeUsername) {
      return 'You can change your username now.';
    }
    final remaining = nextChange.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    return 'Available again in ${days}d ${hours}h.';
  }

  Future<void> showUsernameEditor() async {
    if (!canChangeUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usernameCooldownText),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = TextEditingController(text: username);
    final formKey = GlobalKey<FormState>();
    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            autocorrect: false,
            maxLength: 24,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              helperText: 'Letters, numbers, and underscores only',
            ),
            validator: (value) {
              final cleaned = value?.trim() ?? '';
              if (cleaned.length < 3) {
                return 'Use at least 3 characters.';
              }
              if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(cleaned)) {
                return 'Only letters, numbers, and underscores are allowed.';
              }
              if (cleaned.toLowerCase() == username.toLowerCase()) {
                return 'Enter a different username.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newUsername == null || !mounted) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'username': newUsername})
          .eq('id', userId);
      if (!mounted) return;
      setState(() {
        username = newUsername;
        usernameChangedAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username updated. You can change it again in 7 days.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      final message = error.code == '23505'
          ? 'That username is already taken.'
          : error.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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

  Widget buildSettingsSection({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    bool highlighted = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final tint = highlighted ? colors.primary : colors.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tint.withValues(alpha: highlighted ? 0.28 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GlassCard(
        useOwnLayer: true,
        padding: padding,
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        settings: LiquidGlassSettings(
          glassColor: tint.withValues(alpha: highlighted ? 0.14 : 0.09),
          blur: 10,
          thickness: 18,
          lightIntensity: 0.65,
          glowIntensity: 0.55,
          shadowElevation: 2,
          platformViewFallbackColor: colors.surfaceContainerHigh,
        ),
        child: child,
      ),
    );
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
                  buildSettingsSection(
                    highlighted: true,
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
                            onTap: isUploadingAvatar ? null : showAvatarActions,
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
                            onPressed: isUploadingAvatar
                                ? null
                                : showAvatarActions,
                            child: Text(
                              avatarUrl == null || avatarUrl!.isEmpty
                                  ? 'Add profile photo'
                                  : 'Change or remove photo',
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            '@$username',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton.icon(
                            onPressed: canChangeUsername
                                ? showUsernameEditor
                                : null,
                            icon: const Icon(Icons.alternate_email_rounded),
                            label: Text(
                              canChangeUsername
                                  ? 'Change username'
                                  : usernameCooldownText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
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
                  buildSettingsSection(
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
                  buildSettingsSection(
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
