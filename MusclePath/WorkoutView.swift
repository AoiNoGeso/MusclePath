import SwiftUI

// トレーニングデータの構造体
struct Training: Identifiable, Codable {
    let id: Int // 種目のID
    let title: String // 種目名
    let category: [String] // 部位別カテゴリのリスト
}

// Workout View
struct WorkoutView: View {
    let training: Training // トレーニングデータ
    let timerDuration: TimeInterval // タイマーの時間 [秒]
    let earnedXP: Int // トレーニングで獲得するXP
    
    @State private var currentXP: Int // 現在のXP
    @State private var hasAddedXP = false // XPアニメーション用のフラグ
    @State private var xpOffset: CGFloat = 0 // XPアニメーションのオフセット
    @State private var xpScale: CGFloat = 1.0 // XPアニメーションのスケール
    @State private var startDate = Date() // タイマー開始時間
    @State private var isStarted = false // トレーニング開始フラグ
    
    init(training: Training, timerDuration: TimeInterval, currentXP: Int, earnedXP: Int) {
        self.training = training
        self.timerDuration = timerDuration
        self.earnedXP = earnedXP
        _currentXP = State(initialValue: currentXP)
    }
    
    // main View
    var body: some View {
        ZStack {
            // ヘッダー
            headerLayer
                .zIndex(2)

            // 準備画面
            if !isStarted { 
                preWorkoutView()
                    .transition(.opacity)
            } 
            // タイマー画面
            else {
                timerLayer
            }
        }
        .animation(.default, value: isStarted)
    }
    
    // ヘッダー
    private var headerLayer: some View {
        VStack {
            HStack {
                Button(action: { onCancel() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.leading, 20)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                        .font(.title)
                    Text("\(currentXP)")
                        .font(.system(.title, design: .rounded).monospacedDigit())
                        .fontWeight(.bold)
                }
                .offset(y: xpOffset)
                .scaleEffect(xpScale)
                .padding(.trailing, 20)
            }
            .padding(.top, 20)
            Spacer()
        }
    }
    
    // タイマー
    private var timerLayer: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let progress = min(elapsed / timerDuration, 1.0)
            let isFinished = progress >= 1.0
            
            if isFinished && !hasAddedXP {
                triggerXPJump()
            }
            
            return ZStack(alignment: .bottom) {
                VStack {
                    Spacer()
                    timerContents(for: context.date, progress: progress)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isFinished {
                    feedbackButtonsView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isFinished)
        }
    }
    
    // 　
    private func preWorkoutView() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                // 種目名
                Text(training.title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                
                // カテゴリータグの表示
                HStack(spacing: 8) {
                    ForEach(training.category, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 100)
            
            // 3Dモデル用ウィンドウ（デモ）
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                
                VStack {
                    Image(systemName: "arkit")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("3D Model: ID \(training.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // スタートボタン
            Button(action: {
                withAnimation {
                    startDate = Date()
                    isStarted = true
                }
            }) {
                Text("スタート！")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // XP獲得時のアニメーション
    private func triggerXPJump() {
        DispatchQueue.main.async {
            guard !hasAddedXP else { return }
            hasAddedXP = true
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                currentXP += earnedXP
                xpOffset = -25
                xpScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    xpOffset = 0
                    xpScale = 1.0
                }
            }
        }
    }
    
    // フィードバックボタンのレイヤー (限界，普通，余裕)
    private func feedbackButtonsView() -> some View {
        VStack(spacing: 12) {
            feedbackButton(label: "限界", color: .red) { onFeedback("hard") }
            feedbackButton(label: "普通", color: .orange) { onFeedback("normal") }
            feedbackButton(label: "余裕", color: .green) { onFeedback("easy") }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
    
    // フィードバックボタンのView
    private func feedbackButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 25).bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color)
                .cornerRadius(12)
                .shadow(color: color.opacity(0.3), radius: 10, y: 5)
        }
    }
    
    // バツを押された時
    private func onCancel() { print("canceled") }
    
    // フィードバック後
    private func onFeedback(_ level: String) { print("Feedback: \(level)") }
    
    // タイマーのビュー
    private func timerContents(for date: Date, progress: Double) -> some View {
        let elapsed = date.timeIntervalSince(startDate)
        let remaining = max(timerDuration - elapsed, 0)
        
        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 24)
            if progress < 1.0 {
                Circle()
                    .trim(from: progress, to: 1.0)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            VStack {
                Text(String(format: "%.0f", ceil(remaining)))
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                Text("SEC")
                    .font(.system(.caption, design: .rounded)).fontWeight(.black)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .offset(y:-70)
    }
}

// プレビュー
#Preview {
    let mockTraining = Training(
        id: 2002,
        title: "プランク",
        category: ["腹", "背中"]
    )
    
    WorkoutView(
        training: mockTraining,
        timerDuration: 5.0,
        currentXP: 1000,
        earnedXP: 50
    )
}
