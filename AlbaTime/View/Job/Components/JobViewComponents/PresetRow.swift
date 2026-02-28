import SwiftUI

struct PresetRow: View {
    let preset: WorkTimePreset
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(preset.label)
                .bold()
                .foregroundStyle(Color.theme.primary)
            
            Spacer()
            
            Text("\(formatTime(preset.startTime)) ~ \(formatTime(preset.endTime))")
                .font(.subheadline)
                .foregroundStyle(Color.theme.textSecondary)
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.theme.field)
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        return date.time24h
    }
}
#Preview("Preset Row") {
    let calendar = Calendar.current
    let base = calendar.startOfDay(for: Date())
    let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
    let end = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: base) ?? base

    let preset = WorkTimePreset(label: "오픈", startTime: start, endTime: end)

    return PresetRow(
        preset: preset,
        onDelete: {}
    )
    .padding(.vertical, 20)
}
