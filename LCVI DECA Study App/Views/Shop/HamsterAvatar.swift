//
//  HamsterAvatar.swift
//  LCVI DECA Study App
//
//  The hamster, drawn as vectors rather than shipped as art.
//
//  Every coordinate below is normalised 0...1 with y running down, then scaled
//  into whatever rect the view is given, so the same numbers hold at 64pt in a
//  shop tile and at 260pt on the customise screen. Nothing here is an image
//  asset: a PNG set would need @2x/@3x for every combination of hair, hat,
//  facial hair, earrings and chain, which is a combinatorial explosion, and
//  vectors also let an item take its own tint from the catalogue.
//
//  The layout was derived by drawing it: head ellipse centred (0.5, 0.56) at
//  0.80 x 0.70, so the face spans y 0.21...0.91, and the eyes sit at y 0.545.
//  That last number is why every hair style stops at y 0.46 — the first
//  version drew the cap over the eyes and the hamster looked blindfolded.
//

import SwiftUI

// MARK: - Geometry

/// Shared measurements. Anything positioned against the face reads from here
/// rather than repeating a magic number, so nudging the head moves the hats.
private enum H {
    static let headCenter = CGPoint(x: 0.5, y: 0.56)
    static let headSize   = CGSize(width: 0.80, height: 0.70)
    static var headTop: CGFloat { headCenter.y - headSize.height / 2 }   // 0.21

    /// Hair and hats stop here — above the eyes.
    static let browLine: CGFloat = 0.46

    static let earCenters: [CGFloat] = [0.265, 0.735]
    static let earY: CGFloat = 0.235
    static let earSize: CGFloat = 0.235

    static let eyeCenters: [CGFloat] = [0.375, 0.625]
    static let eyeY: CGFloat = 0.545
}

private extension CGRect {
    /// Normalised box → view coordinates.
    func box(_ cx: CGFloat, _ cy: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: minX + (cx - w / 2) * width,
               y: minY + (cy - h / 2) * height,
               width: w * width,
               height: h * height)
    }
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: minX + x * width, y: minY + y * height)
    }
}

/// Half of an ellipse, built from a unit arc and then scaled into the box.
///
/// The obvious implementation is `addEllipse` intersected with a rectangle,
/// and `Path.intersection` is iOS 17 — this app's floor is 16.4, so it is not
/// available. Transforming a unit semicircle costs nothing and works
/// everywhere.
///
/// Angles read oddly because SwiftUI's y axis points down: 270° is straight
/// *up*, so the top half is the sweep 180° → 360°.
private struct HalfEllipse: Shape {
    let cx, cy, w, h: CGFloat
    let top: Bool

    func path(in rect: CGRect) -> Path {
        let b = rect.box(cx, cy, w, h)
        guard b.width > 0, b.height > 0 else { return Path() }
        var unit = Path()
        unit.addArc(center: .zero,
                    radius: 1,
                    startAngle: .degrees(top ? 180 : 0),
                    endAngle: .degrees(top ? 360 : 180),
                    clockwise: false)
        unit.closeSubpath()
        let transform = CGAffineTransform(scaleX: b.width / 2, y: b.height / 2)
            .concatenating(CGAffineTransform(translationX: b.midX, y: b.midY))
        return unit.applying(transform)
    }
}

/// The top half — hair caps and hat crowns.
private struct Dome: Shape {
    let cx, cy, w, h: CGFloat
    func path(in rect: CGRect) -> Path {
        HalfEllipse(cx: cx, cy: cy, w: w, h: h, top: true).path(in: rect)
    }
}

/// The bottom half — beards and cheek shading.
private struct Bowl: Shape {
    let cx, cy, w, h: CGFloat
    func path(in rect: CGRect) -> Path {
        HalfEllipse(cx: cx, cy: cy, w: w, h: h, top: false).path(in: rect)
    }
}

// MARK: - Avatar

struct HamsterAvatar: View {
    var equipped: [CosmeticSlot: CosmeticItem] = [:]
    /// Draws the face only, for small shop previews where a chain would be
    /// clipped by the tile.
    var compact: Bool = false

