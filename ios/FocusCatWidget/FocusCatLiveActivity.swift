import ActivityKit
import WidgetKit
import SwiftUI

public struct FocusCatLiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias FocusCatLiveActivitiesAppStatus = ContentState

  public struct ContentState: Codable, Hashable {
    public var catPose: String
    public var catEmoji: String
    public var statusText: String
    public var title: String
    public var remainingSeconds: Int
    public var endTimeTimestamp: Double?
    public var isPatrolling: Bool
    public var targetAppOrDomain: String
    
    public init(
      catPose: String = "sit",
      catEmoji: String = "🐱",
      statusText: String = "FocusCat is on patrol 🐾",
      title: String = "Focus Session",
      remainingSeconds: Int = 0,
      endTimeTimestamp: Double? = nil,
      isPatrolling: Bool = true,
      targetAppOrDomain: String = ""
    ) {
      self.catPose = catPose
      self.catEmoji = catEmoji
      self.statusText = statusText
      self.title = title
      self.remainingSeconds = remainingSeconds
      self.endTimeTimestamp = endTimeTimestamp
      self.isPatrolling = isPatrolling
      self.targetAppOrDomain = targetAppOrDomain
    }
  }

  public var id = UUID()
  public var name: String

  public init(name: String = "FocusCat") {
    self.name = name
  }
}

func formatSeconds(_ totalSeconds: Int) -> String {
  let m = totalSeconds / 60
  let s = totalSeconds % 60
  return String(format: "%02d:%02d", m, s)
}

@available(iOS 16.1, *)
struct FocusCatLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FocusCatLiveActivitiesAppAttributes.self) { context in
      // Lock screen banner UI
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color(red: 0.1, green: 0.14, blue: 0.2))
            .frame(width: 48, height: 48)
          Text(context.state.catEmoji)
            .font(.system(size: 26))
        }

        VStack(alignment: .leading, spacing: 3) {
          HStack {
            Text(context.state.title)
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.white)
            Spacer()
            if let endTime = context.state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
              Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            } else if context.state.remainingSeconds > 0 {
              Text(formatSeconds(context.state.remainingSeconds))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            }
          }

          Text(context.state.statusText)
            .font(.system(size: 12))
            .foregroundColor(Color(white: 0.8))
            .lineLimit(1)

          if !context.state.targetAppOrDomain.isEmpty {
            HStack {
              Text("Shielding:")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
              Text(context.state.targetAppOrDomain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
            }
          }
        }
      }
      .padding(14)
      .background(Color(red: 0.05, green: 0.07, blue: 0.1))
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded View: When long-pressed / expanded
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            Text(context.state.catEmoji)
              .font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
              Text("FocusCat")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
              Text(context.state.catPose.uppercased())
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.2))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
                .cornerRadius(4)
            }
          }
          .padding(.leading, 8)
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            if let endTime = context.state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
              Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
            } else if context.state.remainingSeconds > 0 {
              Text(formatSeconds(context.state.remainingSeconds))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            } else {
              Text("PATROL")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            }
            Text(context.state.isPatrolling ? "ON PATROL" : "SNOOZED")
              .font(.system(size: 9, weight: .semibold))
              .foregroundColor(.secondary)
          }
          .padding(.trailing, 8)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack {
            Image(systemName: "shield.fill")
              .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
              .font(.system(size: 11))
            Text(context.state.statusText)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)
              .lineLimit(1)
            Spacer()
            if !context.state.targetAppOrDomain.isEmpty {
              Text(context.state.targetAppOrDomain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.12))
                .cornerRadius(4)
                .foregroundColor(.white)
            }
          }
          .padding(.horizontal, 10)
          .padding(.top, 4)
        }
      } compactLeading: {
        // Compact Leading: Kawaii cat sprite / emoji + pose
        HStack(spacing: 3) {
          Text(context.state.catEmoji)
            .font(.system(size: 14))
        }
      } compactTrailing: {
        // Compact Trailing: Live timer or remaining seconds
        if let endTime = context.state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
          Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            .frame(width: 44)
        } else if context.state.remainingSeconds > 0 {
          Text(formatSeconds(context.state.remainingSeconds))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            .frame(width: 44)
        } else {
          Text("🐾")
            .font(.system(size: 11))
        }
      } minimal: {
        Text(context.state.catEmoji)
          .font(.system(size: 12))
      }
    }
  }
}
