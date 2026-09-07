import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/farm_input.dart';
import '../../data/models/farm_model.dart';

class FarmFormDialog extends StatefulWidget {
  const FarmFormDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    this.initialFarm,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;
  final FarmModel? initialFarm;
  final Future<void> Function(
    CreateFarmInput createInput,
    UpdateFarmInput updateInput,
  ) onSubmit;

  @override
  State<FarmFormDialog> createState() => _FarmFormDialogState();
}

class _FarmFormDialogState extends State<FarmFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _locationController;
  late final TextEditingController _regionController;
  late final TextEditingController _countryController;
  late final TextEditingController _farmTypeController;
  late final TextEditingController _registrationNoController;

  @override
  void initState() {
    super.initState();
    final farm = widget.initialFarm;
    _nameController = TextEditingController(text: farm?.name ?? '');
    _phoneController = TextEditingController(text: farm?.phone ?? '');
    _emailController = TextEditingController(text: farm?.email ?? '');
    _locationController = TextEditingController(text: farm?.location ?? '');
    _regionController = TextEditingController(text: farm?.region ?? '');
    _countryController = TextEditingController(text: farm?.country ?? '');
    _farmTypeController = TextEditingController(text: farm?.farmType ?? '');
    _registrationNoController = TextEditingController(text: farm?.registrationNo ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    _farmTypeController.dispose();
    _registrationNoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.onSubmit(
      CreateFarmInput(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        location: _locationController.text,
        region: _regionController.text,
        country: _countryController.text,
        farmType: _farmTypeController.text,
        registrationNo: _registrationNoController.text,
      ),
      UpdateFarmInput(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        location: _locationController.text,
        region: _regionController.text,
        country: _countryController.text,
        farmType: _farmTypeController.text,
        registrationNo: _registrationNoController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Farm name',
                  controller: _nameController,
                  validator: (value) => Validators.required(value, fieldLabel: 'Farm name'),
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.agriculture,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Phone (optional)',
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email (optional)',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Location (optional)',
                  controller: _locationController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Region (optional)',
                  controller: _regionController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.map_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Country (optional)',
                  controller: _countryController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.public,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Farm type (optional)',
                  controller: _farmTypeController,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Registration No. (optional)',
                  controller: _registrationNoController,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.badge_outlined,
                  onFieldSubmitted: (_) {
                    _submit();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _submit();
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
