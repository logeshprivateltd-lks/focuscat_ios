import WidgetKit
import SwiftUI

// =============================================================================
// FocusCat iOS Home Screen Widget
// Developed by LKS.pvt.ltd company
// Displays the Kawaii FocusCat companion, speech bubble, focus timer & patrol status.
// =============================================================================

public struct FocusCatEntry: TimelineEntry {
  public let date: Date
  public let catPose: String
  public let catEmoji: String
  public let catMood: String
  public let speechBubble: String
  public let isPatrolling: Bool
  public let focusSecondsRemaining: Int
  public let focusEndTimeTimestamp: Double?
  public let targetAppOrDomain: String
  public let dailyFocusMinutes: Int
  public let company: String

  public init(
    date: Date = Date(),
    catPose: String = "sit",
    catEmoji: String = "🐱",
    catMood: String = "Chill",
    speechBubble: String = "Purr... staying focused! 🐾",
    isPatrolling: Bool = true,
    focusSecondsRemaining: Int = 0,
    focusEndTimeTimestamp: Double? = nil,
    targetAppOrDomain: String = "YouTube & Socials",
    dailyFocusMinutes: Int = 45,
    company: String = "LKS.pvt.ltd company"
  ) {
    self.date = date
    self.catPose = catPose
    self.catEmoji = catEmoji
    self.catMood = catMood
    self.speechBubble = speechBubble
    self.isPatrolling = isPatrolling
    self.focusSecondsRemaining = focusSecondsRemaining
    self.focusEndTimeTimestamp = focusEndTimeTimestamp
    self.targetAppOrDomain = targetAppOrDomain
    self.dailyFocusMinutes = dailyFocusMinutes
    self.company = company
  }
}

// -----------------------------------------------------------------------------
// Timeline Provider
// -----------------------------------------------------------------------------
struct FocusCatTimelineProvider: TimelineProvider {
  typealias Entry = FocusCatEntry

  private func fetchEntry(for date: Date = Date()) -> FocusCatEntry {
    let defaults = UserDefaults(suiteName: "group.com.focuscat.ios") ?? UserDefaults.standard

    let pose = defaults.string(forKey: "catPose") ?? "sit"
    let emoji = defaults.string(forKey: "catEmoji") ?? "🐱"
    let mood = defaults.string(forKey: "catMood") ?? "Focused"
    let speech = defaults.string(forKey: "speechBubble") ?? "Purr... ready to focus with you! 🐾"
    let isPatrolling = defaults.object(forKey: "isPatrolling") as? Bool ?? true
    let remaining = defaults.integer(forKey: "focusSecondsRemaining")
    let endTime = defaults.double(forKey: "focusEndTime")
    let target = defaults.string(forKey: "targetAppOrDomain") ?? "Safari & Apps"
    let dailyMins = defaults.integer(forKey: "dailyFocusMinutes")

    return FocusCatEntry(
      date: date,
      catPose: pose,
      catEmoji: emoji,
      catMood: mood,
      speechBubble: speech,
      isPatrolling: isPatrolling,
      focusSecondsRemaining: remaining,
      focusEndTimeTimestamp: endTime > 0 ? endTime : nil,
      targetAppOrDomain: target,
      dailyFocusMinutes: dailyMins > 0 ? dailyMins : 25,
      company: "LKS.pvt.ltd company"
    )
  }

  func placeholder(in context: Context) -> FocusCatEntry {
    FocusCatEntry()
  }

  func getSnapshot(in context: Context, completion: @escaping (FocusCatEntry) -> Void) {
    completion(fetchEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<FocusCatEntry>) -> Void) {
    let current = fetchEntry()
    // Refresh every 15 minutes or when updated by Flutter app
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    let timeline = Timeline(entries: [current], policy: .after(nextUpdate))
    completion(timeline)
  }
}

// -----------------------------------------------------------------------------
// Kawaii Cat SwiftUI Drawing Component
// -----------------------------------------------------------------------------
struct KawaiiCatView: View {
  let pose: String
  let mood: String
  let size: CGFloat

