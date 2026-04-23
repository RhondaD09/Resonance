//
//  AnimatedMeshGradient.swift
//  Resonance
//
//  Created by Rhonda Davis on 4/17/26.
//

import SwiftUI

struct AnimatedMeshGradient: View {
    @State private var startDate = Date.now

    var body: some View {
        TimelineView(.animation) { context in
            let t = Float(context.date.timeIntervalSince(startDate))

            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0),
                .init(0.5 + 0.2 * cos(t * 1.2), 0),
                .init(1, 0),

                .init(0, 0.5 + 0.15 * sin(t)),
                .init(0.5 + 0.3 * cos(t * 0.8), 0.5 + 0.3 * sin(t * 1.1)),
                .init(1, 0.5 - 0.15 * cos(t * 0.9)),

                .init(0, 1),
                .init(0.5 - 0.2 * sin(t * 1.3), 1),
                .init(1, 1)
            ], colors: [
                .black,
                Color(red: 90/255, green: 20/255, blue: 160/255),
//                .white,

                Color(red: 120/255, green: 50/255, blue: 200/255),
//                .white,
                .black,

                Color(red: 90/255, green: 20/255, blue: 160/255),
                .black,
                Color(red: 70/255, green: 20/255, blue: 140/255)
            ])
        }
    }

    private func cos(_ v: Float) -> Float { Foundation.cos(v) }
    private func sin(_ v: Float) -> Float { Foundation.sin(v) }
}
