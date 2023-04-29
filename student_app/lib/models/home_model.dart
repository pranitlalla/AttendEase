import 'dart:async';
import 'dart:ui';

import 'package:attendease/controllers/home_controller.dart';
import 'package:attendease/database/db.dart';
import 'package:attendease/main.dart';
import 'package:attendease/views/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:pocketbase/pocketbase.dart';

class HomeModel {
  late HomeController _homeController;
  // late StreamSubscription _userSub;
  // late StreamSubscription _courseSub;
  // var userSub;
  // var courseSub;

  HomeModel(HomeController homeController) {
    _homeController = homeController;
    PbDb.pb.collection('students').subscribe(user.id, (e) async {
      // print("stream initalized");
      if (e.action == "update") {
        // print("stream is active");
        // _isFetching.value = true;
        _homeController.attendance = e.record?.data["attendance"];
        submitCheck.fire();
        if (!Get.isOverlaysClosed) {
          await Future.delayed(const Duration(seconds: 2), () {
            Get.back(closeOverlays: true);
          });
          // Get.back(closeOverlays: true);
        }
        int i = 0;
        _homeController.items.clear();
        _homeController.courses.forEach((key, value) {
          // print("key: $key, value: $value, attendance: ${attendance[key]}");
          // barData.add(BarData(name: key, y1: (attendance[key] != null) ? attendance[key].length : 0, y2: courses[key]));
          _homeController.items.add(makeGroupData(
              i++,
              (_homeController.attendance[key] != null)
                  ? _homeController.attendance[key].length
                  : 0,
              _homeController.courses[key]));
        });
        // rawBarGroups = items;
        _homeController.showingBarGroups = _homeController.items;
        _homeController.graphKey.currentState?.update();
        Future.delayed(const Duration(milliseconds: 500), () {
          _homeController.isFetching.value = false;
        });
        // _isFetching.value = false;
      }
    });
    PbDb.pb.collection("courses").subscribe("*", (e) {
      if (e.action == "update") {
        e.record?.data["students_enrolled"].forEach((element) {
          if (element == user.id) {
            _homeController.courses[e.record?.data["course_name"]] =
                e.record?.data["lectures"];
          }
        });
        // print("courses: $courses");
      }
    });
  }

  BarChartGroupData makeGroupData(int x, int y1, int y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1.toDouble(),
          color: const Color(0xFF04d9ff),
          width: 14,
        ),
        BarChartRodData(
          toY: y2.toDouble(),
          color: const Color(0xFF39FF14),
          width: 14,
        ),
      ],
    );
  }

  // Future<void> cancelSubscriptions() async {
  //   await PbDb.pb.collection('students').unsubscribe();
  //   await PbDb.pb.collection('courses').unsubscribe();
  // }

  Future<void> populateUserData() async {
    await PbDb.pb
        .collection("students")
        .getOne(user.id, expand: "courses(students).courses")
        .then((RecordModel value) {
      _homeController.attendance = value.data["attendance"];
    });
  }

  Future<void> populateUserCourses() async {
    await PbDb.pb.collection("courses").getFullList().then((value) {
      // print(value);
      for (RecordModel element in value) {
        if (element.data["students_enrolled"].contains(user.id)) {
          // print(element.data["course_name"]);
          // print(element.data["lectures"]);
          _homeController.courses[element.data["course_name"]] =
              element.data["lectures"];
        }
      }
      // print("courses: ${_homeController.courses}");
      // print("attendance: ${_homeController.attendance}");

      int i = 0;
      _homeController.items.clear();
      _homeController.courses.forEach((key, value) {
        _homeController.items.add(makeGroupData(
            i++,
            (_homeController.attendance[key] != null)
                ? _homeController.attendance[key].length
                : 0,
            _homeController.courses[key]));
      });
      //rawBarGroups = items;
      _homeController.showingBarGroups = _homeController.items;
      // print("test2");
      // Future.delayed(const Duration(milliseconds: 500), () {
      //   // _homeController.graphKey.currentState?.update();
      _homeController.isFetching.value = false;
      // });
    });
  }
}
