import SwiftUI

struct TaskCardView: View {
    let task: TaskEntity
    let onMove: (Int) -> Void
    var onOpen: (() -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var isExpanded = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)

                    Text(task.resolvedProjectTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(task.priority.color)
                    .frame(width: 10, height: 10)
            }

            HStack {
                Label(task.status.title, systemImage: task.status.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(task.status.tint)

                Spacer()

                Text("\(task.completedPomodoros)/\(task.estimatedPomodoros) пом.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if isExpanded {
                Text(task.detailsText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ProgressView(value: task.progress)
                .tint(task.status.tint)

            Text("Потяни влево/вправо, чтобы сменить статус карточки на доске.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .scaleEffect(isPressed ? 0.98 : 1)
        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
        .offset(dragOffset)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .gesture(longPressGesture.simultaneously(with: dragGesture))
        .simultaneousGesture(
            TapGesture().onEnded {
                onOpen?()
            }
        )
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .onEnded { _ in
                isPressed = true
                withAnimation(.spring) {
                    isExpanded.toggle()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                defer {
                    withAnimation(.spring) {
                        dragOffset = .zero
                    }
                }

                if value.translation.width > 120 {
                    onMove(1)
                } else if value.translation.width < -120 {
                    onMove(-1)
                }
            }
    }
}
