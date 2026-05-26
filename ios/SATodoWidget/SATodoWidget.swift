import WidgetKit
import SwiftUI

// MARK: - Data Model

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let taskCount: Int
}

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let priority: Int
}

// MARK: - Timeline Provider

struct TaskTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [], taskCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        let entry = loadTasks()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let entry = loadTasks()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadTasks() -> TaskEntry {
        let defaults = UserDefaults(suiteName: "group.com.satodo.saTodo")
        let count = defaults?.integer(forKey: "task_count") ?? 0

        if let jsonString = defaults?.string(forKey: "pending_tasks"),
           let data = jsonString.data(using: .utf8),
           let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) {
            return TaskEntry(date: Date(), tasks: tasks, taskCount: count)
        }
        return TaskEntry(date: Date(), tasks: [], taskCount: 0)
    }
}

// MARK: - Colors (light / dark)

struct WidgetColors {
    let textPrimary: Color
    let textSecondary: Color
    let primary: Color
    let background: Color
    let separator: Color

    static func resolve(for colorScheme: ColorScheme) -> WidgetColors {
        switch colorScheme {
        case .dark:
            return WidgetColors(
                textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),       // #FFFFFF
                textSecondary: Color(red: 0.56, green: 0.56, blue: 0.58),   // #8E8E93
                primary: Color(red: 0.04, green: 0.52, blue: 1.0),          // #0A84FF
                background: Color(red: 0.11, green: 0.11, blue: 0.12),      // #1C1C1E
                separator: Color(red: 0.19, green: 0.19, blue: 0.2, opacity: 0.3) // #30FFFFFF
            )
        default:
            return WidgetColors(
                textPrimary: Color(red: 0.11, green: 0.11, blue: 0.12),     // #1C1C1E
                textSecondary: Color(red: 0.56, green: 0.56, blue: 0.58),   // #8E8E93
                primary: Color(red: 0.0, green: 0.48, blue: 1.0),           // #007AFF
                background: Color(red: 0.95, green: 0.95, blue: 0.97),      // #F2F2F7
                separator: Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 0.19) // #30000000
            )
        }
    }
}

// MARK: - Widget View

struct SATodoWidgetEntryView: View {
    var entry: TaskTimelineProvider.Entry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let colors = WidgetColors.resolve(for: colorScheme)

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("SA Todo")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                Spacer()
                Text("\(entry.taskCount) pending")
                    .font(.system(size: 12))
                    .foregroundColor(colors.textSecondary)

                Link(destination: URL(string: "satodo://quickadd")!) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.bottom, 8)

            Divider()
                .background(colors.separator)

            // Task list
            if entry.tasks.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 28))
                        .foregroundColor(colors.textSecondary)
                    Text("No pending tasks")
                        .font(.system(size: 13))
                        .foregroundColor(colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(5)) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(priorityColor(task.priority))
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.system(size: 15))
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(colors.background)
    }

    func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 3: return Color(red: 1.0, green: 0.23, blue: 0.19)   // #FF3B30
        case 2: return Color(red: 1.0, green: 0.58, blue: 0.0)    // #FF9500
        case 1: return Color(red: 0.20, green: 0.78, blue: 0.35)  // #34C759
        default: return Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        }
    }
}

// MARK: - Widget Configuration

struct SATodoWidget: Widget {
    let kind: String = "SATodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider()) { entry in
            SATodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("SA Todo")
        .description("View pending tasks and quick-add")
        .supportedFamilies([.systemMedium])
    }
}
