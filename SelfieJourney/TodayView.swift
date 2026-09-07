import SwiftUI

struct TodayView: View {
    let portraits: [Portrait]
    let reminders: ReminderManager
    let onCapture: () -> Void
    let onSettings: () -> Void
    let onLookback: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            page(now: context.date)
        }
    }

    private func page(now: Date) -> some View {
        let today = portraits.first { $0.date <= now && Calendar.current.isDate($0.date, inSameDayAs: now) }
        let streak = StreakCalculator.currentStreak(dates: portraits.map(\.date), now: now)
        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                masthead
                rhythm(now: now, streak: streak, capturedToday: today != nil)

                VStack(spacing: 11) {
                    PrimaryButton(title: today != nil ? "Retake today's selfie" : "Take today's selfie", action: onCapture)
                        .accessibilityIdentifier("today.capture")
                    HStack(spacing: 5) {
                        Image(systemName: today != nil ? "checkmark.circle.fill" : "sparkle")
                        Text(today != nil ? "Today's selfie is saved. Another frame for your time-lapse." : "Same framing each day. Watch yourself change over time.")
                    }
                    .font(.caption2).foregroundStyle(JourneyTheme.secondary)
                    .multilineTextAlignment(.center)
                }

                portraitStage(portrait: today ?? portraits.first, capturedToday: today != nil)

                Button(action: onSettings) {
                    HStack(spacing: 14) {
                        Image(systemName: reminders.enabled ? "bell.badge" : "bell")
                            .font(.system(size: 20)).foregroundStyle(JourneyTheme.accent)
                            .frame(width: 43, height: 43).background(JourneyTheme.softAccent, in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your daily selfie reminder").font(.subheadline.weight(.medium))
                            Text(reminders.enabled ? "Your daily reminder · \(reminders.date.formatted(date: .omitted, time: .shortened))" : "Choose a time to add your next frame")
                                .font(.caption).foregroundStyle(JourneyTheme.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(JourneyTheme.secondary)
                    }
                }
                .buttonStyle(.plain).accessibilityIdentifier("today.reminder")

                Button(action: onLookback) {
                    HStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .leading, spacing: 9) {
                            Eyebrow(text: "YOUR SELFIE TIME-LAPSE")
                            Text("Watch yourself\nchange over time.").font(JourneyTheme.serif(27)).tracking(-0.5)
                            Text(portraits.count >= 2 ? "Play your selfies as a time-lapse video" : "Each daily selfie becomes a frame in your video")
                                .font(.caption).foregroundStyle(JourneyTheme.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "play.fill").font(.system(size: 20))
                            .frame(width: 58, height: 58)
                            .background(JourneyTheme.surface.opacity(0.7), in: Circle())
                    }
                    .padding(23).frame(maxWidth: .infinity, alignment: .leading)
                    .background(JourneyTheme.sage, in: RoundedRectangle(cornerRadius: 25))
                }
                .buttonStyle(.plain).accessibilityIdentifier("today.lookback")
                HStack(spacing: 5) {
                    Image(systemName: "heart")
                    Text("Your real photos. Your changes over time.")
                }
                .font(.system(size: 10)).foregroundStyle(JourneyTheme.secondary)
                .frame(maxWidth: .infinity).padding(.bottom, 15)
            }
            .padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(JourneyTheme.background)
        .foregroundStyle(JourneyTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var masthead: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "camera.aperture").font(.system(size: 25, weight: .medium)).foregroundStyle(JourneyTheme.accent)
                    .accessibilityHidden(true)
                Text("Selfie Journey")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .tracking(-0.7)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selfie Journey")
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 18, weight: .regular))
                    .frame(width: 44, height: 44)
                    .background(JourneyTheme.surface.opacity(0.8), in: Circle())
                    .overlay(Circle().strokeBorder(JourneyTheme.line, lineWidth: 0.7))
            }
            .buttonStyle(.plain).accessibilityLabel("Your daily ritual settings")
            .accessibilityIdentifier("today.settings")
        }
    }

    private func portraitStage(portrait: Portrait?, capturedToday: Bool) -> some View {
        GeometryReader { geometry in
            let photoWidth = min(geometry.size.width * 0.47, 165)
            ZStack {
                RoundedRectangle(cornerRadius: 27).fill(JourneyTheme.sage.opacity(0.72))
                Circle().stroke(JourneyTheme.secondary.opacity(0.08), lineWidth: 1)
                    .frame(width: 270, height: 270).offset(x: 125, y: -75)
                Circle().stroke(JourneyTheme.secondary.opacity(0.08), lineWidth: 1)
                    .frame(width: 270, height: 270).offset(x: -125, y: 115)
                RoundedRectangle(cornerRadius: 5).fill(JourneyTheme.background)
                    .frame(width: photoWidth + 20, height: photoWidth * 1.1 + 43)
                    .rotationEffect(.degrees(8)).offset(x: 9, y: 0)
                VStack(spacing: 0) {
                    Group {
                        if let image = portrait?.image {
                            Image(uiImage: image).resizable().scaledToFill()
                        } else {
                            Image("PortraitInspiration").resizable().scaledToFill()
                        }
                    }
                    .frame(width: photoWidth, height: photoWidth * 1.1).clipped()
                    HStack {
                        Text(portrait == nil ? "the first of many" : portrait!.date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.system(size: 11, weight: .regular, design: .serif)).italic()
                        Spacer()
                        Image(systemName: "sparkle").font(.system(size: 12)).foregroundStyle(Color(red: 0.75, green: 0.34, blue: 0.22))
                    }
                    .foregroundStyle(Color(red: 0.2, green: 0.21, blue: 0.18))
                    .padding(.horizontal, 3).frame(width: photoWidth, height: 32)
                }
                .padding(9).padding(.bottom, 1)
                .background(.white, in: RoundedRectangle(cornerRadius: 4))
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 2, y: 8)
                .rotationEffect(.degrees(-5))
                .accessibilityLabel(portrait == nil ? "An example portrait for inspiration" : "Your most recent portrait")

                VStack {
                    HStack(alignment: .top) {
                        Text(portrait == nil ? "DAY\nONE" : "DAY\n\(String(format: "%03d", portraits.count))")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .tracking(1.3).lineSpacing(4).foregroundStyle(JourneyTheme.secondary)
                        Spacer()
                        Image(systemName: capturedToday ? "checkmark.seal.fill" : "sun.max")
                            .font(.system(size: 26, weight: .ultraLight))
                            .foregroundStyle(JourneyTheme.accent)
                            .rotationEffect(.degrees(15))
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Text(portrait == nil ? "INSPIRATION" : capturedToday ? "TODAY, KEPT" : "LAST PORTRAIT")
                            .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1)
                            .foregroundStyle(JourneyTheme.secondary)
                    }
                }.padding(19)
            }
            .clipped().clipShape(RoundedRectangle(cornerRadius: 27))
        }
        .frame(height: 245)
    }

    private func rhythm(now: Date, streak: Int, capturedToday: Bool) -> some View {
        let progress = StreakProgress(streak: streak, hasPortraits: !portraits.isEmpty, completedToday: capturedToday)
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(text: "YOUR DAILY STREAK")
                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        Text(streak.formatted())
                            .font(.system(size: 64, weight: .medium, design: .rounded))
                            .tracking(-3).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.65)
                            .foregroundStyle(JourneyTheme.accent)
                        Text(streak == 1 ? "day" : "days")
                            .font(JourneyTheme.serif(27)).foregroundStyle(JourneyTheme.ink)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current streak, \(streak) \(streak == 1 ? "day" : "days")")
                    .accessibilityIdentifier("today.streak")
                }
                Spacer(minLength: 0)
                if !dynamicTypeSize.isAccessibilitySize {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 47, weight: .medium))
                            .foregroundStyle(JourneyTheme.accent.gradient)
                            .frame(width: 84, height: 84)
                            .background(JourneyTheme.softAccent, in: RoundedRectangle(cornerRadius: 29))
                            .rotationEffect(.degrees(-7))
                        if capturedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 25, height: 25)
                                .background(JourneyTheme.accent, in: Circle())
                                .overlay(Circle().strokeBorder(JourneyTheme.surface, lineWidth: 3))
                                .offset(x: 4, y: 3)
                        }
                    }
                    .accessibilityHidden(true)
                }
            }
            Text(progress.encouragement)
                .font(.caption).foregroundStyle(JourneyTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 0) {
                ForEach(weekDates(now: now), id: \.self) { day in
                    let isToday = Calendar.current.isDate(day, inSameDayAs: now)
                    let complete = portraits.contains { $0.date <= now && Calendar.current.isDate($0.date, inSameDayAs: day) }
                    VStack(spacing: 9) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(JourneyTheme.secondary)
                        ZStack {
                            Circle().fill(complete ? JourneyTheme.accent : JourneyTheme.background)
                            if isToday { Circle().strokeBorder(JourneyTheme.accent, style: StrokeStyle(lineWidth: 1.3, dash: complete ? [] : [3, 3])) }
                            if complete {
                                Image(systemName: "checkmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                            } else {
                                Text(day.formatted(.dateTime.day())).font(.system(size: 12, weight: isToday ? .semibold : .regular))
                                    .foregroundStyle(isToday ? JourneyTheme.accent : JourneyTheme.secondary)
                            }
                        }.frame(width: 35, height: 35)
                        Circle().fill(isToday ? JourneyTheme.accent : .clear).frame(width: 3, height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(isToday ? "Today, " : "")\(day.formatted(date: .complete, time: .omitted)), \(complete ? "portrait saved" : "no portrait")")
                }
            }
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    Text(progress.milestoneLabel)
                        .font(.caption.weight(.medium))
                    Spacer(minLength: 8)
                    Text("\(streak) / \(progress.nextMilestone) days")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(JourneyTheme.secondary)
                }
                ProgressView(value: progress.fractionComplete)
                    .tint(JourneyTheme.accent)
                    .accessibilityLabel("Next milestone, \(progress.nextMilestone) days")
                    .accessibilityValue("\(progress.daysToMilestone) more \(progress.daysToMilestone == 1 ? "day" : "days")")
            }
            .padding(.top, 3)
        }
        .padding(22)
        .background(JourneyTheme.surface, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(JourneyTheme.line, lineWidth: 0.7))
    }

    private func weekDates(now: Date) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}
