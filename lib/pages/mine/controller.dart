import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/http/user.dart';
import 'package:pilipala/models/user/info.dart';
import 'package:pilipala/models/user/stat.dart';
import 'package:pilipala/utils/storage.dart';

class MineController extends GetxController {
  // 用户信息 头像、昵称、lv
  Rx<UserInfoData> userInfo = UserInfoData().obs;
  // 用户状态 动态、关注、粉丝
  Rx<UserStat> userStat = UserStat().obs;
  Box user = GStrorage.user;
  RxBool userLogin = false.obs;
  Box userInfoCache = GStrorage.userInfo;

  @override
  onInit() {
    super.onInit();

    if (userInfoCache.get('userInfoCache') != null) {
      userInfo.value = userInfoCache.get('userInfoCache');
    }
  }

  onLogin() async {
    if (!userLogin.value) {
      /// TODO
      Get.back();
      await Future.delayed(const Duration(milliseconds: 150));
      Get.toNamed(
        '/webview',
        parameters: {
          'url': 'https://passport.bilibili.com/h5-app/passport/login',
          'type': 'login',
          'pageTitle': '登录bilibili',
        },
      );
    } else {
      int mid = user.get(UserBoxKey.userMid);
      String face = user.get(UserBoxKey.userFace);
      Get.toNamed(
        '/member?mid=$mid',
        arguments: {'face': face},
      );
    }
  }

  Future queryUserInfo() async {
    if (user.get(UserBoxKey.userLogin) == null) {
      return {'status': false};
    }
    var res = await UserHttp.userInfo();
    if (res['status']) {
      if (res['data'].isLogin) {
        userInfo.value = res['data'];
        userInfoCache.put('userInfoCache', res['data']);
        user.put(UserBoxKey.userName, res['data'].uname);
        user.put(UserBoxKey.userFace, res['data'].face);
        user.put(UserBoxKey.userMid, res['data'].mid);
        user.put(UserBoxKey.userLogin, true);
        userLogin.value = true;
        // Get.find<MainController>().readuUserFace();
      } else {
        resetUserInfo();
      }
    } else {
      resetUserInfo();
      // SmartDialog.showToast(res['msg']);
    }
    await queryUserStatOwner();
    return res;
  }

  Future queryUserStatOwner() async {
    var res = await UserHttp.userStatOwner();
    if (res['status']) {
      userStat.value = res['data'];
    }
    return res;
  }

  Future resetUserInfo() async {
    userInfo.value = UserInfoData();
    userStat.value = UserStat();
    await user.delete(UserBoxKey.userName);
    await user.delete(UserBoxKey.userFace);
    await user.delete(UserBoxKey.userMid);
    await user.delete(UserBoxKey.userLogin);
    userLogin.value = false;
    // Get.find<MainController>().resetLast();
  }
}
