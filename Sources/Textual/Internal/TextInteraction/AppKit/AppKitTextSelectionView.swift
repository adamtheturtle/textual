#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionView` renders selection highlights for a single `Text.Layout`.
  //
  // Each text fragment provides its own resolved layout and origin. The view reads the shared
  // `TextSelectionModel` from the environment, computes selection rectangles for the current
  // range within this layout, and paints them in a `Canvas` behind the text.

  struct AppKitTextSelectionView: View {
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
    @State private var selectionRects: [TextSelectionRect] = []

    private let layout: Text.Layout
    private let origin: CGPoint

    init(layout: Text.Layout, origin: CGPoint) {
      self.layout = layout
      self.origin = origin
    }

    var body: some View {
      Group {
        if selectionRects.isEmpty {
          Color.clear
        } else {
          Canvas { context, _ in
            context.translateBy(x: origin.x, y: origin.y)
            for selectionRect in selectionRects {
              context.fill(
                Path(selectionRect.rect.integral),
                with: .color(.init(nsColor: .selectedTextBackgroundColor))
              )
            }
          }
        }
      }
      // A single handler keyed on both inputs. Registering one `onChange` per input
      // meant both could fire on the same frame (both use `initial: true`), each
      // writing `selectionRects` — which SwiftUI flags as "onChange(of: Layout)
      // action tried to update multiple times per frame".
      .onChange(
        of: SelectionInput(selectedRange: textSelectionModel?.selectedRange, layout: layout),
        initial: true,
        updateSelectionRects
      )
    }

    /// The inputs `updateSelectionRects` reads, combined so a change to either drives
    /// a single state update per frame.
    private struct SelectionInput: Equatable {
      let selectedRange: TextRange?
      let layout: Text.Layout
    }

    private func updateSelectionRects() {
      if let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange
      {
        selectionRects = textSelectionModel.selectionRects(for: selectedRange, layout: layout)
      } else {
        selectionRects = []
      }
    }
  }
#endif
