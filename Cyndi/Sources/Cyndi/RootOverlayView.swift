import SwiftUI

struct RootOverlayView: View {
    @ObservedObject var store: Store
    var bandHeight: CGFloat
    var onTapDot: (UUID) -> Void
    var onDelete: () -> Void
    var onDimClick: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            if store.isOpen {
                Ink.dimColor
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onDimClick() }

                EditorView(store: store, bandHeight: bandHeight, onDelete: onDelete)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            DotsView(store: store, onTapNote: onTapDot)
                .frame(height: bandHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
