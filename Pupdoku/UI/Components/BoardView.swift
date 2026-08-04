import SwiftUI

/// The full puzzle grid. Lays out `order × order` cells and overlays thin cell
/// separators plus bold box-boundary lines and an outer frame.
struct BoardView: View {
    let session: PuzzleSession
    let appearance: BoardAppearance
    let onTapCell: (Int) -> Void

    private var order: Int { session.order }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(order)
            ZStack(alignment: .topLeading) {
                ForEach(0..<order, id: \.self) { row in
                    ForEach(0..<order, id: \.self) { col in
                        let flat = row * order + col
                        CellView(session: session, flat: flat, appearance: appearance) {
                            onTapCell(flat)
                        }
                        .frame(width: cell, height: cell)
                        .position(x: cell * CGFloat(col) + cell / 2,
                                  y: cell * CGFloat(row) + cell / 2)
                    }
                }
                BoardLines(order: order,
                           boxRows: session.working.boxRows,
                           boxCols: session.working.boxCols)
                    .stroke(Palette.line, lineWidth: 1)
                    .frame(width: side, height: side)
                BoardBoxLines(order: order,
                              boxRows: session.working.boxRows,
                              boxCols: session.working.boxCols)
                    .stroke(Palette.lineBold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: side, height: side)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Palette.lineBold, lineWidth: 2.5)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Thin lines between every row / column.
private struct BoardLines: Shape {
    let order: Int, boxRows: Int, boxCols: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cw = rect.width / CGFloat(order)
        let ch = rect.height / CGFloat(order)
        for i in 1..<order {
            let x = cw * CGFloat(i)
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height))
            let y = ch * CGFloat(i)
            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return p
    }
}

/// Bold lines only on box boundaries.
private struct BoardBoxLines: Shape {
    let order: Int, boxRows: Int, boxCols: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cw = rect.width / CGFloat(order)
        let ch = rect.height / CGFloat(order)
        // Vertical box separators at multiples of boxCols.
        var c = boxCols
        while c < order {
            let x = cw * CGFloat(c)
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height))
            c += boxCols
        }
        // Horizontal box separators at multiples of boxRows.
        var r = boxRows
        while r < order {
            let y = ch * CGFloat(r)
            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y))
            r += boxRows
        }
        return p
    }
}
