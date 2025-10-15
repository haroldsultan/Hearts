import SwiftUI

// MARK: - Particle Effect for Celebrations

struct ParticleEffect: View {
    let type: ParticleType
    @State private var particles: [Particle] = []
    
    enum ParticleType {
        case hearts       // Red hearts for hearts breaking
        case stars        // Yellow stars for shooting moon
        case sparkles     // White sparkles for winning
        case moonEmoji    // Moon emoji rising
    }
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particleView(for: type)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    @ViewBuilder
    private func particleView(for type: ParticleType) -> some View {
        switch type {
        case .hearts:
            Text("♥️")
                .font(.system(size: 30))
        case .stars:
            Text("⭐️")
                .font(.system(size: 25))
        case .sparkles:
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
        case .moonEmoji:
            Text("🌙")
                .font(.system(size: 60))
        }
    }
    
    private func createParticles(in size: CGSize) {
        let count = type == .moonEmoji ? 1 : 20
        
        for i in 0..<count {
            let delay = Double(i) * 0.05
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: type == .moonEmoji ? 2.0 : 1.5)) {
                    if type == .moonEmoji {
                        // Single moon rises from center
                        particles.append(Particle(
                            x: size.width / 2,
                            y: size.height / 2,
                            scale: 0.5,
                            opacity: 1.0,
                            rotation: 0
                        ))
                        
                        // Animate moon rising
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 2.0)) {
                                if let index = particles.firstIndex(where: { $0.id == particles.first?.id }) {
                                    particles[index].y = size.height * 0.2
                                    particles[index].scale = 1.5
                                }
                            }
                        }
                    } else {
                        // Random particles
                        let particle = Particle(
                            x: CGFloat.random(in: 0...size.width),
                            y: size.height + 50,
                            scale: CGFloat.random(in: 0.5...1.5),
                            opacity: 1.0,
                            rotation: Double.random(in: 0...360)
                        )
                        particles.append(particle)
                        
                        // Animate upward
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 1.5)) {
                                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                                    particles[index].y = -50
                                    particles[index].opacity = 0
                                    particles[index].rotation += 360
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            particles.removeAll()
        }
    }
}

// MARK: - Pulse Animation Modifier

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let count: Int
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: isPulsing ? 0 : 3)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).repeatCount(count, autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseEffect(color: Color = .red, count: Int = 3) -> some View {
        modifier(PulseModifier(color: color, count: count))
    }
}

// MARK: - Shake Animation Modifier

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

// MARK: - Flash Screen Effect

struct FlashOverlay: View {
    let color: Color
    @State private var opacity: Double = 0.0
    
    var body: some View {
        color
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeIn(duration: 0.1)) {
                    opacity = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                    }
                }
            }
    }
}

// MARK: - Card Flying Animation

struct CardFlyingModifier: ViewModifier {
    let destination: CGPoint
    let duration: Double
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .position(position)
            .opacity(opacity)
            .onAppear {
                // Start animation
                withAnimation(.easeInOut(duration: duration)) {
                    position = destination
                }
                
                // Fade out near end
                DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.8) {
                    withAnimation(.easeOut(duration: duration * 0.2)) {
                        opacity = 0.0
                    }
                }
            }
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isGlowing ? color : .clear, radius: isGlowing ? radius : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func glow(color: Color = .yellow, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Bounce Animation

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 0.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    scale = 1.0
                }
            }
    }
}

extension View {
    func bounceIn() -> some View {
        modifier(BounceModifier())
    }
}

// MARK: - Score Flying Animation

struct ScoreFlyingView: View {
    let score: Int
    let from: CGPoint
    let to: CGPoint
    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    
    init(score: Int, from: CGPoint, to: CGPoint) {
        self.score = score
        self.from = from
        self.to = to
        _position = State(initialValue: from)
    }
    
    var body: some View {
        Text("+\(score)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.yellow)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    position = to
                    opacity = 0.0
                }
            }
    }
}
