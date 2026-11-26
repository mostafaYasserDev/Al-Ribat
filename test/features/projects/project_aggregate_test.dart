import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/features/projects/projects.dart';

void main() {
  group('ProjectAggregate Unit Tests', () {
    test('groups activities correctly and calculates progress', () {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final activities = [
        ActivityItem(
          id: '1',
          title: 'مهمة منجزة اليوم',
          projectName: 'مشروع الرباط',
          groupName: 'التطوير البرمجي',
          createdAt: now,
          historyDates: {todayStr},
        ),
        ActivityItem(
          id: '2',
          title: 'مهمة قيد الانتظار',
          projectName: 'مشروع الرباط',
          groupName: 'التطوير البرمجي',
          createdAt: now,
        ),
        ActivityItem(
          id: '3',
          title: 'مهمة في مرحلة التصميم',
          projectName: 'مشروع الرباط',
          groupName: 'التصميم',
          createdAt: now,
        ),
      ];

      final projects =
          ProjectAggregate.fromActivities(activities, ThemeData.light());

      expect(projects.length, 1);
      final project = projects.first;

      expect(project.name, 'مشروع الرباط');
      expect(project.totalTasks, 3);
      expect(project.completedTasks, 1);
      expect(project.progress, closeTo(1 / 3, 0.01));
      expect(project.isCompleted, isFalse);
      expect(project.groups.keys, containsAll(['التطوير البرمجي', 'التصميم']));
    });

    test('isCompleted is true only when all tasks are finished', () {
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final activities = [
        ActivityItem(
          id: '1',
          title: 'مهمة 1',
          projectName: 'قراءة كتاب',
          createdAt: now,
          historyDates: {todayStr},
        ),
        ActivityItem(
          id: '2',
          title: 'مهمة 2',
          projectName: 'قراءة كتاب',
          createdAt: now,
          historyDates: {todayStr},
        ),
      ];

      final projects =
          ProjectAggregate.fromActivities(activities, ThemeData.light());
      expect(projects.first.isCompleted, isTrue);
      expect(projects.first.progress, 1.0);
    });

    test('places ungrouped tasks in generalTasks without auto-creating a group',
        () {
      final now = DateTime.now();
      final activities = [
        ActivityItem(
          id: '10',
          title: 'مهمة بدون مرحلة',
          projectName: 'مشروع جديد',
          createdAt: now,
        ),
      ];

      final projects =
          ProjectAggregate.fromActivities(activities, ThemeData.light());
      expect(projects.first.groups.isEmpty, isTrue);
      expect(projects.first.generalTasks.length, 1);
      expect(projects.first.generalTasks.first.title, 'مهمة بدون مرحلة');
    });
  });
}
