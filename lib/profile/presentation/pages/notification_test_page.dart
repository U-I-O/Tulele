import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tulele/core/services/notification_service.dart' as service;
import 'package:tulele/core/widgets/padded_button.dart';

class TestNotificationPage extends StatefulWidget {
  const TestNotificationPage(
    this.notificationAppLaunchDetails,
    {super.key,}
    ) ;

  final NotificationAppLaunchDetails? notificationAppLaunchDetails;

  bool get didNotificationLaunchApp =>
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  @override
  _TestNotificationPageState createState() => _TestNotificationPageState();
}

class _TestNotificationPageState extends State<TestNotificationPage> {
  final TextEditingController _linuxIconPathController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }


  Future<void> _requestPermissionsWithCriticalAlert() async {
    if (Platform.isIOS || Platform.isMacOS) {
       await service.requestIOSMacOSPermissions(critical: true);
    }
  }

  Future<void> _requestNotificationPolicyAccess() async {
    if (Platform.isAndroid) {
      await service.requestNotificationPolicyAccess();
    }
  }

  @override
  void dispose() {
    _linuxIconPathController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('通知插件演示页面'),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child:
                          Text('Tap on a notification when it appears to trigger'
                              ' navigation'),
                    ),
                    _InfoValueString(
                      title: '通知启动了应用?',
                      value: widget.didNotificationLaunchApp,
                    ),
                    if (widget.didNotificationLaunchApp) ...<Widget>[
                        const Text('用于启动的通知详细'),
                      _InfoValueString(
                          title: 'Notification id',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.id),
                      _InfoValueString(
                          title: 'Action id',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.actionId),
                      _InfoValueString(
                          title: 'Input',
                          value: widget.notificationAppLaunchDetails!
                              .notificationResponse?.input),
                      _InfoValueString(
                        title: 'Payload:',
                        value: widget.notificationAppLaunchDetails!
                            .notificationResponse?.payload,
                      ),
                    ],
                    PaddedElevatedButton(
                      buttonText: 'Show notification with custom sound',
                      onPressed: service.showNotificationCustomSound,
                    ),
                    if (kIsWeb || !Platform.isLinux) ...<Widget>[
                        PaddedElevatedButton(
                          buttonText:
                              '5秒后显示通知 '
                              '基于本地时间',
                          onPressed: service.zonedScheduleNotification,
                        ),
                    ],
                    PaddedElevatedButton(
                      buttonText:
                          'Show silent notification from channel with sound',
                      onPressed: service.showNotificationSilently,
                    ),
                    PaddedElevatedButton(
                      buttonText: '取消所有通知',
                      onPressed: service.cancelAllNotifications,
                    ),
                    const Divider(),
                    const Text(
                      'Notifications with actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with plain actions',
                      onPressed: service.showNotificationWithActions,
                    ),
                    if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text action',
                      onPressed: service.showNotificationWithTextAction,
                    ),

                    if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text choice',
                      onPressed: service.showNotificationWithTextChoice,
                    ),
                  const Divider(),
                  if (Platform.isAndroid) ...<Widget>[
                    const Text(
                      '安卓平台示例',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('notifications enabled: ${service.notificationsEnabled}'),
                     PaddedElevatedButton(
                        buttonText: 'Request Android Permissions',
                        onPressed: service.requestPermissions // Specific to Android in this button context
                    ),
                    PaddedElevatedButton(
                        buttonText: 'Request Critical Alert Permissions (iOS/macOS)',
                        onPressed: _requestPermissionsWithCriticalAlert
                    ),
                    PaddedElevatedButton(
                        buttonText: 'Request Notification Policy Access (Android)',
                        onPressed: _requestNotificationPolicyAccess
                    ),
                    PaddedElevatedButton(
                      buttonText:
                          'Show big picture notification, hide large icon '
                          'on expand',
                      onPressed: service.showBigPictureNotificationHiddenLargeIcon,
                    ),
                    PaddedElevatedButton(
                      buttonText:
                          'Show progress notification - updates every second',
                      onPressed: service.showProgressNotification,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class SecondPage extends StatefulWidget {
  const SecondPage(
    this.payload, 
    {//命名参数 (named parameters)。它们是可选的
    this.data,
    Key? key,
    }
  ) : super(key: key);

  static const String routeName = '/secondPage';

  final String? payload;
  final Map<String, dynamic>? data; // From NotificationResponse

  @override
  State<StatefulWidget> createState() => SecondPageState();
}

class SecondPageState extends State<SecondPage> {
  String? _payload;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _payload = widget.payload;
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Second Screen (Payload: ${_payload ?? ''})'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Payload from notification: ${_payload ?? ''}'),
              if (_data != null) Text('Data from notification: ${_data.toString()}'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go back!'),
              ),
            ],
          ),
        ),
      );
}

class _InfoValueString extends StatelessWidget {
  const _InfoValueString({
    required this.title,
    required this.value,
    Key? key,
  }) : super(key: key);

  final String title;
  final Object? value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$title ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '$value',
              )
            ],
          ),
        ),
      );
} 