// COPY of CrowsflightWidget./DialView.swift — the widget owns the canonical dial rendering.
// Pure SwiftUI over RenderModel, compiles unchanged on watchOS. Keep the two in sync.


import SwiftUI

struct DialView: View {
    let model: RenderModel
    let underlayRadius: CGFloat

    static func underlayRadius(for size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.24
    }

    private let cone = Color(red: 1, green: 1, blue: 0)
    private let blue = Color(red: 0, green: 0.73, blue: 1)
    private let red = Color(red: 0.85, green: 0.12, blue: 0.12)
    private let field = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF9/255)

    var body: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let u = underlayRadius
            let r = u * 1.583                 // ring radius
            let t = u * 0.333                 // arc thickness
            let coneR = hypot(geo.size.width, geo.size.height) // reach past edges
            let heading = model.headingDegrees                 // 0 = north-up; else course-up
            ZStack {
                // 1. Cone wedge → destination bearing relative to travel direction.
                ConeShape(halfAngleDegrees: model.spreadDegrees, radius: coneR)
                    .fill(cone.opacity(0.7))
                    .rotationEffect(.degrees(model.bearingDegrees - heading), anchor: .center)
                    .opacity(model.isStale ? 0.5 : 1)
                // 2. Thin track ring.
                Circle().stroke(blue, lineWidth: 1).frame(width: r * 2, height: r * 2)
                // 3. Thick distance arc (fixed gauge): from the top, sweeping the same
                //    length and direction as the app — `progress` degrees, counterclockwise.
                Circle()
                    .trim(from: 0, to: CGFloat(model.progress / 360))
                    .stroke(blue, style: StrokeStyle(lineWidth: t, lineCap: .butt))
                    .frame(width: r * 2, height: r * 2)
                    .rotationEffect(.degrees(-90))   // start at 12 o'clock
                    .scaleEffect(x: -1, y: 1)         // sweep counterclockwise like the app
                    .opacity(model.isStale ? 0.4 : 1)
                // 4. North indicator: a long red tick from the ring toward center (its
                //    inner half hidden by the white circle) with the N at the outer end.
                //    Rotates rigidly to true north, so N flips upside down pointing down.
                ZStack {
                    Path { p in
                        p.move(to: CGPoint(x: c.x, y: c.y - (r + t / 2)))
                        p.addLine(to: CGPoint(x: c.x, y: c.y))
                    }
                    .stroke(Color(white: 0.55), lineWidth: 0.75)
                    Text("N").font(.system(size: max(9, u * 0.22), weight: .bold))
                        .foregroundColor(red)
                        .position(x: c.x, y: c.y - (r + t / 2) - u * 0.22)
                }
                .rotationEffect(.degrees(-heading), anchor: .center)
                // 5. White underlay masks the cone + the tick's inner half behind the readout.
                Circle().fill(field).frame(width: u * 2, height: u * 2)
            }
        }
    }
}

/// Filled wedge with apex at center, opening straight up, given half-angle.
struct ConeShape: Shape {
    let halfAngleDegrees: Double
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let half = CGFloat(halfAngleDegrees) * .pi / 180
        // "Up" is -90° in screen coords; edges are ±half around it.
        let start = -CGFloat.pi / 2 - half
        let end = -CGFloat.pi / 2 + half
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: radius, startAngle: .radians(Double(start)),
                 endAngle: .radians(Double(end)), clockwise: false)
        p.closeSubpath()
        return p
    }
}
