//
//  ConduitWidget.swift
//  ConduitWidget
//
//  Created by cogwheel on 07/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ConduitEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct ConduitProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConduitEntry {
        ConduitEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ConduitEntry) -> Void) {
        let entry = ConduitEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConduitEntry>) -> Void) {
        let entry = ConduitEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget View

struct ConduitWidgetEntryView: View {
    var entry: ConduitProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Main "Ask Conduit" pill - ChatGPT style
            Link(destination: URL(string: "homewidget://new_chat")!) {
                HStack(spacing: 12) {
                    Image("HubIcon")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Ask Conduit")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.15))
                )
            }
            .buttonStyle(.plain)

            // 4 circular icon buttons - ChatGPT style, fill width
            HStack(spacing: 8) {
                CircularIconButton(symbol: "camera", url: "homewidget://camera")
                CircularIconButton(symbol: "photo.on.rectangle.angled", url: "homewidget://photos")
                CircularIconButton(symbol: "waveform", url: "homewidget://mic")
                CircularIconButton(symbol: "doc.on.clipboard", url: "homewidget://clipboard")
            }
        }
        .padding(16)
    }
}

// MARK: - Circular Icon Button (ChatGPT Style)

struct CircularIconButton: View {
    let symbol: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Configuration

struct ConduitWidget: Widget {
    let kind: String = "ConduitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConduitProvider()) { entry in
            if #available(iOS 17.0, *) {
                ConduitWidgetEntryView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                ConduitWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Conduit")
        .description("Quick access to chat, camera, photos, and voice.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    ConduitWidget()
} timeline: {
    ConduitEntry(date: .now)
}

