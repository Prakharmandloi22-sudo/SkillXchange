import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../core/performance_utils.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _bioController;
  late final TextEditingController _nameController;

  late List<String> _teachSkills;
  late List<String> _learnSkills;

  String _experienceLevel = 'Intermediate';
  String _preferredMethod = 'Remote';
  bool _isLoading = false;
  String? _selectedAvatar;

  final List<String> _allSkills = [
    'Flutter', 'React', 'Python', 'UI Design', 'Figma', 'Marketing',
    'Public Speaking', 'Guitar', 'Cooking', 'Yoga', 'Machine Learning',
    'SQL', 'Dart', 'Node.js', 'Go', 'AWS', 'Photoshop', 'Video Editing',
    'Excel', 'Leadership', 'Java', 'Swift',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.user.bio);
    _nameController = TextEditingController(text: widget.user.name);
    _teachSkills = List.from(widget.user.teachSkills);
    _learnSkills = List.from(widget.user.learnSkills);
    _experienceLevel = (widget.user.preferences['experienceLevel'] as String?) ?? 'Intermediate';
    _preferredMethod = (widget.user.preferences['preferredMethod'] as String?) ?? 'Remote';
    _selectedAvatar = widget.user.profileImage;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddCustomSkillDialog(bool isTeaching) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            isTeaching ? 'Add Teaching Skill' : 'Add Learning Skill',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter skill name...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ADD SKILL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ),
          ],
        ),
    );
  }

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
        
        setState(() => _selectedAvatar = url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded to Cloudinary!'), backgroundColor: AppColors.accent),
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 32),
              Text(
                'UPDATE PHOTO',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _photoOption(
                      icon: Icons.palette_rounded,
                      label: 'AVATARS',
                      onTap: () {
                        Navigator.pop(context);
                        _showAvatarSelector();
                      },
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _photoOption(
                      icon: Icons.photo_library_rounded,
                      label: 'GALLERY',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      color: AppColors.neonMagenta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOption({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }


  void _showAvatarSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CHOOSE YOUR AVATAR',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                  ),
                  itemCount: AppColors.avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = AppColors.avatars[index];
                    final isSelected = _selectedAvatar == avatar;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatar = avatar);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: 300.ms,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              spreadRadius: 4,
                            ),
                          ] : null,
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.cardBackground,
                          backgroundImage: CachedNetworkImageProvider(PerformanceUtils.optimizeCloudinaryUrl(avatar, width: 200)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.completeOnboarding(
        uid: widget.user.id,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        teachSkills: _teachSkills,
        learnSkills: _learnSkills,
        profileImage: _selectedAvatar,
        preferences: {
          'experienceLevel': _experienceLevel,
          'preferredMethod': _preferredMethod,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: AppColors.accent),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                expandedHeight: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'EDIT PROFILE',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
                ),
                actions: [
                  if (!_isLoading)
                    TextButton(
                      onPressed: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), spreadRadius: 1)
                          ],
                        ),
                        child: Text(
                          'SAVE',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                        ),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 48),
                      _sectionLabel('IDENTITY'),
                      const SizedBox(height: 16),
                      _inputField(_nameController, 'Full Name', Icons.person_rounded),
                      const SizedBox(height: 24),
                      _sectionLabel('BIO'),
                      const SizedBox(height: 16),
                      _inputField(_bioController, 'Describe your expertise...', Icons.notes_rounded, maxLines: 3),
                      const SizedBox(height: 48),
                      _sectionHeader('PROFICIENCY', AppColors.accent),
                      const SizedBox(height: 20),
                      _skillSelector(_allSkills, _teachSkills, AppColors.accent, isTeaching: true),
                      const SizedBox(height: 40),
                      _sectionHeader('CURIOSITY', AppColors.neonCyan),
                      const SizedBox(height: 20),
                      _skillSelector(_allSkills, _learnSkills, AppColors.neonCyan, isTeaching: false),
                      const SizedBox(height: 48),
                      _sectionLabel('PREFERENCES'),
                      const SizedBox(height: 20),
                      _dropdownField('Experience level', ['Beginner', 'Intermediate', 'Expert'], _experienceLevel, (v) => setState(() => _experienceLevel = v!)),
                      const SizedBox(height: 20),
                      _dropdownField('Interaction mode', ['Remote', 'In-Person', 'Hybrid'], _preferredMethod, (v) => setState(() => _preferredMethod = v!)),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 3),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: (_selectedAvatar != null && _selectedAvatar!.isNotEmpty)
                    ? PerformanceUtils.buildOptimizedImage(_selectedAvatar!, targetWidth: 300)
                    : Container(
                        color: AppColors.cardBackground,
                        child: const Icon(Icons.person_rounded, size: 60, color: Colors.white24),
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.palette_rounded, size: 20, color: Colors.black),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.accent.withValues(alpha: 0.5), size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      ),
    );
  }

  Widget _skillSelector(List<String> skills, List<String> selected, Color color, {required bool isTeaching}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...skills.map((s) {
          final isSelected = selected.contains(s);
          return GestureDetector(
            onTap: () => setState(() => isSelected ? selected.remove(s) : selected.add(s)),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                s,
                style: GoogleFonts.outfit(color: isSelected ? Colors.black : Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showAddCustomSkillDialog(isTeaching),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), style: BorderStyle.none),
            ),
            child: Text('+ CUSTOM', style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, List<String> items, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.background,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}


