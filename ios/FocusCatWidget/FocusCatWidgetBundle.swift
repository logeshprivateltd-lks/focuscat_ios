import WidgetKit
import SwiftUI

@main
struct FocusCatWidgetBundle: WidgetBundle {
  var body: some Widget {
    FocusCatHomeScreenWidget()
    if #available(iOS 16.1, *) {
      FocusCatLiveActivityWidget()
    }
  }
}
