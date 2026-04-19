import SwiftUI

struct PlannerWorkspaceView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var sessionStore: StudySessionStore
    @EnvironmentObject private var noteStore: NoteStore
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel

    @SceneStorage("workspace.selection") private var selectionRaw = SidebarSelection.inbox.rawValue
    @SceneStorage("workspace.selectedTaskID") private var selectedTaskID = ""
    @SceneStorage("workspace.calendarTimestamp") private var calendarTimestamp = Date.now.timeIntervalSinceReferenceDate
    @SceneStorage("workspace.note") private var workspaceNote = "Эта заметка хранится через SceneStorage и переживает пересоздание сцены."
    @SceneStorage("workspace.presentedNoteID") private var presentedNoteID = ""
    @AppStorage(AppPreferenceKeys.showsCompleted) private var showsCompleted = true

    @State private var quickTaskTitle = ""
    @State private var noteDisplayMode: NoteDisplayMode = .preview
    @State private var visibility: NavigationSplitViewVisibility = .all
    @StateObject private var viewModel = WorkspaceViewModel()

    var body: some View {
        Group {
            if isCompactLayout {
                compactWorkspace
            } else {
                regularWorkspace
            }
        }
        // Анимация завязана на самом контейнере, чтобы смена выбранной задачи,
        // фильтра и состава данных ощущалась как один непрерывный переход,
        // а не как несколько независимых дерганий вложенных subview.
        .animation(.snappy(duration: 0.32), value: selectionRaw)
        .animation(.snappy(duration: 0.32), value: selectedTaskID)
        .animation(.snappy(duration: 0.32), value: taskStore.changeToken)
        .onAppear(perform: ensureValidSelection)
        .onChange(of: selectionRaw) { _, _ in
            ensureValidSelection()
            refreshViewModel()
        }
        .onChange(of: showsCompleted) { _, _ in
            ensureValidSelection()
            refreshViewModel()
        }
        .onChange(of: taskStore.changeToken) { _, _ in
            ensureValidSelection()
            refreshViewModel()
        }
        .onChange(of: noteStore.changeToken) { _, _ in
            refreshViewModel()
        }
        .onChange(of: selectedTaskID) { _, _ in
            refreshViewModel()
        }
        .onChange(of: calendarTimestamp) { _, _ in
            refreshViewModel()
        }
        .task {
            refreshViewModel()
        }
        .sheet(item: presentedNoteBinding) { note in
            NavigationStack {
                NoteInspectorView(note: note, displayMode: $noteDisplayMode)
            }
        }
    }

    private var regularWorkspace: some View {
        // В рабочем месте мы используем три колонки не как "просто навигацию",
        // а как полноценный productivity layout:
        // 1. sidebar отвечает за смену контекста и быстрые системные сигналы,
        // 2. content показывает текущий поток задач и быстрые действия,
        // 3. detail раскрывает выбранную задачу без перегрузки центральной колонки.
        // Такой разнос обязанностей делает экран визуально спокойнее и масштабируется лучше,
        // чем попытка уместить все элементы в один длинный список.
        NavigationSplitView(columnVisibility: $visibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
        } content: {
            TaskListView(
                selection: currentSelection,
                selectedTaskID: $selectedTaskID,
                quickTaskTitle: $quickTaskTitle,
                showsCompleted: showsCompleted
            )
            .navigationSplitViewColumnWidth(min: 420, ideal: 500, max: 620)
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var compactWorkspace: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    workspaceSummaryCard
                    compactContextPicker
                    compactCalendarCard
                    compactRecentTasksCard
                    compactRecentNotesCard
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Рабочее место")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await dashboardViewModel.refresh(taskStore: taskStore, sessionStore: sessionStore)
                        }
                    } label: {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }

    private var currentSelection: SidebarSelection {
        SidebarSelection(rawValue: selectionRaw) ?? .inbox
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var selectedCalendarDate: Date {
        Date(timeIntervalSinceReferenceDate: calendarTimestamp)
    }

    private var sidebar: some View {
        // Sidebar намеренно собран как scroll-контейнер с отдельными карточками,
        // а не как большой List. Это даёт больше контроля над плотностью, фонами,
        // внутренними анимациями и позволяет сделать колонку похожей на dashboard,
        // а не на таблицу с системным стилем по умолчанию.
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                workspaceSummaryCard

                sidebarSection("Smart Views") {
                    ForEach(SidebarSelection.smartLists) { selection in
                        sidebarButton(for: selection)
                    }
                }

                sidebarSection("Projects") {
                    OutlineGroup(ProjectNode.studyTree, children: \.children) { node in
                        if let selection = node.selection {
                            sidebarButton(for: selection, titleOverride: node.title)
                        } else {
                            Label(node.title, systemImage: "folder.fill")
                                .font(.headline)
                                .padding(.vertical, 6)
                        }
                    }
                }

                if !dashboardViewModel.recommendations.isEmpty {
                    sidebarSection("Рекомендации") {
                        ForEach(Array(dashboardViewModel.recommendations.prefix(3).enumerated()), id: \.offset) { index, recommendation in
                            Label(recommendation, systemImage: "sparkles")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    Color.accentColor.opacity(index == 0 ? 0.12 : 0.08),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                )
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .navigationTitle("Рабочее место")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await dashboardViewModel.refresh(taskStore: taskStore, sessionStore: sessionStore)
                    }
                } label: {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private var compactContextPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Фокус рабочего места")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SidebarSelection.smartLists) { selection in
                        compactSelectionChip(for: selection)
                    }

                    Menu {
                        ForEach(projectSelections) { selection in
                            Button(selection.title) {
                                selectionRaw = selection.rawValue
                                selectedTaskID = ""
                            }
                        }
                    } label: {
                        Label("Проекты", systemImage: "folder")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.secondary.opacity(0.08), in: Capsule())
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var compactCalendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Календарь")
                        .font(.headline)

                    Text(viewModel.calendarMonthTitle.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        shiftCalendarMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Button {
                        shiftCalendarMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(viewModel.calendarDays) { day in
                    Button {
                        calendarTimestamp = day.date.timeIntervalSinceReferenceDate
                    } label: {
                        CompactCalendarDayCell(
                            day: day,
                            isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedCalendarDate)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("План на \(selectedCalendarDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline.weight(.semibold))

                if viewModel.selectedDayTasks.isEmpty {
                    Text("На выбранный день задач с дедлайном нет.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.selectedDayTasks, id: \.id) { task in
                        compactTaskRow(task)
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var compactRecentTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Актуальные задачи")
                    .font(.headline)

                Spacer()

                Text(currentSelection.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.10), in: Capsule())
            }

            if viewModel.recentTasks.isEmpty {
                Text("Пока нет задач для этого контекста.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentTasks, id: \.id) { task in
                    compactTaskRow(task)
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var compactRecentNotesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Свежие заметки")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.recentNotes.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.10), in: Capsule())
            }

            if viewModel.recentNotes.isEmpty {
                Text("Пока нет заметок, связанных с текущим контекстом.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentNotes, id: \.persistentModelID) { note in
                    Button {
                        presentedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                    } label: {
                        CompactNoteCard(
                            note: note,
                            projectTitle: projectTitle(for: note)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var detail: some View {
        Group {
            if let task = viewModel.selectedTask {
                ScrollView {
                    VStack(spacing: 20) {
                        TaskDetailView(task: task)
                        TaskRelationshipDetailCard(
                            task: task,
                            projects: viewModel.selectedTaskProjects,
                            siblingTasks: viewModel.siblingTasks,
                            notes: viewModel.selectedTaskNotes,
                            onOpenTask: { selectedTaskID = $0.id.uuidString },
                            onOpenNote: { note in
                                presentedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                            }
                        )
                        SceneStorageView(note: $workspaceNote)
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                VStack(spacing: 20) {
                    WorkspaceContextDetailCard(
                        selection: currentSelection,
                        projects: viewModel.relatedProjects,
                        tasks: viewModel.contextTasks,
                        notes: viewModel.relatedNotes,
                        weeklyMinutes: sessionStore.weeklyFocusedMinutes(),
                        recommendations: dashboardViewModel.recommendations,
                        onOpenTask: { task in
                            selectedTaskID = task.id.uuidString
                        },
                        onOpenNote: { note in
                            presentedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                        }
                    )

                    SceneStorageView(note: $workspaceNote)
                        .frame(maxWidth: 560)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
                .transition(.opacity)
            }
        }
    }

    private func sidebarButton(
        for selection: SidebarSelection,
        titleOverride: String? = nil
    ) -> some View {
        let taskCount = taskStore.tasks(for: selection, showsCompleted: showsCompleted).count
        let isSelected = selectionRaw == selection.rawValue

        return Button {
            withAnimation(.snappy) {
                selectionRaw = selection.rawValue
                // Выбор пункта sidebar меняет рабочий контекст, а не открывает молча
                // первую задачу. Это делает поведение предсказуемым: сначала меняется
                // фильтр и detail показывает summary выбранного контекста, а уже потом
                // пользователь сам выбирает конкретную задачу из центральной колонки.
                selectedTaskID = ""
            }
        } label: {
            HStack {
                Label(titleOverride ?? selection.title, systemImage: selection.systemImage)
                    .fontWeight(isSelected ? .semibold : .regular)

                Spacer()

                Text("\(taskCount)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.primary.opacity(isSelected ? 0.12 : 0.06), in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.10) : Color.clear)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.28) : Color.clear, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var workspaceSummaryCard: some View {
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Текущий контекст")
                        .font(.title3.bold())

                    Text(currentSelection.title)
                        .font(.title3.weight(.semibold))

                    Text(selectionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "rectangle.3.group.bubble")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }

            HStack(spacing: 12) {
                WorkspaceMiniMetric(title: "В контексте", value: "\(contextTasks.count)")
                WorkspaceMiniMetric(title: "Проектов", value: "\(relatedProjects.count)")
                WorkspaceMiniMetric(title: "Заметок", value: "\(viewModel.relatedNotes.count)")
                WorkspaceMiniMetric(title: "Фокус", value: "\(sessionStore.weeklyFocusedMinutes())м")
            }

            Group {
                if dashboardViewModel.isSyncing {
                    ProgressView("Синхронизация", value: dashboardViewModel.syncProgress)
                        .tint(Color.accentColor)
                } else {
                    ProgressView(value: taskStore.completionRatio()) {
                        Text("Общий прогресс")
                    }
                    .tint(Color.accentColor)
                }
            }
            .animation(.snappy(duration: 0.3), value: dashboardViewModel.isSyncing)
            .animation(.snappy(duration: 0.3), value: dashboardViewModel.syncProgress)

            Text(dashboardViewModel.lastSyncDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func sidebarSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        }
    }

    private func ensureValidSelection() {
        let tasks = taskStore.tasks(for: currentSelection, showsCompleted: showsCompleted)

        guard !tasks.isEmpty else {
            selectedTaskID = ""
            return
        }

        if !tasks.contains(where: { $0.id.uuidString == selectedTaskID }) {
            selectedTaskID = ""
        }
    }

    private var contextTasks: [TaskEntity] {
        viewModel.contextTasks
    }

    private var relatedProjects: [ProjectEntity] {
        viewModel.relatedProjects
    }

    private var selectionDescription: String {
        switch currentSelection {
        case .inbox:
            "Показываем все незавершённые задачи вне узкого project-контекста."
        case .today:
            "Фильтр собирает задачи, которые требуют внимания именно сегодня."
        case .flagged:
            "Здесь собраны только отмеченные как важные задачи."
        case .inProgress:
            "Контекст работы по задачам, которые уже двигаются к результату."
        case .done:
            "Архив завершённых задач для обзора результата и прогресса."
        case .projectSwiftUI, .projectData, .projectWellbeing, .projectResearch:
            "Выбран project-контекст: ниже можно увидеть связанные проекты и задачи."
        }
    }

    private func refreshViewModel() {
        viewModel.refresh(
            taskStore: taskStore,
            noteStore: noteStore,
            selection: currentSelection,
            showsCompleted: showsCompleted,
            selectedTaskID: selectedTaskID,
            selectedDate: selectedCalendarDate
        )
    }

    private func compactSelectionChip(for selection: SidebarSelection) -> some View {
        let isSelected = currentSelection == selection

        return Button {
            selectionRaw = selection.rawValue
            selectedTaskID = ""
        } label: {
            Label(selection.title, systemImage: selection.systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.accentColor.opacity(0.28) : Color.clear, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func compactTaskRow(_ task: TaskEntity) -> some View {
        NavigationLink {
            ScrollView {
                VStack(spacing: 20) {
                    TaskDetailView(task: task)
                    TaskRelationshipDetailCard(
                        task: task,
                        projects: taskStore.relatedProjects(for: task),
                        siblingTasks: taskStore.relatedTasks(for: task),
                        notes: noteStore.notes(for: task),
                        onOpenTask: { selectedTaskID = $0.id.uuidString },
                        onOpenNote: { note in
                            presentedNoteID = noteStore.persistentModelIDHash(for: note).uuidString
                        }
                    )
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(task.resolvedProjectTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dueDate = task.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Label(task.status.title, systemImage: task.status.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(task.status.tint)
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func projectTitle(for note: NoteRecord) -> String {
        if let projectID = note.projectID,
           let project = taskStore.allProjects().first(where: { $0.id == projectID }) {
            return project.title
        }

        return "Без проекта"
    }

    private func shiftCalendarMonth(by delta: Int) {
        let updatedDate = Calendar.current.date(byAdding: .month, value: delta, to: selectedCalendarDate) ?? selectedCalendarDate
        calendarTimestamp = updatedDate.timeIntervalSinceReferenceDate
    }

    private var weekdaySymbols: [String] {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    }

    private var projectSelections: [SidebarSelection] {
        [.projectSwiftUI, .projectData, .projectWellbeing, .projectResearch]
    }

    private var presentedNoteBinding: Binding<NoteRecord?> {
        Binding(
            get: { noteStore.note(idString: presentedNoteID) },
            set: { presentedNoteID = $0.map(noteStore.persistentModelIDHash(for:)).map(\.uuidString) ?? "" }
        )
    }
}

private struct WorkspaceMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WorkspaceContextDetailCard: View {
    let selection: SidebarSelection
    let projects: [ProjectEntity]
    let tasks: [TaskEntity]
    let notes: [NoteRecord]
    let weeklyMinutes: Int
    let recommendations: [String]
    let onOpenTask: (TaskEntity) -> Void
    let onOpenNote: (NoteRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Detail для режима "задача не выбрана" теперь показывает именно выбранный
            // рабочий контекст. Благодаря этому клик по sidebar имеет очевидный результат:
            // карточка обновляется под выбранный фильтр, а ниже сразу видны связанные
            // проекты и задачи, которые относятся к этому контексту.
            Label("Контекст: \(selection.title)", systemImage: selection.systemImage)
                .font(.title2.bold())

            HStack(spacing: 12) {
                WorkspaceHighlightCard(title: "Фокус за неделю", value: "\(weeklyMinutes) мин", tint: .blue)
                WorkspaceHighlightCard(title: "Релевантных задач", value: "\(tasks.count)", tint: .green)
            }

            if !projects.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Связанные проекты")
                        .font(.headline)

                    ForEach(projects, id: \.id) { project in
                        Label(project.title, systemImage: project.iconName)
                            .font(.subheadline)
                    }
                }
            }

            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Связанные задачи")
                        .font(.headline)

                    ForEach(tasks, id: \.id) { task in
                        Button {
                            onOpenTask(task)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(task.priority.color)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.subheadline.weight(.semibold))

                                    Text(task.resolvedProjectPath)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(task.status.title)
                                    .font(.caption)
                                    .foregroundStyle(task.status.tint)
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Связанные заметки")
                        .font(.headline)

                    ForEach(notes.prefix(3), id: \.persistentModelID) { note in
                        Button {
                            onOpenNote(note)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(note.markdownText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Что делать дальше")
                    .font(.headline)

                ForEach(recommendations.isEmpty ? ["Выбери задачу в центре, чтобы открыть подробный контекст и действия."] : Array(recommendations.prefix(3)), id: \.self) { recommendation in
                    Label(recommendation, systemImage: "arrow.right.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: 620, alignment: .leading)
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct TaskRelationshipDetailCard: View {
    let task: TaskEntity
    let projects: [ProjectEntity]
    let siblingTasks: [TaskEntity]
    let notes: [NoteRecord]
    let onOpenTask: (TaskEntity) -> Void
    let onOpenNote: (NoteRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Связанный контекст задачи", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.title3.bold())

            if let project = projects.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Проект")
                        .font(.headline)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: project.iconName)
                            .foregroundStyle(project.tintColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title)
                                .font(.headline)
                            Text(project.detailsText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(project.tintColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }

            if !siblingTasks.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Другие задачи этого проекта")
                        .font(.headline)

                    ForEach(siblingTasks, id: \.id) { sibling in
                        Button {
                            onOpenTask(sibling)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(sibling.priority.color)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sibling.title)
                                        .font(.subheadline.weight(.semibold))
                                    Text(sibling.detailsText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Label(sibling.status.title, systemImage: sibling.status.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(sibling.status.tint)
                            }
                            .padding(12)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("Для этой задачи пока нет соседних карточек в том же проекте.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Заметки по задаче")
                        .font(.headline)

                    ForEach(notes, id: \.persistentModelID) { note in
                        Button {
                            onOpenNote(note)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(note.markdownText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Эта секция показывает, как одно выбранное `TaskEntity` раскрывается обратно в проект и в связанные задачи без дополнительных моков в UI.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct CompactCalendarDayCell: View {
    let day: WorkspaceCalendarDay
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(day.date.formatted(.dateTime.day()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(day.isInDisplayedMonth ? Color.primary : Color.secondary.opacity(0.45))

            if day.dueTasksCount > 0 {
                Text("\(day.dueTasksCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(isSelected ? .white : .accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.12),
                        in: Capsule()
                    )
            } else {
                Circle()
                    .fill(day.isToday ? Color.accentColor.opacity(0.6) : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(day.isInDisplayedMonth ? 0.05 : 0.02))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(day.isToday ? Color.accentColor.opacity(0.30) : Color.clear, lineWidth: 1)
        }
    }
}

private struct CompactNoteCard: View {
    let note: NoteRecord
    let projectTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text(projectTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(note.markdownText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct WorkspaceHighlightCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
