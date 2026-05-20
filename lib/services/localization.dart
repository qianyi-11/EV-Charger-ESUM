import 'package:flutter/material.dart';

class AppLocalizations {
  static final AppLocalizations _instance = AppLocalizations._internal();

  factory AppLocalizations() {
    return _instance;
  }

  AppLocalizations._internal();

  static String _currentLanguage = 'en';

  static void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }

  static String getLanguage() => _currentLanguage;

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'ai_greeting':
          'Hello! I\'m EVision AI Assistant. I can help you understand EV charger errors, safety protocols, and maintenance procedures. How can I assist you today?',
      'error_8': 'What does Error 8 mean?',
      'dangerous': 'Is this dangerous?',
      'continue_charging': 'Can customer continue charging?',
      'how_fix': 'How to fix this?',
      'settings': 'Settings',
      'language': 'Language',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'get_alerts': 'Get alerts for critical errors',
      'system_info': 'System Information',
      'ai_model': 'AI Model Version',
      'offline_sync': 'Offline Sync',
      'enabled_diagnostics': 'Enabled for diagnostics',
      'about_evision': 'About EVision AI',
      'privacy_policy': 'Privacy Policy',
      'terms_service': 'Terms of Service',
    },
    'ms': {
      'ai_greeting':
          'Halo! Saya adalah Pembantu AI EVision. Saya dapat membantu Anda memahami ralat pengisi daya EV, protokol keselamatan, dan prosedur penyelenggaraan. Bagaimana saya boleh membantu Anda hari ini?',
      'error_8': 'Apakah maksud Ralat 8?',
      'dangerous': 'Adakah ini berbahaya?',
      'continue_charging': 'Bolehkah pelanggan terus mengisi daya?',
      'how_fix': 'Bagaimana cara memperbaikinya?',
      'settings': 'Tetapan',
      'language': 'Bahasa',
      'appearance': 'Rupa',
      'dark_mode': 'Mode Gelap',
      'notifications': 'Pemberitahuan',
      'push_notifications': 'Pemberitahuan Tolak',
      'get_alerts': 'Dapatkan amaran untuk ralat kritikal',
      'system_info': 'Maklumat Sistem',
      'ai_model': 'Versi Model AI',
      'offline_sync': 'Sinkronisasi Luar Talian',
      'enabled_diagnostics': 'Didayakan untuk diagnostik',
      'about_evision': 'Perihal EVision AI',
      'privacy_policy': 'Dasar Privasi',
      'terms_service': 'Terma Perkhidmatan',
    },
    'zh': {
      'ai_greeting':
          '你好！我是 EVision AI 助手。我可以帮助你理解电动车充电器错误、安全协议和维护程序。我今天可以如何帮助你？',
      'error_8': '错误 8 是什么意思？',
      'dangerous': '这危险吗？',
      'continue_charging': '客户可以继续充电吗？',
      'how_fix': '如何修复？',
      'settings': '设置',
      'language': '语言',
      'appearance': '外观',
      'dark_mode': '深色模式',
      'notifications': '通知',
      'push_notifications': '推送通知',
      'get_alerts': '获取关键错误警报',
      'system_info': '系统信息',
      'ai_model': 'AI 模型版本',
      'offline_sync': '离线同步',
      'enabled_diagnostics': '启用诊断功能',
      'about_evision': '关于 EVision AI',
      'privacy_policy': '隐私政策',
      'terms_service': '服务条款',
    },
  };

  static String translate(String key) {
    return _translations[_currentLanguage]?[key] ??
        _translations['en']?[key] ??
        key;
  }
}
