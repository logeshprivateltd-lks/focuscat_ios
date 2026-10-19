import Flutter
import UIKit
import AVKit
import AVFoundation
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVPictureInPictureControllerDelegate {
  private var pipController: AVPictureInPictureController?
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Audio Session setup for Background Audio & PiP
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
      try audioSession.setActive(true)
    } catch {
      print("[FocusCat] Audio session error: \(error)")
    }

    // Register PiP MethodChannel
    if let controller = window?.rootViewController as? FlutterViewController {
      let pipChannel = FlutterMethodChannel(name: "com.focuscat.pip", binaryMessenger: controller.binaryMessenger)
      pipChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else { return }
        switch call.method {
        case "isPipSupported":
          result(AVPictureInPictureController.isPictureInPictureSupported())
        case "startPip":
          self.startPip(result: result)
        case "stopPip":
          self.stopPip(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      // Register Widget MethodChannel (iOS Home Screen Widget Support)
      let widgetChannel = FlutterMethodChannel(name: "com.focuscat.widget", binaryMessenger: controller.binaryMessenger)
      widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "updateWidgetData":
          if let args = call.arguments as? [String: Any] {
            let defaults = UserDefaults(suiteName: "group.com.focuscat.ios") ?? UserDefaults.standard
            for (key, val) in args {
              defaults.set(val, forKey: key)
            }
            defaults.synchronize()
            if #available(iOS 14.0, *) {
              WidgetCenter.shared.reloadAllTimelines()
            }
            result(true)
          } else {
            result(false)
          }
        case "reloadWidgets":
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupPipController() {
    guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
    if pipController != nil { return }

    guard let url = Bundle.main.url(forResource: "focuscat_loop", withExtension: "mp4") ??
          URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4") else {
      return
    }
    let avPlayer = AVPlayer(url: url)
    avPlayer.isMuted = true
    avPlayer.actionAtItemEnd = .none
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: avPlayer.currentItem,
      queue: .main
    ) { _ in
      avPlayer.seek(to: .zero)
      avPlayer.play()
    }
    self.player = avPlayer

    let layer = AVPlayerLayer(player: avPlayer)
    layer.frame = CGRect(x: 0, y: 0, width: 320, height: 180)
    layer.isHidden = true
    window?.layer.addSublayer(layer)
    self.playerLayer = layer

    if #available(iOS 15.0, *) {
      let source = AVPictureInPictureController.ContentSource(playerLayer: layer)
      pipController = AVPictureInPictureController(contentSource: source)
    } else {
      pipController = AVPictureInPictureController(playerLayer: layer)
    }
    pipController?.delegate = self
    pipController?.canStartPictureInPictureAutomaticallyFromInline = true
  }

  private func startPip(result: @escaping FlutterResult) {
    setupPipController()
    guard let pip = pipController, AVPictureInPictureController.isPictureInPictureSupported() else {
      result(false)
      return
    }
    player?.play()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if pip.isPictureInPicturePossible {
        pip.startPictureInPicture()
        result(true)
      } else {
        result(true)
      }
    }
  }

  private func stopPip(result: @escaping FlutterResult) {
    pipController?.stopPictureInPicture()
    player?.pause()
    result(true)
  }

  func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    print("[FocusCat] PiP will start")
  }

  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    print("[FocusCat] PiP did stop")
    player?.pause()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