    private let fur      = Color(lightHex: 0xC69660, darkHex: 0xB4854F)
    private let furDark  = Color(lightHex: 0xA87A48, darkHex: 0x93683C)
    private let innerEar = Color(lightHex: 0xE8B2AA, darkHex: 0xC98F87)
    private let belly    = Color(lightHex: 0xF0E1CB, darkHex: 0xDCCBB2)
    private let ink      = Color(lightHex: 0x30261C, darkHex: 0x1C160F)
    private let blush    = Color(lightHex: 0xE2968C, darkHex: 0xC57A70)

    private func item(_ slot: CosmeticSlot) -> CosmeticItem? { equipped[slot] }
    private func tint(_ item: CosmeticItem) -> Color { Color(hex: item.tintHex) }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let stroke = min(geo.size.width, geo.size.height) * 0.008

            ZStack {
                if !compact, let chain = item(.chain) { chainLayer(chain, rect) }
                ears(rect, stroke)
                if case .hair(.long)? = item(.hair)?.design { longBacking(rect) }
                if case .hair(.afro)? = item(.hair)?.design { afroBacking(rect) }
                head(rect, stroke)
                muzzleAndCheeks(rect)
                if let facial = item(.facialHair) { facialLayer(facial, rect, stroke) }
                eyes(rect)
                noseAndMouth(rect, stroke)
                whiskers(rect, stroke)
                if let ear = item(.earrings) { earringLayer(ear, rect, stroke) }
                if let hair = item(.hair) { hairLayer(hair, rect) }
                if let hat = item(.headwear) { headwearLayer(hat, rect, stroke) }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let worn = CosmeticSlot.allCases.compactMap { equipped[$0]?.name }
        return worn.isEmpty ? "Your hamster, wearing nothing yet"
                            : "Your hamster, wearing \(worn.joined(separator: ", "))"
    }

    // MARK: Face

    private func ears(_ r: CGRect, _ s: CGFloat) -> some View {
        ForEach(Array(H.earCenters.enumerated()), id: \.offset) { _, ex in
            ZStack {
                Circle().fill(furDark)
                    .frame(width: H.earSize * r.width, height: H.earSize * r.height)
                    .overlay(Circle().strokeBorder(ink, lineWidth: s))
                Circle().fill(innerEar)
                    .frame(width: 0.135 * r.width, height: 0.135 * r.height)
                    .offset(y: 0.010 * r.height)
            }
            .position(r.pt(ex, H.earY))
        }
    }

    private func head(_ r: CGRect, _ s: CGFloat) -> some View {
        Ellipse().fill(fur)
            .overlay(Ellipse().strokeBorder(ink, lineWidth: s))
            .frame(width: H.headSize.width * r.width, height: H.headSize.height * r.height)
            .position(r.pt(H.headCenter.x, H.headCenter.y))
    }

    private func muzzleAndCheeks(_ r: CGRect) -> some View {
        ZStack {
            Ellipse().fill(belly)
                .frame(width: 0.44 * r.width, height: 0.30 * r.height)
                .position(r.pt(0.5, 0.70))
            ForEach([0.215, 0.785], id: \.self) { cx in
                Ellipse().fill(blush.opacity(0.75))
                    .frame(width: 0.13 * r.width, height: 0.10 * r.height)
                    .position(r.pt(cx, 0.665))
            }
        }
    }

    private func eyes(_ r: CGRect) -> some View {
        ForEach(Array(H.eyeCenters.enumerated()), id: \.offset) { _, ex in
            ZStack {
                Ellipse().fill(ink)
                    .frame(width: 0.115 * r.width, height: 0.125 * r.height)
                Circle().fill(.white)
                    .frame(width: 0.040 * r.width, height: 0.040 * r.height)
                    .offset(x: -0.022 * r.width, y: -0.025 * r.height)
            }
            .position(r.pt(ex, H.eyeY))
        }
    }