  var body: some View {
    ZStack {
      // Cat Body & Silhouette
      VStack(spacing: 0) {
        // Ears
        HStack(spacing: size * 0.28) {
          // Left Ear
          ZStack {
            EarShape()
              .fill(Color(red: 0.95, green: 0.82, blue: 0.65))
              .frame(width: size * 0.28, height: size * 0.28)
            EarShape()
              .fill(Color(red: 0.98, green: 0.65, blue: 0.70))
              .frame(width: size * 0.16, height: size * 0.16)
              .offset(y: size * 0.03)
          }

          // Right Ear
          ZStack {
            EarShape()
              .fill(Color(red: 0.95, green: 0.82, blue: 0.65))
              .frame(width: size * 0.28, height: size * 0.28)
              .scaleEffect(x: -1, y: 1)
            EarShape()
              .fill(Color(red: 0.98, green: 0.65, blue: 0.70))
              .frame(width: size * 0.16, height: size * 0.16)
              .scaleEffect(x: -1, y: 1)
              .offset(y: size * 0.03)
          }
        }
        .offset(y: size * 0.08)

        // Head
        ZStack {
          // Head Base
          RoundedRectangle(cornerRadius: size * 0.26)
            .fill(
              LinearGradient(
                colors: [
                  Color(red: 0.98, green: 0.88, blue: 0.74),
                  Color(red: 0.93, green: 0.80, blue: 0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .frame(width: size * 0.78, height: size * 0.58)
            .overlay(
              RoundedRectangle(cornerRadius: size * 0.26)
                .stroke(Color(red: 0.75, green: 0.58, blue: 0.40), lineWidth: 1.5)
            )

          // Fur Cheeks / Blushes
          HStack {
            Circle()
              .fill(Color(red: 1.0, green: 0.60, blue: 0.65).opacity(0.65))
              .frame(width: size * 0.14, height: size * 0.14)
            Spacer()
            Circle()
              .fill(Color(red: 1.0, green: 0.60, blue: 0.65).opacity(0.65))
              .frame(width: size * 0.14, height: size * 0.14)
          }
          .padding(.horizontal, size * 0.08)
          .offset(y: size * 0.06)

          // Whiskers
          HStack {
            // Left Whiskers
            VStack(spacing: size * 0.04) {
              Rectangle()
                .fill(Color(red: 0.55, green: 0.40, blue: 0.28))
                .frame(width: size * 0.14, height: 1.5)
                .rotationEffect(.degrees(6))
              Rectangle()
                .fill(Color(red: 0.55, green: 0.40, blue: 0.28))
                .frame(width: size * 0.12, height: 1.5)
                .rotationEffect(.degrees(-6))
            }
            Spacer()
            // Right Whiskers
            VStack(spacing: size * 0.04) {
              Rectangle()
                .fill(Color(red: 0.55, green: 0.40, blue: 0.28))
                .frame(width: size * 0.14, height: 1.5)
                .rotationEffect(.degrees(-6))
              Rectangle()
                .fill(Color(red: 0.55, green: 0.40, blue: 0.28))
                .frame(width: size * 0.12, height: 1.5)
                .rotationEffect(.degrees(6))
            }
          }
          .padding(.horizontal, size * 0.02)
          .offset(y: size * 0.04)

          // Face: Eyes, Nose, Mouth
          VStack(spacing: size * 0.02) {
            // Eyes according to pose
            HStack(spacing: size * 0.24) {
              CatEyeView(pose: pose, isLeft: true, size: size)
              CatEyeView(pose: pose, isLeft: false, size: size)
            }

            // Nose
            Triangle()
              .fill(Color(red: 0.95, green: 0.45, blue: 0.55))
              .frame(width: size * 0.07, height: size * 0.05)
              .rotationEffect(.degrees(180))

            // Mouth: Cute "ω"
            CatMouthShape()
              .stroke(Color(red: 0.45, green: 0.30, blue: 0.20), lineWidth: 1.4)
              .frame(width: size * 0.18, height: size * 0.06)
          }
          .offset(y: size * 0.02)
        }

        // Paws & Collar
        HStack(spacing: size * 0.18) {
          // Left Paw
          RoundedRectangle(cornerRadius: size * 0.08)
            .fill(Color(red: 0.98, green: 0.92, blue: 0.85))
            .frame(width: size * 0.20, height: size * 0.16)
            .overlay(
              RoundedRectangle(cornerRadius: size * 0.08)
                .stroke(Color(red: 0.75, green: 0.58, blue: 0.40), lineWidth: 1)
            )

          // Golden Bell Charm
          Circle()
            .fill(Color(red: 0.98, green: 0.78, blue: 0.20))
            .frame(width: size * 0.11, height: size * 0.11)
            .overlay(
              Circle().stroke(Color(red: 0.80, green: 0.60, blue: 0.10), lineWidth: 1)
            )
            .offset(y: -size * 0.04)

          // Right Paw
          RoundedRectangle(cornerRadius: size * 0.08)
            .fill(Color(red: 0.98, green: 0.92, blue: 0.85))
            .frame(width: size * 0.20, height: size * 0.16)
            .overlay(
              RoundedRectangle(cornerRadius: size * 0.08)
                .stroke(Color(red: 0.75, green: 0.58, blue: 0.40), lineWidth: 1)
            )
        }
        .offset(y: -size * 0.04)
      }

      // Sleeping "Zzz" accessory if asleep
      if pose.lowercased().contains("sleep") {
        VStack(alignment: .trailing, spacing: 2) {
          Text("z")
            .font(.system(size: size * 0.14, weight: .bold, design: .rounded))
            .foregroundColor(.cyan)
          Text("Z")
            .font(.system(size: size * 0.20, weight: .bold, design: .rounded))
            .foregroundColor(.cyan)
        }
        .offset(x: size * 0.40, y: -size * 0.32)
      }

      // Focus Headband / Shield badge if patrolling or focusing
      if pose.lowercased().contains("patrol") || mood.lowercased().contains("patrol") {
        Image(systemName: "shield.fill")
          .font(.system(size: size * 0.18))
          .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          .offset(x: -size * 0.36, y: -size * 0.24)
      }
    }
    .frame(width: size, height: size)
  }
}

// Cat Eye View based on mood / pose
struct CatEyeView: View {
  let pose: String
  let isLeft: Bool
  let size: CGFloat

  var body: some View {
    let p = pose.lowercased()
    if p.contains("sleep") || p.contains("nap") {
      // Closed happy curved eye: ⌒
      ArcShape()
        .stroke(Color(red: 0.40, green: 0.25, blue: 0.15), lineWidth: 2)
        .frame(width: size * 0.12, height: size * 0.06)
    } else if p.contains("focus") || p.contains("laser") {
      // Determined focus eye: •̀
      ZStack {
        Circle()
          .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
          .frame(width: size * 0.12, height: size * 0.12)
        Circle()
          .fill(Color.white)
          .frame(width: size * 0.04, height: size * 0.04)
          .offset(x: 2, y: -2)
      }
    } else {
      // Big shiny anime kawaii eye
      ZStack {
        Ellipse()
          .fill(Color(red: 0.20, green: 0.15, blue: 0.25))
          .frame(width: size * 0.12, height: size * 0.15)
        Circle()
          .fill(Color.white)
          .frame(width: size * 0.05, height: size * 0.05)
          .offset(x: -1.5, y: -2.5)
        Circle()
          .fill(Color.white)
          .frame(width: size * 0.025, height: size * 0.025)
          .offset(x: 1.5, y: 2.0)
      }
    }
  }
}

// Shapes for Kawaii Cat
struct EarShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.midX, y: rect.minY),
      control: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.minY + rect.height * 0.2)
    )
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.maxY),
      control: CGPoint(x: rect.maxX - rect.width * 0.1, y: rect.minY + rect.height * 0.4)
    )
    path.closeSubpath()
    return path
  }
}

struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

struct CatMouthShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
    path.addQuadCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY),
      control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY)
    )
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2),
      control: CGPoint(x: rect.midX + rect.width * 0.25, y: rect.maxY)
    )
    return path
  }
}

struct ArcShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.maxY),
      control: CGPoint(x: rect.midX, y: rect.minY)
    )
    return path
  }
}

// -----------------------------------------------------------------------------
// Small Widget View (2x2)
// -----------------------------------------------------------------------------
struct FocusCatSmallWidgetView: View {
  let entry: FocusCatEntry

  var body: some View {
    VStack(spacing: 4) {
      // Top status row
      HStack {
        HStack(spacing: 4) {
          Circle()
            .fill(entry.isPatrolling ? Color(red: 0.29, green: 0.87, blue: 0.50) : Color.orange)
            .frame(width: 6, height: 6)
          Text(entry.isPatrolling ? "PATROL" : "FOCUS")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(entry.isPatrolling ? Color(red: 0.29, green: 0.87, blue: 0.50) : Color.orange)
        }
        Spacer()
        if let endTime = entry.focusEndTimeTimestamp, endTime > Date().timeIntervalSince1970 {
          Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
        } else if entry.focusSecondsRemaining > 0 {
          let m = entry.focusSecondsRemaining / 60
          let s = entry.focusSecondsRemaining % 60
          Text(String(format: "%02d:%02d", m, s))
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
        } else {
          Text("FocusCat")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        }
      }

      Spacer(minLength: 0)

      // The Kawaii Focus Cat!
      KawaiiCatView(pose: entry.catPose, mood: entry.catMood, size: 66)

      Spacer(minLength: 0)

      // Speech bubble text
      Text(entry.speechBubble)
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(Color(white: 0.90))
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.08))
        .cornerRadius(6)
    }
    .padding(12)
    .background(Color(red: 0.05, green: 0.08, blue: 0.12))
  }
}

