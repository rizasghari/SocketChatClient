import 'models/user.dart';
import 'services/local_storage_service.dart';

class Utils {
  static Future<String> getProfilePhotoUrl(String filePath) async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    return "http://$apiHost:9000$filePath";
  }

  static Future<void> setUsersListProfilePhotosURl(List<User>? users) async {
    if (users == null) {
      return;
    }
    for (var user in users) {
      user.profilePhoto = await getProfilePhotoUrl(user.profilePhoto!);
    }
  }
}