    private func noseAndMouth(_ r: CGRect, _ s: CGFloat) -> some View {
        ZStack {
            Path { p in
                p.move(to: r.pt(0.5, 0.685))
                p.addLine(to: r.pt(0.462, 0.645))
                p.addLine(to: r.pt(0.538, 0.645))
                p.closeSubpath()
            }
            .fill(Color(lightHex: 0x5C3A34, darkHex: 0x4A2E2A))

            Path { p in
                p.addArc(center: r.pt(0.462, 0.705),
                         radius: 0.037 * r.width,
                         startAngle: .degrees(0), endAngle: .degrees(150), clockwise: false)
                p.move(to: r.pt(0.575, 0.705))
                p.addArc(center: r.pt(0.538, 0.705),
                         radius: 0.037 * r.width,
                         startAngle: .degrees(30), endAngle: .degrees(180), clockwise: false)
            }
            .stroke(ink, style: StrokeStyle(lineWidth: s, lineCap: .round))
        }
    }

    private func whiskers(_ r: CGRect, _ s: CGFloat) -> some View {
        Path { p in
            for y in [0.66, 0.70, 0.74] {
                p.move(to: r.pt(0.30, y));  p.addLine(to: r.pt(0.13, y - 0.03))
                p.move(to: r.pt(0.70, y));  p.addLine(to: r.pt(0.87, y - 0.03))
            }
        }
        .stroke(ink.opacity(0.55), style: StrokeStyle(lineWidth: s * 0.7, lineCap: .round))
    }

    // MARK: Cosmetic layers

    @ViewBuilder
    private func hairLayer(_ item: CosmeticItem, _ r: CGRect) -> some View {
        let c = tint(item)
        if case .hair(let style) = item.design {
            switch style {
            case .buzz:
                Dome(cx: 0.5, cy: H.browLine, w: 0.80, h: 0.50).fill(c)
            case .long:
                Dome(cx: 0.5, cy: H.browLine, w: 0.82, h: 0.52).fill(c)
            case .afro:
                Dome(cx: 0.5, cy: H.browLine, w: 0.84, h: 0.54).fill(c)
            case .sidePart:
                ZStack {
                    Dome(cx: 0.5, cy: H.browLine, w: 0.80, h: 0.50).fill(c)
                    // The sweep: a second dome in fur colour, offset, lifting
                    // the fringe off one side rather than sitting flat.
                    Dome(cx: 0.66, cy: 0.455, w: 0.58, h: 0.44).fill(fur)
                        .clipShape(Dome(cx: 0.5, cy: H.browLine, w: 0.80, h: 0.50))
                }
            case .dreads:
                ZStack {
                    Dome(cx: 0.5, cy: H.browLine, w: 0.80, h: 0.50).fill(c)
                    ForEach(0..<7, id: \.self) { i in
                        let t = CGFloat(i) / 6
                        let a = CGFloat.pi * (1.06 + 0.88 * t)
                        let x = 0.5 + 0.395 * cos(a)
                        let y = H.browLine + 0.245 * sin(a)
                        let drop: CGFloat = (i == 0 || i == 6) ? 0.30 : (i == 1 || i == 5 ? 0.20 : 0.12)
                        Capsule().fill(c)
                            .frame(width: 0.075 * r.width, height: (drop + 0.06) * r.height)
                            .position(r.pt(x, y + drop / 2))
                    }
                }
            case .spikes:
                ZStack {
                    Dome(cx: 0.5, cy: H.browLine, w: 0.80, h: 0.50).fill(c)
                    ForEach(0..<5, id: \.self) { i in
                        let x = 0.30 + CGFloat(i) * 0.10
                        Path { p in
                            p.move(to: r.pt(x, 0.10))
                            p.addLine(to: r.pt(x + 0.055, 0.30))
                            p.addLine(to: r.pt(x - 0.055, 0.30))
                            p.closeSubpath()
                        }
                        .fill(c)
                    }
                }
            case .mohawk:
                ZStack {
                    Path { p in
                        p.move(to: r.pt(0.5, 0.10))
                        p.addLine(to: r.pt(0.605, 0.35))
                        p.addLine(to: r.pt(0.395, 0.35))
                        p.closeSubpath()
                    }
                    .fill(Color(lightHex: 0x34343C, darkHex: 0x26262C))
                    Path { p in
                        p.move(to: r.pt(0.5, 0.145))
                        p.addLine(to: r.pt(0.567, 0.35))
                        p.addLine(to: r.pt(0.433, 0.35))
                        p.closeSubpath()
                    }
                    .fill(c)
                }
            }
        }
    }