// -----------------------------------------------------------------------------
// Medium Widget View (4x2)
// -----------------------------------------------------------------------------
struct FocusCatMediumWidgetView: View {
  let entry: FocusCatEntry

  var body: some View {
    HStack(spacing: 12) {
      // Left: Kawaii Cat + Mood Tag
      VStack(spacing: 6) {
        KawaiiCatView(pose: entry.catPose, mood: entry.catMood, size: 76)
        Text(entry.catMood.uppercased())
          .font(.system(size: 8.5, weight: .bold))
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.2))
          .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          .cornerRadius(4)
      }
      .frame(width: 90)

      // Right: Focus timer, patrol shield & speech bubble
      VStack(alignment: .leading, spacing: 6) {
        // App header & Timer
        HStack {
          Text("FocusCat")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
          Spacer()
          if let endTime = entry.focusEndTimeTimestamp, endTime > Date().timeIntervalSince1970 {
            Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
              .font(.system(size: 14, weight: .bold, design: .monospaced))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          } else if entry.focusSecondsRemaining > 0 {
            let m = entry.focusSecondsRemaining / 60
            let s = entry.focusSecondsRemaining % 60
            Text(String(format: "%02d:%02d", m, s))
              .font(.system(size: 14, weight: .bold, design: .monospaced))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          } else {
            HStack(spacing: 4) {
              Circle()
                .fill(Color(red: 0.29, green: 0.87, blue: 0.50))
                .frame(width: 6, height: 6)
              Text("PATROL ACTIVE")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            }
          }
        }

        // Speech Bubble
        HStack(alignment: .top, spacing: 5) {
          Text("💬")
            .font(.system(size: 11))
          Text(entry.speechBubble)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(white: 0.92))
            .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .cornerRadius(6)

        // Shield status & Developer attribution
        HStack {
          HStack(spacing: 4) {
            Image(systemName: "shield.fill")
              .font(.system(size: 9))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            Text(entry.targetAppOrDomain)
              .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
              .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
              .lineLimit(1)
          }
          Spacer()
          Text("LKS.pvt.ltd")
            .font(.system(size: 8.5, weight: .semibold))
            .foregroundColor(Color(white: 0.50))
        }
      }
    }
    .padding(14)
    .background(Color(red: 0.05, green: 0.08, blue: 0.12))
  }
}

// -----------------------------------------------------------------------------
// Large Widget View (4x4)
// -----------------------------------------------------------------------------
struct FocusCatLargeWidgetView: View {
  let entry: FocusCatEntry

