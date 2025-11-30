//
//  CelebrationView.swift
//  LeetcodeCounter
//
//  Celebration animation when counter reaches 500
//
import SwiftUI

struct CelebrationView: View {
    @State private var animate = false
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
            startAnimation()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green]
        for i in 0..<50 {
            let angle = Double(i) * (2 * .pi / 50)
            let distance = Double.random(in: 100...300)
            let x = cos(angle) * distance
            let y = sin(angle) * distance
            
            particles.append(Particle(
                id: UUID(),
                position: CGPoint(x: 0, y: 0),
                velocity: CGPoint(x: x, y: y),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...12),
                opacity: 1.0
            ))
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 2.0)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: particles[i].velocity.x,
                    y: particles[i].velocity.y
                )
                particles[i].opacity = 0.0
            }
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let velocity: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

