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
                .foregroundStyle(.gray)
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        return date.time24h
    }
}
//#Preview {
//    PresetRow()
//}
