import 'package:get/get.dart';

import '../auth/auth_controller.dart';
import 'schedule_controller.dart';

class ScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SchoolSession>(() => SchoolSession(), fenix: true);
    Get.lazyPut<ScheduleController>(
      () => ScheduleController(Get.find<SchoolSession>()),
      fenix: true,
    );
  }
}
