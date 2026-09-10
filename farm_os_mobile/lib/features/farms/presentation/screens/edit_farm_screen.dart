import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/farms_state.dart';
import '../../data/models/farm_model.dart';
import '../../data/models/update_farm_input.dart';
import '../../farms_providers.dart';
import 'edit_farm_controller.dart';

class EditFarmScreen extends ConsumerWidget {
  const EditFarmScreen({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsControllerProvider);

    FarmModel? farm;
    if (farmsState is FarmsLoaded) {
      for (final f in farmsState.farms) {
        if (f.id == farmId) farm = f;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Farm')),
      body: switch (farmsState) {
        FarmsInitial() || FarmsLoading() => const LoadingIndicator(),
        FarmsError(:final failure) => ErrorView(message: failure.message),
        FarmsLoaded() when farm == null =>
          const ErrorView(message: "We couldn't find that farm."),
        FarmsLoaded() => _EditFarmForm(farm: farm!),
      },
    );
  }
}

class _EditFarmForm extends ConsumerStatefulWidget {
  const _EditFarmForm({required this.farm});

  final FarmModel farm;

  @override
  ConsumerState<_EditFarmForm> createState() => _EditFarmFormState();
}

class _EditFarmFormState extends ConsumerState<_EditFarmForm> {
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
    final farm = widget.farm;
    _nameController = TextEditingController(text: farm.name);
    _phoneController = TextEditingController(text: farm.phone ?? '');
    _emailController = TextEditingController(text: farm.email ?? '');
    _locationController = TextEditingController(text: farm.location ?? '');
    _regionController = TextEditingController(text: farm.region ?? '');
    _countryController = TextEditingController(text: farm.country ?? '');
    _farmTypeController = TextEditingController(text: farm.farmType ?? '');
    _registrationNoController = TextEditingController(text: farm.registrationNo ?? '');
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(editFarmControllerProvider.notifier).submit(
          widget.farm.id,
          UpdateFarmInput(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            location: _locationController.text.trim(),
            region: _regionController.text.trim(),
            country: _countryController.text.trim(),
            farmType: _farmTypeController.text.trim(),
            registrationNo: _registrationNoController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormSubmissionState>(editFarmControllerProvider, (previous, next) {
      if (next is FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure.message)),
        );
      }
      if (next is FormSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm updated.')),
        );
        context.pop();
      }
    });

    final formState = ref.watch(editFarmControllerProvider);
    final isSubmitting = formState is FormSubmitting;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              AppTextField(
                label: 'Farm name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, fieldLabel: 'Farm name'),
                prefixIcon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Farm type',
                controller: _farmTypeController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Phone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Location',
                controller: _locationController,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Region',
                controller: _regionController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Country',
                controller: _countryController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Registration number',
                controller: _registrationNoController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save Changes',
                isLoading: isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
