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

    var body: some View {
        Link(destination: URL(string: "conduit://new_chat?homeWidget=true")!) {
            HStack(spacing: 12) {
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("Ask Clinical Guidelines")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
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
                    .containerBackground(Color.black, for: .widget)
            } else {
                ConduitWidgetEntryView(entry: entry)
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Clinical Guidelines")
        .description("Quick access to clinical guidelines.")
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

