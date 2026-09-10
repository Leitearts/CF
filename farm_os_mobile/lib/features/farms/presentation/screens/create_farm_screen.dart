import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/create_farm_input.dart';
import 'create_farm_controller.dart';

const List<String> _farmTypeOptions = [
  'Mixed Livestock',
  'Pig Farming',
  'Dairy Cattle',
  'Poultry',
  'Crop Farming',
  'Other',
];

/// Shown when an authenticated farmer has zero farms (Sprint 2 section 12).
/// Also reachable later as "Add another farm" from the dashboard -- the form
/// itself doesn't need to know which case it's in.
class CreateFarmScreen extends ConsumerStatefulWidget {
  const CreateFarmScreen({super.key, this.isOnboarding = true});

  final bool isOnboarding;

  @override
  ConsumerState<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends ConsumerState<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _regionController = TextEditingController();
  final _countryController = TextEditingController();
  final _registrationNoController = TextEditingController();
  final _customFarmTypeController = TextEditingController();
  String? _selectedFarmType;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    _registrationNoController.dispose();
    _customFarmTypeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final farmType = _selectedFarmType == 'Other'
        ? _customFarmTypeController.text.trim()
        : _selectedFarmType;

    ref.read(createFarmControllerProvider.notifier).submit(
          CreateFarmInput(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            location:
                _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
            country:
                _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
            farmType: (farmType == null || farmType.isEmpty) ? null : farmType,
            registrationNo: _registrationNoController.text.trim().isEmpty
                ? null
                : _registrationNoController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormSubmissionState>(createFarmControllerProvider, (previous, next) {
      if (next is FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure.message)),
        );
      }
      // On FormSuccess, farmsControllerProvider's state flips to FarmsLoaded
      // with the new farm active; router redirect logic (app_router.dart)
      // does NOT auto-navigate away from this route by design (so it also
      // works as an "add another farm" screen later), so we navigate
      // explicitly here.
      if (next is FormSuccess) {
        context.go('/dashboard');
      }
    });

    final formState = ref.watch(createFarmControllerProvider);
    final isSubmitting = formState is FormSubmitting;

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(title: const Text('Add Farm')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (widget.isOnboarding) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text("Let's set up your farm", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Just the basics for now -- you can add more detail later.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                AppTextField(
                  label: 'Farm name',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, fieldLabel: 'Farm name'),
                  prefixIcon: Icons.agriculture_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Farm type'),
                  value: _selectedFarmType,
                  items: _farmTypeOptions
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFarmType = value),
                ),
                if (_selectedFarmType == 'Other') ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Describe your farm type',
                    controller: _customFarmTypeController,
                    textInputAction: TextInputAction.next,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Phone (optional)',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email (optional)',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.alternate_email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Location (optional)',
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Region (optional)',
                  controller: _regionController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Country (optional)',
                  controller: _countryController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Registration number (optional)',
                  controller: _registrationNoController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: widget.isOnboarding ? 'Create Farm' : 'Save Farm',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
