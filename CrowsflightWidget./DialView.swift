//
//  DialView.swift
//  CrowsflightWidget
//
//  Draws the Crowsflight dial: yellow bearing cone → white underlay circle →
//  blue track ring → blue distance arc → North tick. Text is overlaid by the entry view.
//

import SwiftUI

struct DialView: View {
    let model: RenderModel
    let underlayRadius: CGFloat

    static func underlayRadius(for size: CGSize) -> CGFloat {
        min(size.width, size.height) * 0.24
    }

    private let cone = Color(red: 1, green: 1, blue: 0)
    private let blue = Color(red: 0, green: 0.73, blue: 1)
    private let field = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF9/255)

    var body: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let u = underlayRadius
            let r = u * 1.583                 // ring radius
            let t = u * 0.333                 // arc thickness
            let coneR = hypot(geo.size.width, geo.size.height) // reach past edges
            let heading = model.headingDegrees                 // 0 = north-up; else course-up
            let nAngle = -heading * .pi / 180                  // north's angle from the top
            let nRadius = r + t / 2 + u * 0.30
            ZStack {
                // 1. Cone wedge → destination bearing relative to travel direction.
                ConeShape(halfAngleDegrees: model.spreadDegrees, radius: coneR)
                    .fill(cone.opacity(0.7))
                    .rotationEffect(.degrees(model.bearingDegrees - heading), anchor: .center)
                    .opacity(model.isStale ? 0.5 : 1)
                // 2. White underlay masks the cone behind the readout.
                Circle().fill(field).frame(width: u * 2, height: u * 2)
                // 3. Thin track ring.
                Circle().stroke(blue, lineWidth: 1).frame(width: r * 2, height: r * 2)
                // 4. Thick distance arc (fixed gauge). Mirrored to sweep like the app.
                ProgressArc(sweptDegrees: model.sweptDegrees)
                    .stroke(blue, style: StrokeStyle(lineWidth: t, lineCap: .butt))
                    .frame(width: r * 2, height: r * 2)
                    .scaleEffect(x: -1, y: 1)
                    .opacity(model.isStale ? 0.4 : 1)
                // 5. North indicator: tick rotates around the ring to point at true north.
                Path { p in
                    p.move(to: CGPoint(x: c.x, y: c.y - r - t / 2))
                    p.addLine(to: CGPoint(x: c.x, y: c.y - r + t / 2))
                }
                .stroke(blue, lineWidth: 1)
                .rotationEffect(.degrees(-heading), anchor: .center)
                // N label stays upright, positioned around the ring at north.
                Text("N").font(.system(size: max(9, u * 0.18), weight: .semibold))
                    .foregroundColor(blue)
                    .position(x: c.x + nRadius * CGFloat(sin(nAngle)),
                              y: c.y - nRadius * CGFloat(cos(nAngle)))
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

/// Arc starting at the top tick, sweeping clockwise by `sweptDegrees`.
struct ProgressArc: Shape {
    let sweptDegrees: Double
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start = Angle.degrees(-90)
        let end = Angle.degrees(-90 + sweptDegrees)
        var p = Path()
        p.addArc(center: c, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return p
    }
}