    /// Long hair and afros need mass *behind* the head as well as a fringe in
    /// front, or they read as a cap rather than as hair.
    private func longBacking(_ r: CGRect) -> some View {
        Ellipse()
            .fill(tint(item(.hair) ?? CosmeticCatalogue.hair[2]))
            .frame(width: 0.98 * r.width, height: 0.80 * r.height)
            .position(r.pt(0.5, 0.58))
    }

    private func afroBacking(_ r: CGRect) -> some View {
        Circle()
            .fill(tint(item(.hair) ?? CosmeticCatalogue.hair[4]))
            .frame(width: 1.0 * r.width, height: 1.0 * r.height)
            .position(r.pt(0.5, 0.50))
    }

    @ViewBuilder
    private func facialLayer(_ item: CosmeticItem, _ r: CGRect, _ s: CGFloat) -> some View {
        let c = tint(item)
        if case .facialHair(let style) = item.design {
            switch style {
            case .stubble:
                Bowl(cx: 0.5, cy: 0.665, w: 0.42, h: 0.30).fill(c.opacity(0.55))
            case .moustache:
                ZStack {
                    Ellipse().fill(c)
                        .frame(width: 0.115 * r.width, height: 0.062 * r.height)
                        .position(r.pt(0.443, 0.712))
                    Ellipse().fill(c)
                        .frame(width: 0.115 * r.width, height: 0.062 * r.height)
                        .position(r.pt(0.557, 0.712))
                }
            case .goatee:
                Ellipse().fill(c)
                    .frame(width: 0.17 * r.width, height: 0.15 * r.height)
                    .position(r.pt(0.5, 0.795))
            case .muttonChops:
                ForEach([0.245, 0.755], id: \.self) { cx in
                    Capsule().fill(c)
                        .frame(width: 0.10 * r.width, height: 0.26 * r.height)
                        .position(r.pt(cx, 0.62))
                }
            case .beard:
                ZStack {
                    Bowl(cx: 0.5, cy: 0.66, w: 0.50, h: 0.44).fill(c)
                    Ellipse().fill(belly)
                        .frame(width: 0.30 * r.width, height: 0.17 * r.height)
                        .position(r.pt(0.5, 0.695))
                }
            }
        }
    }

