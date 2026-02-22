import SwiftUI

// MARK: - Data Models

struct MapHeaderStats {
    var streak: Int
    var gems: Int
    var lives: Int
}

enum NodeType {
    case lesson, boss, chest, practice
}

enum NodeState {
    case locked, available, completed
}

struct MapNode: Identifiable {
    let id: Int
    let type: NodeType
    var state: NodeState
    var stars: Int
    let training: Training?
}

struct UnitInfo {
    let sectionNumber: Int
    let unitNumber: Int
    let unitTitle: String
}

struct UnitData: Identifiable {
    let id: Int
    let info: UnitInfo
    let nodes: [MapNode]
}

struct SectionData: Identifiable {
    let id: Int
    let units: [UnitData]
}


// MARK: - MapPathView

struct MapPathView: View {
    let nodes: [MapNode]
    let onTap: (MapNode) -> Void
    private let rowHeight: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. ノードを繋ぐ線（最背面に配置）
                ForEach(0..<max(0, nodes.count - 1), id: \.self) { i in
                    let start = center(i, width: geo.size.width)
                    let end = center(i + 1, width: geo.size.width)
                    let isNextLocked = nodes[i + 1].state == .locked
                    
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(isNextLocked ? Color.gray.opacity(0.5) : Color.orange.opacity(0.8),
                            lineWidth: 20)
                }

                // 2. ノード（前面に配置）
                ForEach(Array(nodes.enumerated()), id: \.element.id) { i, node in
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 98, height: 98)
                            .offset(y: 3)
                        // 実際のノードボタン
                        nodeView(for: node)
                    }
                    .position(center(i, width: geo.size.width))
                }
            }
        }
        .frame(height: CGFloat(nodes.count) * rowHeight)
    }

    private func center(_ i: Int, width: CGFloat) -> CGPoint {
        CGPoint(
            x: width * 0.5,
            y: CGFloat(i) * rowHeight + rowHeight / 2
        )
    }

    @ViewBuilder
    private func nodeView(for node: MapNode) -> some View {
        switch node.type {
        default: lessonNode(node)
        }
    }

    private func lessonNode(_ node: MapNode) -> some View {
        let isLocked = node.state == .locked
        let size: CGFloat = 100
        return Button { onTap(node) } label: {
            ZStack {
                Circle()
                    .fill(isLocked ? Color.gray : Color.orange)
                    .frame(width: size, height: size)
                    .offset(y: 3)
                    .shadow(radius: 3)
                Image(systemName: node.type == .practice ? "dumbbell.fill" : "star.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MapView: View {
    @State private var stats = MapHeaderStats(streak: 852, gems: 452, lives: 25)
    @State private var selectedTraining: Training? = nil
    @State private var showWorkout = false

    let sections: [SectionData] = MapView.mockSections()

    var body: some View {
        VStack(spacing: 0) {
            mapHeader
            Divider()
            scrollMap
            Divider()
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $showWorkout) {
            if let training = selectedTraining {
                WorkoutView(
                    training: training,
                    timerDuration: 30.0,
                    currentXP: stats.gems,
                    earnedXP: 50
                )
            }
        }
    }

    // MARK: Header
    private var mapHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: 20) {
                statItem(icon: "flame.fill",
                         iconColor: .gray.opacity(0.6),
                         value: stats.streak,
                         valueColor: .primary.opacity(0.5))

                statItem(icon: "bolt.fill",
                         iconColor: Color(.orange),
                         value: stats.lives,
                         valueColor: Color(.orange))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func statItem(icon: String, iconColor: Color, value: Int, valueColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20, weight: .bold))
            Text("\(value)")
                .font(.system(.body, design: .rounded).weight(.bold))
                .monospacedDigit()
        }
    }

    private var scrollMap: some View {
        ScrollView {
            // 1. pinnedViews を指定してヘッダーを固定できるようにします
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sections) { section in
                    ForEach(section.units) { unit in
                        // 2. 各ユニットを Section でラップし，バナーを header に配置します
                        Section(header:
                            unitBanner(unit.info)
                                .padding(.horizontal, 16)
                                .padding(.top, 24)
                                .background(Color(.systemBackground))
                        ) {
                            MapPathView(nodes: unit.nodes) { node in
                                guard node.state != .locked, let t = node.training else { return }
                                selectedTraining = t
                                showWorkout = true
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: Unit Banner
    private func unitBanner(_ unit: UnitInfo) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("セクション \(unit.sectionNumber)・ユニット \(unit.unitNumber)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Text(unit.unitTitle)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 16))

        }
    }

    // MARK: Mock Data
    static func mockSections() -> [SectionData] {
        let t = [
            Training(id: 1, title: "プッシュアップ", category: ["胸", "肩", "腕"]),
            Training(id: 2, title: "上体起こし",     category: ["腹", "有酸素"]),
            Training(id: 3, title: "プランク",       category: ["腹"]),
            Training(id: 4, title: "スクワット",     category: ["脚"]),
        ]
        return [
            SectionData(id: 1, units: [
                UnitData(
                    id: 1,
                    info: UnitInfo(sectionNumber: 1, unitNumber: 1, unitTitle: "基本のフォーム"),
                    nodes: [
                        MapNode(id: 101, type: .lesson,   state: .completed, stars: 0, training: t[0]),
                        MapNode(id: 102, type: .chest,    state: .completed, stars: 0, training: nil),
                        MapNode(id: 103, type: .lesson,   state: .completed, stars: 0, training: t[1]),
                        MapNode(id: 104, type: .lesson,   state: .available, stars: 0, training: t[2]),
                        MapNode(id: 105, type: .boss,     state: .available, stars: 1, training: t[3]),
                        MapNode(id: 106, type: .practice, state: .locked,   stars: 0, training: t[0]),
                    ]
                )
            ]),
        ]
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
