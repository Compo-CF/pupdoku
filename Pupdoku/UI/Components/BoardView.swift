import SwiftUI

/// The full N×N board. Cells are filled by region color; thin lines separate all
/// cells and bold lines trace the boundaries between different regions.
struct BoardView: View {
    let session: QueensSession
    let appearance: BoardAppearance
    let onTapCell: (Int) -> Void

    private var n: Int { session.n }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(n)
            ZStack(alignment: .topLeading) {
                ForEach(0..<n, id: \.self) { row in
                    ForEach(0..<n, id: \.self) { col in
                        let flat = row * n + col
                        CellView(session: session, flat: flat, appearance: appearance) { onTapCell(flat) }
                            .frame(width: cell, height: cell)
                            .position(x: cell * CGFloat(col) + cell / 2, y: cell * CGFloat(row) + cell / 2)
                    }
                }
                ThinGrid(n: n).stroke(Palette.line, lineWidth: 1).frame(width: side, height: side)
                RegionBorders(regionOf: session.puzzle.regionOf, n: n)
                    .stroke(Palette.lineBold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(width: side, height: side)
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.lineBold, lineWidth: 3))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ThinGrid: Shape {
    let n: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cw = rect.width / CGFloat(n), ch = rect.height / CGFloat(n)
        for i in 1..<n {
            let x = cw * CGFloat(i)
            p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height))
            let y = ch * CGFloat(i)
            p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return p
    }
}

/// Bold segments only where two adjacent cells belong to different regions.
private struct RegionBorders: Shape {
    let regionOf: [Int]
    let n: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cw = rect.width / CGFloat(n), ch = rect.height / CGFloat(n)
        for r in 0..<n {
            for c in 0..<n {
                let region = regionOf[r * n + c]
                // Right edge
                if c + 1 < n, regionOf[r * n + (c + 1)] != region {
                    let x = cw * CGFloat(c + 1)
                    p.move(to: CGPoint(x: x, y: ch * CGFloat(r)))
                    p.addLine(to: CGPoint(x: x, y: ch * CGFloat(r + 1)))
                }
                // Bottom edge
                if r + 1 < n, regionOf[(r + 1) * n + c] != region {
                    let y = ch * CGFloat(r + 1)
                    p.move(to: CGPoint(x: cw * CGFloat(c), y: y))
                    p.addLine(to: CGPoint(x: cw * CGFloat(c + 1), y: y))
                }
            }
        }
        return p
    }
}
