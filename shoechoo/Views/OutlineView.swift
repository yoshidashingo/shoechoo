import SwiftUI

struct OutlineView: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        List {
            Section("Outline") {
                if viewModel.headings.isEmpty {
                    Text("No headings")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.headings) { heading in
                        Button(action: { scrollToHeading(heading) }) {
                            Text(heading.title)
                                .font(fontForLevel(heading.level))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, CGFloat((heading.level - 1) * 12))
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .headline
        case 2: return .subheadline
        default: return .body
        }
    }

    private func scrollToHeading(_ heading: HeadingItem) {
        NotificationCenter.default.post(
            name: .scrollToPosition,
            object: nil,
            userInfo: ["position": heading.position]
        )
    }
}