    @ViewBuilder
    private func earringLayer(_ item: CosmeticItem, _ r: CGRect, _ s: CGFloat) -> some View {
        let c = tint(item)
        if case .earrings(let style) = item.design {
            ForEach([0.195, 0.805], id: \.self) { ex in
                switch style {
                case .studs:
                    Circle().fill(c)
                        .overlay(Circle().strokeBorder(ink.opacity(0.5), lineWidth: s * 0.5))
                        .frame(width: 0.052 * r.width, height: 0.052 * r.height)
                        .position(r.pt(ex, 0.330))
                case .hoops:
                    Circle().strokeBorder(c, lineWidth: s * 1.6)
                        .frame(width: 0.088 * r.width, height: 0.088 * r.height)
                        .position(r.pt(ex, 0.345))
                case .drops:
                    ZStack {
                        Circle().fill(c)
                            .frame(width: 0.040 * r.width, height: 0.040 * r.height)
                            .position(r.pt(ex, 0.320))
                        Capsule().fill(c)
                            .frame(width: 0.030 * r.width, height: 0.075 * r.height)
                            .position(r.pt(ex, 0.385))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chainLayer(_ item: CosmeticItem, _ r: CGRect) -> some View {
        let c = tint(item)
        if case .chain(let style) = item.design {
            let width: CGFloat = style == .thin ? 0.016 : 0.026
            ZStack {
                Path { p in
                    p.addArc(center: r.pt(0.5, 0.845),
                             radius: 0.23 * r.width,
                             startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                }
                .stroke(c, style: StrokeStyle(lineWidth: width * r.width, lineCap: .round))

                if style == .pendant {
                    Circle().fill(c)
                        .overlay(Circle().strokeBorder(ink.opacity(0.45), lineWidth: 0.006 * r.width))
                        .frame(width: 0.11 * r.width, height: 0.11 * r.height)
                        .position(r.pt(0.5, 0.945))
                }
            }
        }
    }

    @ViewBuilder
    private func headwearLayer(_ item: CosmeticItem, _ r: CGRect, _ s: CGFloat) -> some View {
        let c = tint(item)
        if case .headwear(let style) = item.design {
            switch style {
            case .cap:
                ZStack {
                    Dome(cx: 0.5, cy: 0.40, w: 0.76, h: 0.52).fill(c)
                    Capsule().fill(c.opacity(0.82))
                        .frame(width: 0.43 * r.width, height: 0.05 * r.height)
                        .position(r.pt(0.685, 0.397))
                }
            case .visor:
                ZStack {
                    Capsule().fill(c)
                        .frame(width: 0.50 * r.width, height: 0.055 * r.height)
                        .position(r.pt(0.5, 0.395))
                    Capsule().fill(c.opacity(0.85))
                        .frame(width: 0.42 * r.width, height: 0.05 * r.height)
                        .position(r.pt(0.70, 0.405))
                }
            case .beanie:
                ZStack {
                    Dome(cx: 0.5, cy: 0.415, w: 0.78, h: 0.54).fill(c)
                    Capsule().fill(c.opacity(0.8))
                        .frame(width: 0.76 * r.width, height: 0.07 * r.height)
                        .position(r.pt(0.5, 0.417))
                }
            case .headphones:
                ZStack {
                    Path { p in
                        p.addArc(center: r.pt(0.5, 0.42),
                                 radius: 0.37 * r.width,
                                 startAngle: .degrees(190), endAngle: .degrees(350), clockwise: false)
                    }
                    .stroke(c, style: StrokeStyle(lineWidth: 0.045 * r.width, lineCap: .round))
                    ForEach([0.135, 0.865], id: \.self) { ex in
                        RoundedRectangle(cornerRadius: 0.03 * r.width, style: .continuous)
                            .fill(c)
                            .frame(width: 0.11 * r.width, height: 0.17 * r.height)
                            .position(r.pt(ex, 0.44))
                    }
                }
            case .topHat:
                ZStack {
                    RoundedRectangle(cornerRadius: 0.022 * r.width, style: .continuous).fill(c)
                        .frame(width: 0.70 * r.width, height: 0.06 * r.height)
                        .position(r.pt(0.5, 0.348))
                    RoundedRectangle(cornerRadius: 0.022 * r.width, style: .continuous).fill(c)
                        .frame(width: 0.44 * r.width, height: 0.29 * r.height)
                        .position(r.pt(0.5, 0.192))
                    Rectangle().fill(Color(lightHex: 0x963238, darkHex: 0x7E2A2F))
                        .frame(width: 0.44 * r.width, height: 0.05 * r.height)
                        .position(r.pt(0.5, 0.273))
                }
            case .crown:
                Path { p in
                    p.move(to: r.pt(0.26, 0.40))
                    p.addLine(to: r.pt(0.26, 0.20))
                    p.addLine(to: r.pt(0.38, 0.30))
                    p.addLine(to: r.pt(0.50, 0.16))
                    p.addLine(to: r.pt(0.62, 0.30))
                    p.addLine(to: r.pt(0.74, 0.20))
                    p.addLine(to: r.pt(0.74, 0.40))
                    p.closeSubpath()
                }
                .fill(c)
            }
        }
    }
}

// MARK: - Hex helper

extension Color {
    /// Single-value hex, for catalogue tints that are the same in both themes —
    /// an item's colour is the item, not a semantic role.
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
