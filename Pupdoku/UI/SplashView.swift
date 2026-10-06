import SwiftUI

/// A short animated splash shown over the app at launch (and while startup work
/// runs). The corgi logo pops in, the wordmark and tagline rise, a row of paw
/// prints trails in, then it calls `onFinished` so RootView can fade to Home.
/// iOS launch screens can't animate, so this runs in-app on top of everything.
struct SplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoIn = false
    @State private var textIn = false
    @State private var pawsIn = false
    @State private var ringPulse = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bgTop, Palette.bgBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    // Soft pulsing halo behind the pup.
                    Circle()
                        .fill(Palette.accent.opacity(0.18))
                        .frame(width: 180, height: 180)
                        .scaleEffect(ringPulse ? 1.12 : 0.88)
                        .opacity(logoIn ? 1 : 0)

                    Image("breed_corgi")
                        .resizable().scaledToFit()
                        .frame(width: 132, height: 132)
                        .shadow(color: Palette.brandShadow.opacity(0.35), radius: 14, y: 8)
                        .scaleEffect(logoIn ? 1 : 0.4)
                        .rotationEffect(.degrees(logoIn || reduceMotion ? 0 : -12))
                        .opacity(logoIn ? 1 : 0)
                }

                VStack(spacing: 4) {
                    Text("Pupdoku")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.ink)
                    Text("Find the hidden puppies")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.inkSoft)
                }
                .offset(y: textIn ? 0 : 14)
                .opacity(textIn ? 1 : 0)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { i in
                        PawMark()
                            .fill(Palette.accentDeep.opacity(0.55))
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(i.isMultiple(of: 2) ? -8 : 8))
                            .opacity(pawsIn ? 1 : 0)
                            .offset(y: pawsIn ? 0 : 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6)
                                .delay(0.5 + Double(i) * 0.08), value: pawsIn)
                    }
                }
                .padding(.top, 6)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { logoIn = true; textIn = true; pawsIn = true }
        } else {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { logoIn = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.22)) { textIn = true }
            pawsIn = true
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { ringPulse = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { onFinished() }
    }
}

/// A simple four-toe paw-print shape.
private struct PawMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Main pad.
        p.addEllipse(in: CGRect(x: w * 0.28, y: h * 0.5, width: w * 0.44, height: h * 0.42))
        // Toes.
        let toe = w * 0.2
        for (tx, ty) in [(0.08, 0.26), (0.34, 0.08), (0.58, 0.08), (0.74, 0.26)] {
            p.addEllipse(in: CGRect(x: w * tx, y: h * ty, width: toe, height: toe * 1.15))
        }
        return p
    }
}
