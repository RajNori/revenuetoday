//
//  OnboardingView.swift
//  RevenueToday
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    @State private var showLogo = false
    @State private var showHeadline = false
    @State private var showSubline = false
    @State private var showStats = false
    @State private var showFeatures = false
    @State private var showTrust = false
    @State private var showCTA = false
    @State private var glowPulse = false

    private struct OnboardingFeatureCard: Identifiable {
        let id: String
        let emoji: String
        let title: String
        let line: String
    }

    private static let onboardingFeatureCards: [OnboardingFeatureCard] = [
        OnboardingFeatureCard(id: "log", emoji: "⚡", title: "10-second logging", line: "Calculator keyboard built in"),
        OnboardingFeatureCard(id: "year", emoji: "📈", title: "Year in view", line: "GitHub grid for your revenue"),
        OnboardingFeatureCard(id: "goal", emoji: "🎯", title: "Daily goals", line: "Ring fills as you earn"),
        OnboardingFeatureCard(id: "clients", emoji: "👥", title: "Client leaderboard", line: "Know who pays you most"),
        OnboardingFeatureCard(id: "pace", emoji: "📊", title: "Pace indicator", line: "Ahead or behind last month"),
        OnboardingFeatureCard(id: "pl", emoji: "💰", title: "Income + Expenses", line: "Full P&L with margin %")
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: "00C896").opacity(0.12),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: "00C896").opacity(0.05),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(Color.white.opacity(0.02))
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    logoSection
                    headlineSection
                    liveStatsSection
                    featuresSection
                    trustSection
                    ctaSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { showLogo = true }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.35)) { showHeadline = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.55)) { showSubline = true }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.75)) { showStats = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0)) { showFeatures = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.3)) { showTrust = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.6)) { showCTA = true }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(2.0)) { glowPulse = true }
    }

    private var logoSection: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: "00C896").opacity(0.25), lineWidth: 1)
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "00C896").opacity(0.15), radius: 20, x: 0, y: 0)

                Text("RT")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "00C896"))
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "00C896"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(glowPulse ? 1.4 : 1.0)
                    .opacity(glowPulse ? 0.6 : 1.0)

                Text("REVENUE TODAY")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Color(hex: "48484C"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: "141418"))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
            )
        }
        .padding(.top, 64)
        .padding(.bottom, 32)
        .opacity(showLogo ? 1 : 0)
        .offset(y: showLogo ? 0 : -16)
    }

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            (
                Text("Every payment").foregroundColor(.white)
                    + Text("\nfeels good.").foregroundColor(.white)
                    + Text("\nSee it happen.").foregroundColor(Color(hex: "00C896"))
            )
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .lineSpacing(2)
            .padding(.bottom, 16)
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline ? 0 : 20)

            Text("The income logger built for people who earn outside a salary.")
                .font(.system(size: 17, weight: .regular, design: .default))
                .foregroundColor(Color(hex: "8A8A8E"))
                .lineSpacing(5)
                .opacity(showSubline ? 1 : 0)
                .offset(y: showSubline ? 0 : 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 40)
    }

    private var liveStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT IT LOOKS LIKE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Color(hex: "48484C"))

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S REVENUE")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "48484C"))

                        Text("$2,450")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "00C896"))

                        Text("Goal: $2,000 · 122%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(hex: "48484C"))
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 5)
                            .frame(width: 56, height: 56)

                        Circle()
                            .trim(from: 0, to: 1.0)
                            .stroke(Color(hex: "00C896"), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        Text("100%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "FF6B6B"))
                        Text("EXPENSES")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "48484C"))
                    }
                    Spacer()
                    Text("- $340")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                HStack {
                    Text("NET PROFIT · 86% margin")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "48484C"))
                    Spacer()
                    Text("$2,110")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("STREAK")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "48484C"))
                        HStack(spacing: 4) {
                            Text("🔥").font(.system(size: 14))
                            Text("14 days")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)

                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 1, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("BEST DAY")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "48484C"))
                        HStack(spacing: 4) {
                            Text("🏆").font(.system(size: 14))
                            Text("$4,200")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color(hex: "00C896"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "141418"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "00C896").opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color(hex: "00C896").opacity(0.08), radius: 24, x: 0, y: 8)

            Text("Example data — your numbers will look even better.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "48484C"))
                .padding(.top, 4)
        }
        .padding(.bottom, 40)
        .opacity(showStats ? 1 : 0)
        .offset(y: showStats ? 0 : 24)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT'S INSIDE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundColor(Color(hex: "48484C"))
                .padding(.bottom, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(Array(Self.onboardingFeatureCards.enumerated()), id: \.element.id) { index, card in
                    miniFeatureCard(card, delay: Double(index) * 0.06)
                }
            }
        }
        .padding(.bottom, 40)
        .opacity(showFeatures ? 1 : 0)
        .offset(y: showFeatures ? 0 : 20)
    }

    private func miniFeatureCard(_ card: OnboardingFeatureCard, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.emoji).font(.system(size: 24))
            Text(card.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Text(card.line)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "48484C"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "141418"))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
        .opacity(showFeatures ? 1 : 0)
        .offset(y: showFeatures ? 0 : 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.0 + delay), value: showFeatures)
    }

    private var trustSection: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)

            VStack(spacing: 10) {
                trustLine(icon: "checkmark.shield.fill", text: "No accounts or sign-in required")
                trustLine(icon: "iphone.and.arrow.forward", text: "All data stored on your device only")
                trustLine(icon: "wifi.slash", text: "Works completely offline")
                trustLine(icon: "dollarsign.circle", text: "One-time payment. No subscription. Ever.")
            }

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
        .padding(.bottom, 32)
        .opacity(showTrust ? 1 : 0)
        .offset(y: showTrust ? 0 : 16)
    }

    private func trustLine(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "00C896"))
                .frame(width: 20)

            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(hex: "8A8A8E"))

            Spacer()

            Text("✓")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "00C896"))
        }
    }

    private var ctaSection: some View {
        VStack(spacing: 20) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    hasSeenOnboarding = true
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Start logging revenue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Capsule().fill(Color(hex: "00C896")))
                .shadow(
                    color: Color(hex: "00C896").opacity(glowPulse ? 0.5 : 0.2),
                    radius: glowPulse ? 24 : 12,
                    x: 0, y: 0
                )
            }
            .buttonStyle(ScaleButtonStyle())

            HStack(spacing: 0) {
                Text("$0.99")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(" · one-time · ")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "48484C"))
                Text("no subscription")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "48484C"))
                Text(" · ")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "48484C"))
                Text("yours forever")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "00C896"))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
        }
        .opacity(showCTA ? 1 : 0)
        .offset(y: showCTA ? 0 : 20)
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
