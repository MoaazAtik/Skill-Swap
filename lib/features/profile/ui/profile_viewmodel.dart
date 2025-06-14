import 'package:flutter/foundation.dart';

import '../../auth/domain/auth_repository.dart';
import '../domain/profile_model.dart';
import '../domain/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository;

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  bool loading = true;
  String? uid;
  String? email;
  ProfileModel? profile;

  /* When calling this method from the profile screen,
   The passed uid is from the auth repository aka, Firebase auth,
   not the profile repository which is a Firestore collection.
   But, when calling this method within this class pass profile!.ui
   because profile is already loaded.*/
  Future<void> loadProfile() async {
    uid = _authRepository.getUserId();
    email = _authRepository.getUserEmail();
    if (uid != null) {
      profile = await _profileRepository.getProfile(uid!);
      loading = false;
      notifyListeners();
    }
  }

  Future<String> updateProfile(ProfileModel newProfile) async {
    bool edited;
    if (profile == null) {
      // creating new profile
      edited = true;
    } else {
      edited = validateProfileUpdates(newProfile);
    }

    if (!edited) return 'No changes to save';

    await _profileRepository.saveProfile(newProfile);
    loadProfile();

    return 'Profile Saved';
  }

  bool validateProfileUpdates(ProfileModel newProfile) {
    bool edited = false;

    for (final entry in newProfile.toMap().entries) {
      // skip uid, email, lastEditedTime
      if (entry.key == 'uid' ||
          entry.key == 'email' ||
          entry.key == 'lastEditedTime') {
        continue;
      }

      // check skills
      if (entry.key == 'skills') {
        if (entry.value.toString() != profile!.toMap()[entry.key].toString()) {
          edited = true;
          break;
        }
        continue;
      }

      // check wishes
      if (entry.key == 'wishes') {
        if (entry.value.toString() != profile!.toMap()[entry.key].toString()) {
          edited = true;
          break;
        }
        continue;
      }

      // check name, bio
      if (entry.value != profile!.toMap()[entry.key]) {
        edited = true;
        break;
      }
    }

    return edited;
  }
}
