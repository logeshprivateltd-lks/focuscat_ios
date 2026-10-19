import WidgetKit
import SwiftUI

@main
struct FocusCatWidgetBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.1, *) {
      FocusCatLiveActivityWidget()
    }
  }
}
