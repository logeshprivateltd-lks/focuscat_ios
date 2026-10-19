import ActivityKit
import WidgetKit
import SwiftUI

public struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {
    public var appGroupId: String?
    public var updateId: Double?

    public init(appGroupId: String? = nil, updateId: Double? = nil) {
      self.appGroupId = appGroupId
      self.updateId = updateId
    }
  }

  public var id: UUID

  public init(id: UUID = UUID()) {
    self.id = id
  }
}

// Extracted payload helper from shared App Group UserDefaults
struct FocusCatLiveState {
  let catPose: String
  let catEmoji: String
  let statusText: String
  let title: String
  let remainingSeconds: Int
  let endTimeTimestamp: Double?
  let isPatrolling: Bool
  let targetAppOrDomain: String

  init(context: ActivityViewContext<LiveActivitiesAppAttributes>) {
    let appGroup = context.state.appGroupId ?? "group.com.lks.focuscat"
    let defaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
    let prefix = "\(context.attributes.id)"

    self.catPose = defaults.string(forKey: "\(prefix)_catPose") ?? defaults.string(forKey: "catPose") ?? "sit"
    self.catEmoji = defaults.string(forKey: "\(prefix)_catEmoji") ?? defaults.string(forKey: "catEmoji") ?? "🐱"
    self.statusText = defaults.string(forKey: "\(prefix)_statusText") ?? defaults.string(forKey: "statusText") ?? "FocusCat is on patrol 🐾"
    self.title = defaults.string(forKey: "\(prefix)_title") ?? defaults.string(forKey: "title") ?? "Focus Session"
    self.remainingSeconds = defaults.integer(forKey: "\(prefix)_remainingSeconds")
    let end = defaults.double(forKey: "\(prefix)_endTimeTimestamp")
    self.endTimeTimestamp = end > 0 ? end : nil
    self.isPatrolling = defaults.object(forKey: "\(prefix)_isPatrolling") as? Bool ?? true
    self.targetAppOrDomain = defaults.string(forKey: "\(prefix)_targetAppOrDomain") ?? defaults.string(forKey: "targetAppOrDomain") ?? ""
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
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let state = FocusCatLiveState(context: context)
      // Lock screen banner UI
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(Color(red: 0.1, green: 0.14, blue: 0.2))
            .frame(width: 48, height: 48)
          Text(state.catEmoji)
            .font(.system(size: 26))
        }

        VStack(alignment: .leading, spacing: 3) {
          HStack {
            Text(state.title)
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(.white)
            Spacer()
            if let endTime = state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
              Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            } else if state.remainingSeconds > 0 {
              Text(formatSeconds(state.remainingSeconds))
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            }
          }

          Text(state.statusText)
            .font(.system(size: 12))
            .foregroundColor(Color(white: 0.8))
            .lineLimit(1)

          if !state.targetAppOrDomain.isEmpty {
            HStack {
              Text("Shielding:")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
              Text(state.targetAppOrDomain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
            }
          }
        }
      }
      .padding(14)
      .background(Color(red: 0.05, green: 0.07, blue: 0.1))
    } dynamicIsland: { context in
      let state = FocusCatLiveState(context: context)
      return DynamicIsland {
        // Expanded View: When long-pressed / expanded
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            Text(state.catEmoji)
              .font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
              Text("FocusCat")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
              Text(state.catPose.uppercased())
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
            if let endTime = state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
              Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.98, green: 0.74, blue: 0.14))
            } else if state.remainingSeconds > 0 {
              Text(formatSeconds(state.remainingSeconds))
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            } else {
              Text("PATROL")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            }
            Text(state.isPatrolling ? "ON PATROL" : "SNOOZED")
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
            Text(state.statusText)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)
              .lineLimit(1)
            Spacer()
            if !state.targetAppOrDomain.isEmpty {
              Text(state.targetAppOrDomain)
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
          Text(state.catEmoji)
            .font(.system(size: 14))
        }
      } compactTrailing: {
        // Compact Trailing: Live timer or remaining seconds
        if let endTime = state.endTimeTimestamp, endTime > Date().timeIntervalSince1970 {
          Text(timerInterval: Date()...Date(timeIntervalSince1970: endTime), countsDown: true)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            .frame(width: 44)
        } else if state.remainingSeconds > 0 {
          Text(formatSeconds(state.remainingSeconds))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(red: 0.29, green: 0.87, blue: 0.50))
            .frame(width: 44)
        } else {
          Text("🐾")
            .font(.system(size: 11))
        }
      } minimal: {
        Text(state.catEmoji)
          .font(.system(size: 12))
      }
    }
  }
}
