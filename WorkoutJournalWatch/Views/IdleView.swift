import SwiftUI
import WatchKit

struct IdleView: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 48, weight: .regular))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                WKInterfaceDevice.current().play(.click)
            }
            .ignoresSafeArea()
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    IdleView()
}
