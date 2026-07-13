//
//  RootView.swift
//  WorkoutJournal
//

import SwiftUI

struct RootViewLegacy: View {
    private enum DragAxis {
        case undecided
        case horizontal
        case vertical
    }

    @State private var sessions = MockData.sessions
    @State private var selectedSessionID: WorkoutSession.ID?
    @State private var sidebarOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var dragAxis: DragAxis = .undecided

    private let sidebarWidth: CGFloat = 300
    private let openCornerRadius: CGFloat = 16
    private let axisLockDistance: CGFloat = 8
    private let sidebarAnimation = Animation.spring(response: 0.26, dampingFraction: 0.92)

    var body: some View {
        ZStack(alignment: .leading) {
            sidebar
                .offset(x: sidebarOffset - sidebarWidth)

            mainPanel
                .offset(x: sidebarOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .task {
            if selectedSessionID == nil {
                selectedSessionID = sessions.first?.id
            }
        }
    }

    private var progress: CGFloat {
        guard sidebarWidth > 0 else { return 0 }
        return min(1, max(0, sidebarOffset / sidebarWidth))
    }

    private var isSidebarOpen: Bool {
        sidebarOffset >= sidebarWidth * 0.5
    }

    private var isHorizontalDragging: Bool {
        dragAxis == .horizontal
    }

    private var mainPanel: some View {
        mainContent
            .scrollDisabled(isHorizontalDragging)
            .background(.background)
            .clipShape(mainPanelShape)
            .shadow(
                color: .black.opacity(0.28 * progress),
                radius: 18 * progress,
                x: -6 * progress,
                y: 0
            )
            .simultaneousGesture(sidebarDragGesture)
            .overlay {
                openPanelInteractionLayer
            }
    }

    private var mainPanelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: openCornerRadius * progress,
            bottomTrailingRadius: openCornerRadius * progress,
            topTrailingRadius: 0,
            style: .continuous
        )
    }

    private var mainContent: some View {
        NavigationStack {
            Group {
                if let index = sessions.firstIndex(where: { $0.id == selectedSessionID }) {
                    SessionDetailView(session: $sessions[index])
                } else {
                    ContentUnavailableView(
                        "세션을 선택하세요",
                        systemImage: "dumbbell",
                        description: Text("사이드바에서 운동 세션을 선택하세요.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("세션 목록")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var sidebar: some View {
        SessionSidebarView(
            sessions: sessions,
            selection: $selectedSessionID,
            onSessionSelected: closeSidebar
        )
        .frame(width: sidebarWidth)
        .frame(maxHeight: .infinity)
        .scrollDisabled(isHorizontalDragging)
        .simultaneousGesture(sidebarDragGesture)
        .allowsHitTesting(sidebarOffset > 0)
        .accessibilityHidden(sidebarOffset <= 0)
    }

    private var openPanelInteractionLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(sidebarDragGesture)
            .onTapGesture(perform: closeSidebar)
            .allowsHitTesting(isSidebarOpen)
            .accessibilityLabel("사이드바 닫기")
            .accessibilityAddTraits(.isButton)
            .accessibilityHidden(!isSidebarOpen)
    }

    private var sidebarDragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        let translation = value.translation

        if dragAxis == .undecided {
            let distance = hypot(translation.width, translation.height)
            guard distance >= axisLockDistance else { return }

            dragAxis = abs(translation.width) > abs(translation.height)
                ? .horizontal
                : .vertical

            if dragAxis == .horizontal {
                dragStartOffset = sidebarOffset
            }
        }

        guard dragAxis == .horizontal else { return }

        let proposed = dragStartOffset + translation.width
        sidebarOffset = min(sidebarWidth, max(0, proposed))
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        defer { dragAxis = .undecided }

        guard dragAxis == .horizontal else { return }

        let predicted = dragStartOffset + value.predictedEndTranslation.width
        withAnimation(sidebarAnimation) {
            sidebarOffset = predicted > sidebarWidth * 0.5 ? sidebarWidth : 0
        }
    }

    private func toggleSidebar() {
        withAnimation(sidebarAnimation) {
            sidebarOffset = isSidebarOpen ? 0 : sidebarWidth
        }
    }

    private func closeSidebar() {
        withAnimation(sidebarAnimation) {
            sidebarOffset = 0
        }
    }
}

#Preview {
    RootViewLegacy()
}