  var body: some View {
    VStack(spacing: 12) {
      // Top header
      HStack {
        HStack(spacing: 6) {
          Image(systemName: "pawprint.fill")
            .font(.system(size: 12))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          Text("FocusCat Companion")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
        }
        Spacer()
        Text(entry.company)
          .font(.system(size: 9.5, weight: .semibold))
          .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
      }

      // Middle Stage: Adorable Cat + Big Speech Bubble
      HStack(spacing: 16) {
        KawaiiCatView(pose: entry.catPose, mood: entry.catMood, size: 90)

        VStack(alignment: .leading, spacing: 6) {
          Text(entry.speechBubble)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(white: 0.95))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .cornerRadius(8)

          HStack(spacing: 8) {
            Label(entry.catMood, systemImage: "sparkles")
              .font(.system(size: 9.5, weight: .semibold))
              .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
            Label(entry.isPatrolling ? "Shield Active" : "Paused", systemImage: "shield.lefthalf.filled")
              .font(.system(size: 9.5, weight: .semibold))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          }
        }
      }
      .padding(.vertical, 4)

      Divider().background(Color.white.opacity(0.12))

      // Focus Pomodoro Timer Section
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("POMODORO FOCUS SESSION")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.secondary)
          Spacer()
          if let endTime = entry.focusEndTimeTimestamp, endTime > Date().timeIntervalSince1970 {
            Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
              .font(.system(size: 16, weight: .bold, design: .monospaced))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          } else if entry.focusSecondsRemaining > 0 {
            let m = entry.focusSecondsRemaining / 60
            let s = entry.focusSecondsRemaining % 60
            Text(String(format: "%02d:%02d", m, s))
              .font(.system(size: 16, weight: .bold, design: .monospaced))
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
          } else {
            Text("Ready to start")
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(Color(white: 0.7))
          }
        }

        // Guarded targets row
        HStack {
          Image(systemName: "hand.raised.fill")
            .font(.system(size: 10))
            .foregroundColor(.orange)
          Text("Guarded Targets: \(entry.targetAppOrDomain)")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(Color(white: 0.85))
            .lineLimit(1)
        }
      }
      .padding(10)
      .background(Color.white.opacity(0.04))
      .cornerRadius(8)

      Spacer(minLength: 0)

      // Footer hint
      HStack {
        Text("🐾 Tap to open FocusCat and pet your companion")
          .font(.system(size: 9.5))
          .foregroundColor(.secondary)
        Spacer()
      }
    }
    .padding(16)
    .background(Color(red: 0.05, green: 0.08, blue: 0.12))
  }
}

// -----------------------------------------------------------------------------
// Lock Screen Accessory Views
// -----------------------------------------------------------------------------
struct FocusCatAccessoryCircularView: View {
  let entry: FocusCatEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 1) {
        Text(entry.catEmoji)
          .font(.system(size: 16))
        if entry.focusSecondsRemaining > 0 {
          let m = entry.focusSecondsRemaining / 60
          Text("\(m)m")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
        } else {
          Text("🐾")
            .font(.system(size: 9))
        }
      }
    }
  }
}

struct FocusCatAccessoryRectangularView: View {
  let entry: FocusCatEntry

  var body: some View {
    HStack(spacing: 8) {
      Text(entry.catEmoji)
        .font(.system(size: 20))
      VStack(alignment: .leading, spacing: 2) {
        Text("FocusCat · \(entry.catMood)")
          .font(.system(size: 11, weight: .bold))
        if let endTime = entry.focusEndTimeTimestamp, endTime > Date().timeIntervalSince1970 {
          Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
        } else {
          Text(entry.speechBubble)
            .font(.system(size: 10))
            .lineLimit(1)
        }
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Root Widget Definition
// -----------------------------------------------------------------------------
public struct FocusCatHomeScreenWidget: Widget {
  public let kind: String = "FocusCatHomeScreenWidget"

  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FocusCatTimelineProvider()) { entry in
      FocusCatWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("FocusCat Companion")
    .description("Keep your adorable kawaii FocusCat companion and focus status right on your Home Screen!")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .systemLarge,
      .accessoryCircular,
      .accessoryRectangular
    ])
  }
}

struct FocusCatWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  let entry: FocusCatEntry

  var body: some View {
    switch family {
    case .systemSmall:
      FocusCatSmallWidgetView(entry: entry)
    case .systemMedium:
      FocusCatMediumWidgetView(entry: entry)
    case .systemLarge:
      FocusCatLargeWidgetView(entry: entry)
    case .accessoryCircular:
      FocusCatAccessoryCircularView(entry: entry)
    case .accessoryRectangular:
      FocusCatAccessoryRectangularView(entry: entry)
    default:
      FocusCatSmallWidgetView(entry: entry)
    }
  }
}
