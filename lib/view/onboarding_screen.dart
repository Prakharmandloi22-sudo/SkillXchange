import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/theme.dart';
import '../core/performance_utils.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _bioController = TextEditingController();
  final List<String> _teachSkills = [];
  final List<String> _learnSkills = [];
  String _experienceLevel = 'Intermediate';
  String _preferredMethod = 'Remote';
  String? _profileImageUrl;

  final List<String> _suggestedSkills = [
    'Flutter', 'React', 'Python', 'UI Design', 'Figma', 'Marketing',
    'Public Speaking', 'Guitar', 'Cooking', 'Yoga', 'Machine Learning',
    'SQL', 'Dart', 'Node.js', 'Go', 'AWS',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _showAddCustomSkillDialog(bool isTeaching) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          isTeaching ? 'Add Teaching Skill' : 'Add Learning Skill',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter skill name...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final skill = controller.text.trim();
              if (skill.isNotEmpty) {
                setState(() {
                  if (isTeaching) {
                    if (!_teachSkills.contains(skill)) _teachSkills.add(skill);
                  } else {
                    if (!_learnSkills.contains(skill)) _learnSkills.add(skill);
                  }
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final cloudinary = ref.read(cloudinaryServiceProvider);
        final url = await cloudinary.uploadProfileImage(File(pickedFile.path));
        
        setState(() => _profileImageUrl = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!'), backgroundColor: AppColors.accent),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _submit() async {
    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an avatar to continue.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_teachSkills.isEmpty || _learnSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill to teach and learn.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authServiceProvider);
      final currentUser = ref.read(authStateProvider).value;

      // Core Fix: Use real UID from Firebase Auth if the provider state is lagging
      final targetUid = currentUser?.id ?? 
                      Supabase.instance.client.auth.currentUser?.id ?? 
                      'error_unauthorized';
      
      if (targetUid == 'error_unauthorized') {
        throw Exception('User authentication lost. Please log in again.');
      }

      await auth.completeOnboarding(
        uid: targetUid,
        bio: _bioController.text,
        teachSkills: _teachSkills,
        learnSkills: _learnSkills,
        preferences: {
          'experienceLevel': _experienceLevel,
          'preferredMethod': _preferredMethod,
        },
        profileImage: _profileImageUrl,
      );
      
      // Force refresh of auth state to trigger UI transition in main.dart
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Premium Mesh Background ─────────────────
          _buildBackgroundblobs(),

          SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) => setState(() => _currentPage = page),
                    children: [
                      _buildPhotoStep(),
                      _buildBioStep(),
                      _buildSkillsStep(isTeaching: true),
                      _buildSkillsStep(isTeaching: false),
                      _buildPreferencesStep(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundblobs() {
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: -50,
          child: _animatedBlob(500, AppColors.deepAurora.withValues(alpha: 0.2)),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _animatedBlob(400, AppColors.accent.withValues(alpha: 0.1)),
        ),
      ],
    );
  }

  Widget _animatedBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 10.seconds)
        .move(begin: Offset.zero, end: const Offset(100, 50), duration: 12.seconds);
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppColors.accent
                    : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          children: [
            Text(
              'CHOOSE YOUR\nIDENTITY',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 0.9,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select an avatar or upload your own photo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            // ── Gallery Upload Option ──────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.1),
                      AppColors.neonMagenta.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload from Gallery',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Show the world the real you',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white10)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR PICK AN AVATAR', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const Expanded(child: Divider(color: Colors.white10)),
              ],
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1,
              ),
              itemCount: AppColors.avatars.length,
              itemBuilder: (context, index) {
                final avatar = AppColors.avatars[index];
                final isSelected = _profileImageUrl == avatar;
                return GestureDetector(
                  onTap: () => setState(() => _profileImageUrl = avatar),
                  child: AnimatedContainer(
                    duration: 300.ms,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 4 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.cardBackground,
                      backgroundImage: CachedNetworkImageProvider(PerformanceUtils.optimizeCloudinaryUrl(avatar, width: 200)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WRITE YOUR\nSTORY',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 0.9,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A great bio increases your chance of finding the perfect swap by 80%.',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 6,
                cursorColor: AppColors.accent,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Share your passion...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardBackground.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideX(begin: 0.1);
  }

  Widget _buildSkillsStep({required bool isTeaching}) {
    final selectedSkills = isTeaching ? _teachSkills : _learnSkills;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTeaching ? 'What can you teach?' : 'What do you want to learn?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for a skill or pick from the list.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._suggestedSkills.map((skill) {
                  final isSelected = selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          selectedSkills.add(skill);
                        } else {
                          selectedSkills.remove(skill);
                        }
                      });
                    },
                    backgroundColor: AppColors.cardBackground,
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.accent,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? AppColors.accent : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.cardBorder,
                    ),
                  );
                }),
                ActionChip(
                  onPressed: () => _showAddCustomSkillDialog(isTeaching),
                  label: const Text('Others +'),
                  labelStyle: GoogleFonts.outfit(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ],
            ),
            if (selectedSkills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED:',
                      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedSkills
                          .map(
                            (s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onDeleted: () => setState(() => selectedSkills.remove(s)),
                              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                              deleteIconColor: AppColors.accent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swap Preferences',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Help us find your perfect match style.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            _buildDropdown(
              'Experience Level',
              ['Beginner', 'Intermediate', 'Expert'],
              _experienceLevel,
              (val) => setState(() => _experienceLevel = val!),
            ),
            const SizedBox(height: 24),
            _buildDropdown(
              'Preferred Method',
              ['Remote', 'In-Person', 'Hybrid'],
              _preferredMethod,
              (val) => setState(() => _preferredMethod = val!),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.cardBackground,
            style: GoogleFonts.outfit(color: Colors.white),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: Text(
                'Back',
                style: GoogleFonts.outfit(color: AppColors.textMuted),
              ),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentPage == 4 ? 'Finish' : 'Next',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
