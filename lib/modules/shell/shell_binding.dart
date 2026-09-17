import 'package:get/get.dart';

import '../auth/auth_controller.dart';
import '../schedule/schedule_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduleController>(
      () => ScheduleController(Get.find<SchoolSession>()),
      fenix: true,
    );
  }
}
