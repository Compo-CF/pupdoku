import SwiftUI

/// The app-wide illustrated backdrop. Replaces the old flat two-color gradient
/// with a layered, hand-illustrated meadow: a warm sky, a soft sun glow, rolling
/// grassy hills, and a sprinkle of faint floating bones and paw prints.
///
/// Everything is drawn procedurally (vector `Canvas` + `Path`), so it scales
/// crisply to any device, adds zero asset weight, and never distorts across
/// aspect ratios. Motifs are deliberately low-contrast so they decorate without
/// ever competing with the puzzle board or controls that sit on top. All motion
/// is omitted (static), so it's safe under Reduce Motion by construction.
struct PupBackground: View {
    /// Fixed pseudo-random motif placements, expressed as fractions of the
    /// drawable size so the scene composes the same on every screen. Seeded by
    /// hand (not an RNG) so the layout is deterministic and art-directed.
    private static let paws: [Motif] = [
        Motif(x: 0.12, y: 0.16, scale: 0.9, angle: -18),
        Motif(x: 0.82, y: 0.11, scale: 0.7, angle: 22),
        Motif(x: 0.68, y: 0.30, scale: 0.55, angle: -8),
        Motif(x: 0.22, y: 0.42, scale: 0.6, angle: 30),
        Motif(x: 0.90, y: 0.52, scale: 0.8, angle: -24),
        Motif(x: 0.08, y: 0.63, scale: 0.65, angle: 14),
        Motif(x: 0.46, y: 0.20, scale: 0.5, angle: 40),
    ]
    private static let bones: [Motif] = [
        Motif(x: 0.78, y: 0.22, scale: 1.0, angle: -20),
        Motif(x: 0.17, y: 0.30, scale: 0.8, angle: 28),
        Motif(x: 0.58, y: 0.46, scale: 0.7, angle: -12),
        Motif(x: 0.30, y: 0.56, scale: 0.9, angle: 18),
    ]

    struct Motif { let x, y, scale, angle: CGFloat }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // 1 — warm sky base.
                LinearGradient(colors: [Palette.bgTop, Palette.bgBottom],
                               startPoint: .top, endPoint: .bottom)

                // 2 — soft sun glow, upper area.
                Canvas { ctx, s in
                    let center = CGPoint(x: s.width * 0.78, y: s.height * 0.10)
                    let radius = max(s.width, s.height) * 0.75
                    let glow = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                      width: radius * 2, height: radius * 2))
                    ctx.fill(glow, with: .radialGradient(
                        Gradient(colors: [Palette.accentBright.opacity(0.22), .clear]),
                        center: center, startRadius: 0, endRadius: radius))
                }

                // 3 — faint floating motifs (bones + paw prints).
                Canvas { ctx, s in
                    for m in Self.bones {
                        let p = bonePath(scale: 26 * m.scale)
                            .applying(transform(m, in: s))
                        ctx.fill(p, with: .color(Palette.accentDeep.opacity(0.10)))
                    }
                    for m in Self.paws {
                        let p = pawPath(scale: 20 * m.scale)
                            .applying(transform(m, in: s))
                        ctx.fill(p, with: .color(Palette.lineBold.opacity(0.055)))
                    }
                }

                // 4 — rolling hills along the bottom.
                hills(in: size)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    // MARK: - Hills

    @ViewBuilder
    private func hills(in size: CGSize) -> some View {
        let w = size.width, h = size.height
        ZStack(alignment: .bottom) {
            hill(w: w, h: h, baseline: 0.86, crest: 0.055, phase: 0.0)
                .fill(Palette.accent.opacity(0.12))
            hill(w: w, h: h, baseline: 0.92, crest: 0.045, phase: 0.6)
                .fill(Palette.accentDeep.opacity(0.14))
            hill(w: w, h: h, baseline: 0.97, crest: 0.03, phase: 0.2)
                .fill(Palette.brandShadow.opacity(0.10))
        }
        .allowsHitTesting(false)
    }

    /// One smooth rolling-hill band. `baseline` is where the crest sits (fraction
    /// of height from the top); `crest` is the wave amplitude; `phase` shifts the
    /// wave sideways so stacked hills don't align.
    private func hill(w: CGFloat, h: CGFloat, baseline: CGFloat,
                      crest: CGFloat, phase: CGFloat) -> Path {
        var path = Path()
        let baseY = h * baseline
        let amp = h * crest
        let step = w / 6
        path.move(to: CGPoint(x: 0, y: baseY))
        var x: CGFloat = 0
        var up = true
        while x < w {
            let nextX = x + step
            let ctrlX = x + step / 2
            let ctrlY = baseY + (up ? -amp : amp) - amp * phase * 0.3
            path.addQuadCurve(to: CGPoint(x: nextX, y: baseY),
                              control: CGPoint(x: ctrlX, y: ctrlY))
            x = nextX
            up.toggle()
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }

    // MARK: - Motif geometry (built at origin, placed via `transform`)

    private func transform(_ m: Motif, in s: CGSize) -> CGAffineTransform {
        CGAffineTransform(translationX: s.width * m.x, y: s.height * m.y)
            .rotated(by: m.angle * .pi / 180)
    }

    /// A dog paw: one large pad plus four toe beans, centered on the origin.
    private func pawPath(scale: CGFloat) -> Path {
        var p = Path()
        p.addEllipse(in: CGRect(x: -0.9 * scale, y: 0.1 * scale,
                                width: 1.8 * scale, height: 1.5 * scale))
        let toes: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.85, -0.9, 0.42), (-0.3, -1.25, 0.46),
            (0.3, -1.25, 0.46), (0.85, -0.9, 0.42),
        ]
        for (tx, ty, r) in toes {
            p.addEllipse(in: CGRect(x: tx * scale - r * scale, y: ty * scale - r * scale,
                                    width: r * 2 * scale, height: r * 2 * scale))
        }
        return p
    }

    /// A simple dog bone: two lobes at each end joined by a bar, centered on origin.
    private func bonePath(scale: CGFloat) -> Path {
        var p = Path()
        let len = 2.2 * scale
        let lobe = 0.55 * scale
        let barH = 0.5 * scale
        p.addRoundedRect(in: CGRect(x: -len / 2, y: -barH / 2, width: len, height: barH),
                         cornerSize: CGSize(width: barH / 2, height: barH / 2))
        for sx in [-1.0, 1.0] {
            let cx = sx * len / 2
            p.addEllipse(in: CGRect(x: cx - lobe, y: -barH / 2 - lobe * 0.7,
                                    width: lobe * 1.5, height: lobe * 1.5))
            p.addEllipse(in: CGRect(x: cx - lobe, y: barH / 2 - lobe * 0.8,
                                    width: lobe * 1.5, height: lobe * 1.5))
        }
        return p
    }
}

#Preview {
    VStack { Spacer() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PupBackground())
}
