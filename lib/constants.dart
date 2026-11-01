import 'package:flutter/material.dart';

// Generated constants for generation types

enum GenerationType { conspect, worksheet, homework }

extension GenerationTypeExt on GenerationType {
  String get label {
    switch (this) {
      case GenerationType.conspect:
        return 'Конспект занятия';
      case GenerationType.worksheet:
        return 'Лист заданий';
      case GenerationType.homework:
        return 'Домашнее задание';
    }
  }

  String get description {
    switch (this) {
      case GenerationType.conspect:
        return 'Полный конспект занятия';
      case GenerationType.worksheet:
        return 'Лист с заданиями, сразу в PDF';
      case GenerationType.homework:
        return 'Домашнее задание в PDF';
    }
  }

  IconData get icon {
    switch (this) {
      case GenerationType.conspect:
        return Icons.auto_stories_outlined;
      case GenerationType.worksheet:
        return Icons.list_alt_outlined;
      case GenerationType.homework:
        return Icons.home_work_outlined;
    }
  }
}
