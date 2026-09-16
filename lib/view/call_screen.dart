import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/call_service.dart';
import '../core/theme.dart';
import '../models/user_model.dart';

class CallScreen extends StatefulWidget {
  final UserModel otherUser;
  final bool isVideo;
  final String channelId;

  const CallScreen({
    super.key, 
    required this.otherUser, 
    this.isVideo = true,
    required this.channelId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await CallService.initAgora();
    
    CallService.engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined: ${connection.localUid}");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user offline: $remoteUid");
          setState(() => _remoteUid = null);
          Navigator.pop(context);
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() {
            _localUserJoined = false;
            _remoteUid = null;
          });
        },
      ),
    );

    await CallService.joinChannel(widget.channelId, 0);
  }

  @override
  void dispose() {
    CallService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 180,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: CallService.engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ),
          _buildOverlayControls(),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: CallService.engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: widget.otherUser.profileImage.isNotEmpty 
                ? NetworkImage(widget.otherUser.profileImage) 
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            "Calling ${widget.otherUser.name}...",
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Waiting for partner to join",
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),
        ],
      );
    }
  }

  Widget _buildOverlayControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              onPressed: () {
                setState(() => _isMuted = !_isMuted);
                CallService.engine.muteLocalAudioStream(_isMuted);
              },
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.redAccent : Colors.white24,
            ),
            _actionButton(
              onPressed: () => Navigator.pop(context),
              icon: Icons.call_end,
              color: Colors.red,
              size: 70,
            ),
            _actionButton(
              onPressed: () {
                CallService.engine.switchCamera();
              },
              icon: Icons.switch_camera,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required VoidCallback onPressed, required IconData icon, required Color color, double size = 60}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
