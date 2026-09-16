import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/config.dart';

class CallService {
  static RtcEngine? _engine;

  static Future<void> initAgora() async {
    if (_engine != null) return;

    // 1. Request permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Initialize engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AppConfig.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine!.enableVideo();
    await _engine!.startPreview();
  }

  static RtcEngine get engine {
    if (_engine == null) throw Exception('Agora Engine not initialized');
    return _engine!;
  }

  static Future<void> joinChannel(String channelId, int uid) async {
    await _engine!.joinChannel(
      token: '', // Use empty string for temp tokens or if security is disabled in Agora Console
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  static Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }
}
