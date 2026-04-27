import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/widgets/gradient_button.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  _StaffProfileScreenState createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'Staff';
  bool _isLoading = false;

  final List<String> _roles = ['Admin', 'Doctor', 'Nurse', 'Security', 'Manager', 'Staff'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user?.email != null) {
      final name = user!.email!.split('@')[0];
      _nameController.text = name;
      if (name.toLowerCase().contains('admin')) {
        _selectedRole = 'Admin';
      }
    }
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      
      final staff = StaffModel(
        id: auth.currentUser!.uid,
        name: _nameController.text.trim(),
        email: auth.currentUser!.email!,
        role: _selectedRole,
        status: 'available',
        lastSeen: DateTime.now(),
        phone: _phoneController.text.trim(),
      );

      await firestore.saveStaffProfile(staff);
      
      if (mounted) {
        context.go('/command_dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complete Your Profile", style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text("Full Name", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "Enter your full name",
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Text("Your Role", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((role) {
                final isSelected = _selectedRole == role;
                return ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = role);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text("Contact Number", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Enter your phone number",
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.phone, size: 20, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 48),
            GradientButton(
              text: "Finish Setup",
              isLoading: _isLoading,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
