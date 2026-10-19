import Flutter
import UIKit
import AVKit
import AVFoundation
import WidgetKit
import SwiftUI

// =============================================================================
// Floating Cat PiP View (iOS 15+)
// Renders the animated companion, speech bubble & timer in native floating PiP
// =============================================================================
@available(iOS 15.0, *)
struct FloatingCatPiPView: View {
  @State private var bounce = false
  @State private var currentPose = "sit"
  @State private var catEmoji = "🐱"
  @State private var statusText = "FocusCat is on patrol 🐾"
  @State private var timeRemaining = "25:00"

  let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      Color(red: 0.07, green: 0.09, blue: 0.13)
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 4) {
        // Top status badge
        HStack(spacing: 4) {
          Circle()
            .fill(Color(red: 0.29, green: 0.87, blue: 0.50))
            .frame(width: 6, height: 6)
          Text("FocusCat")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          Text(timeRemaining)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)

        Spacer()

        // Bouncing animated companion
        Text(catEmoji)
          .font(.system(size: 46))
          .offset(y: bounce ? -4 : 4)
          .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: bounce)

        Spacer()

        // Speech bubble pill
        Text(statusText)
          .font(.system(size: 9.5, weight: .medium))
          .foregroundColor(Color(white: 0.9))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color.white.opacity(0.14))
          .cornerRadius(6)
          .lineLimit(1)
          .padding(.bottom, 6)
      }
    }
    .onAppear {
      bounce = true
      refreshData()
    }
    .onReceive(timer) { _ in
      refreshData()
    }
  }

  private func refreshData() {
    let defaults = UserDefaults(suiteName: "group.com.lks.focuscat") ?? UserDefaults.standard
    catEmoji = defaults.string(forKey: "catEmoji") ?? "🐱"
    currentPose = defaults.string(forKey: "catPose") ?? "sit"
    statusText = defaults.string(forKey: "speechBubble") ?? "Purr... watching over your focus! 🐾"
    let remaining = defaults.integer(forKey: "focusSecondsRemaining")
    let endTime = defaults.double(forKey: "focusEndTime")
    if endTime > Date().timeIntervalSince1970 {
      let diff = Int(endTime - Date().timeIntervalSince1970)
      timeRemaining = String(format: "%02d:%02d", diff / 60, diff % 60)
    } else if remaining > 0 {
      timeRemaining = String(format: "%02d:%02d", remaining / 60, remaining % 60)
    } else {
      timeRemaining = "PATROL"
    }
  }
}

// =============================================================================
// FocusCat Video Loop Generator (Offline fallback)
// Generates a local, offline loop video so PiP never depends on remote URLs
// =============================================================================
class FocusCatVideoLoopGenerator {
  static func localVideoURL() -> URL {
    let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return cachesDir.appendingPathComponent("focuscat_loop.mp4")
  }

  static func ensureLocalLoopVideoExists() -> URL? {
    let fileURL = localVideoURL()
    if FileManager.default.fileExists(atPath: fileURL.path) {
      return fileURL
    }

    // Generate a minimal 2-second 30fps black/cat frame MP4
    guard let writer = try? AVAssetWriter(outputURL: fileURL, fileType: .mp4) else {
      return nil
    }

    let settings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: 320,
      AVVideoHeightKey: 240
    ]
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = false

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: input,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: 320,
        kCVPixelBufferHeightKey as String: 240
      ]
    )

    writer.add(input)
    guard writer.startWriting() else { return nil }
    writer.startSession(atSourceTime: .zero)

    let fps: Int32 = 30
    let totalFrames = fps * 2 // 2 seconds

    for frame in 0..<totalFrames {
      while !input.isReadyForMoreMediaData {
        Thread.sleep(forTimeInterval: 0.005)
      }
      var pixelBuffer: CVPixelBuffer?
      CVPixelBufferCreate(kCFAllocatorDefault, 320, 240, kCVPixelFormatType_32ARGB, nil, &pixelBuffer)
      if let buffer = pixelBuffer {
        CVPixelBufferLockBaseAddress(buffer, [])
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
          memset(baseAddress, 0x1A, 320 * 240 * 4) // Dark slate fill
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        let presentationTime = CMTime(value: Int64(frame), timescale: fps)
        adaptor.append(buffer, withPresentationTime: presentationTime)
      }
    }

    input.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting {
      semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 2.0)

    return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
  }
}

// =============================================================================
// AppDelegate
// =============================================================================
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVPictureInPictureControllerDelegate {
  private var pipController: AVPictureInPictureController?
  private var pipSourceView: UIView?
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // STEP 3: Configure iOS Native Audio Session immediately upon launch
    // Ensures cat meows, purrs, chimes & TTS play loudly out of the iPhone speaker even on silent mode
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth])
      try AVAudioSession.sharedInstance().setActive(true)
      print("[FocusCat] Native AVAudioSession configured: .playback, mode: .default, mixWithOthers + allowBluetooth")
    } catch {
      print("[FocusCat] Failed to set audio session category: \(error)")
    }

    // Register Native Method Channels
    if let controller = window?.rootViewController as? FlutterViewController {
      // 1. Picture-in-Picture Platform Channel
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

      // 2. Home Screen Widget Platform Channel
      let widgetChannel = FlutterMethodChannel(name: "com.focuscat.widget", binaryMessenger: controller.binaryMessenger)
      widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "updateWidgetData":
          if let args = call.arguments as? [String: Any] {
            let defaults = UserDefaults(suiteName: "group.com.lks.focuscat") ?? UserDefaults.standard
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

    // Option A: iOS 15+ Custom View PiP via AVPictureInPictureVideoCallViewController
    if #available(iOS 15.0, *) {
      let callVC = AVPictureInPictureVideoCallViewController()
      callVC.preferredContentSize = CGSize(width: 180, height: 160)
      let hosting = UIHostingController(rootView: FloatingCatPiPView())
      hosting.view.backgroundColor = .clear
      callVC.addChild(hosting)
      callVC.view.addSubview(hosting.view)
      hosting.view.frame = callVC.view.bounds
      hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      hosting.didMove(toParent: callVC)

      let sourceView = UIView(frame: CGRect(x: 16, y: 16, width: 1, height: 1))
      sourceView.backgroundColor = .clear
      window?.addSubview(sourceView)
      self.pipSourceView = sourceView

      let contentSource = AVPictureInPictureController.ContentSource(
        activeVideoCallSourceView: sourceView,
        contentViewController: callVC
      )
      let pip = AVPictureInPictureController(contentSource: contentSource)
      pip.canStartPictureInPictureAutomaticallyFromInline = true
      pip.delegate = self
      self.pipController = pip
      return
    }

    // Option B: Fallback via local offline video loop
    let videoURL = Bundle.main.url(forResource: "focuscat_loop", withExtension: "mp4") ??
                   FocusCatVideoLoopGenerator.ensureLocalLoopVideoExists()

    guard let url = videoURL else { return }

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
    layer.frame = CGRect(x: 0, y: 0, width: 320, height: 240)
    layer.isHidden = true
    window?.layer.addSublayer(layer)
    self.playerLayer = layer

    let pip = AVPictureInPictureController(playerLayer: layer)
    pip?.delegate = self
    pip?.canStartPictureInPictureAutomaticallyFromInline = true
    self.pipController = pip
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
    print("[FocusCat] PiP floating overlay started outside sandbox")
  }

  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    print("[FocusCat] PiP floating overlay stopped")
    player?.pause()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
