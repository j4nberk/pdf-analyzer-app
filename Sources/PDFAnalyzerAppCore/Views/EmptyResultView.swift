import SwiftUI

struct EmptyResultView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        StudySmartEmptyCard(
            icon: icon,
            title: title,
            subtitle: subtitle
        )
    }
}
