import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tic_tac_toe/utils/app_icons.dart';
import 'package:tic_tac_toe/commons/models/enums/enums.dart';
import 'package:tic_tac_toe/utils/extensions/build_context.dart';
import 'package:tic_tac_toe/utils/extensions/num_extension.dart';
import 'package:tic_tac_toe/utils/validator.dart';
import 'package:tic_tac_toe/commons/widgets/custom_bottom_sheet.dart';
import 'package:tic_tac_toe/commons/widgets/custom_button.dart';
import 'package:tic_tac_toe/commons/widgets/custom_image.dart';
import 'package:tic_tac_toe/commons/widgets/custom_textfield.dart';
import 'package:tic_tac_toe/core/services/firebase_service.dart';
import 'package:tic_tac_toe/features/auth/blocs/authentication_bloc.dart';
import 'package:tic_tac_toe/commons/models/user_model.dart';

/// Edit Profile — lets a signed-in user change their display name and profile
/// picture. Presented as a bottom sheet in the same style as
/// [ChangeLanguageDialog]. The actual Firebase work (Storage upload + `users`
/// node writes) lives in [DatabaseService.updateUsername] /
/// [DatabaseService.uploadProfilePic]; [AuthenticationBloc] then streams the
/// updated user back to every screen.
class EditProfileSheet {
  EditProfileSheet._();

  static Future<void> show(BuildContext context) {
    return showCustomBottomSheet(
      context,
      title: context.tr('editProfile'),
      child: const _EditProfileForm(),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm();

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  late final TextEditingController _nameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  /// Locally-picked image, previewed immediately and uploaded on save. Null
  /// means the user hasn't chosen a new picture.
  File? _pickedImage;
  bool _isSaving = false;

  UserModel? get _user => context.read<AuthenticationBloc>().user;

  //--------------------------------------------------
  // Lifecycle
  //--------------------------------------------------

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _user?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // API Methods
  //--------------------------------------------------

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Resolve navigator/messenger before the awaits so we don't touch a
    // possibly-unmounted context afterwards.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String successMessage = context.tr('profileUpdatedSuccessfully');
    final String errorMessage = context.tr('somethingWentWrongTryAgain');

    final String newName = _nameController.text.trim();
    final bool nameChanged = newName !=
        (_user?.username ?? ''); // gates the updateUsername call below

    setState(() => _isSaving = true);
    try {
      // Only touch fields that actually changed, to avoid unnecessary writes/uploads.
      if (_pickedImage != null) {
        await DatabaseService.instance.uploadProfilePic(_pickedImage!);
      }
      if (nameChanged) {
        await DatabaseService.instance.updateUsername(newName);
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  //--------------------------------------------------
  // UI Builder Methods
  //--------------------------------------------------

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            width: 88.r(context),
            height: 88.r(context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.color.tertiary.withAlpha(100),
            ),
            child: ClipOval(
              child: _pickedImage != null
                  ? Image.file(
                      _pickedImage!,
                      fit: BoxFit.cover,
                      width: 88.r(context),
                      height: 88.r(context),
                    )
                  : CustomImage(
                      _user?.profilePic ?? AppIcons.guest,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              padding: EdgeInsets.all(5.r(context)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.secondary,
                border:
                    Border.all(color: context.color.surfaceContainer, width: 2),
              ),
              child: Icon(
                Icons.edit,
                size: 14.r(context),
                color: context.color.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // build()
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.sizes.lg, context.sizes.xs,
          context.sizes.lg, context.sizes.lg),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(context),
            SizedBox(height: context.sizes.xl),
            CustomTextField(
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              hintText: context.tr('username'),
              validator: (value) => Validator.validateRequired(context, value),
            ),
            SizedBox(height: context.sizes.xl),
            CustomButton(
              onTap: _isSaving ? null : _save,
              title: context.tr('save'),
              type: ButtonType.primary,
              inProgress: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
