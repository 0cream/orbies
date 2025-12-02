import Dependencies
import Foundation

protocol TaskService: Actor {
    func setup() async
    func getCurrentTask() async -> AppTask?
    func completeTask(_ taskId: String) async
    func isTaskCompleted(_ taskId: String) async -> Bool
    func getAllTasksCompleted() async -> Bool
}

actor LiveTaskService: TaskService {
    
    // MARK: - Private Properties
    
    private var completedTasks: Set<String> = []
    private let allTasks: [AppTask] = [
        AppTask(
            id: "task1",
            signal: "Breakout detected on $WE",
            signalImageName: "we", // Token image instead of emoji
            copy: "• Volume spiked +340% in last 2 minutes\n• 3 whales just accumulated\n• 2.5x potential in 2min",
            tokenName: "We",
            ticker: "$WE",
            cta: "BUY $WE NOW",
            order: 1
        ),
        AppTask(
            id: "task2",
            signal: "Smart money alert on $WT",
            signalImageName: "wt", // Token image instead of emoji
            copy: "• 59 copytraders just bought\n• 2x upside potential in 5min\n• Early window closing",
            tokenName: "Want To",
            ticker: "$WT",
            cta: "BUY $WT",
            order: 2
        ),
        AppTask(
            id: "task3",
            signal: "💎 Index opportunity",
            signalImageName: nil, // Keep emoji for task 3
            copy: "• Combine your tokens in $WWTHN index\n• Fast 5x potential upside\n• 400 holders potential after mint",
            tokenName: nil, // Hidden until reveal
            ticker: "$WWTHN",
            cta: "MINT $WWTHN INDEX",
            order: 3
        )
    ]
    
    // MARK: - Methods
    
    func setup() async {
        print("📋 TaskService: Setup complete")
        print("   Total tasks: \(allTasks.count)")
    }
    
    func getCurrentTask() async -> AppTask? {
        // Return first incomplete task
        let task = allTasks.first { !completedTasks.contains($0.id) }
        print("📋 TaskService: getCurrentTask() called")
        print("   Completed tasks: \(completedTasks.count)")
        print("   Returning task: \(task?.id ?? "nil")")
        return task
    }
    
    func completeTask(_ taskId: String) async {
        completedTasks.insert(taskId)
        print("✅ TaskService: Task \(taskId) completed (\(completedTasks.count)/\(allTasks.count))")
    }
    
    func isTaskCompleted(_ taskId: String) async -> Bool {
        return completedTasks.contains(taskId)
    }
    
    func getAllTasksCompleted() async -> Bool {
        return completedTasks.count == allTasks.count
    }
}

// MARK: - Models

struct AppTask: Equatable, Identifiable {
    let id: String
    let signal: String
    let signalImageName: String? // Image name for the signal icon (nil = use emoji from signal text)
    let copy: String
    let tokenName: String? // Can be nil for hidden tasks
    let ticker: String
    let cta: String
    let order: Int
}

// MARK: - Dependency

extension DependencyValues {
    var taskService: TaskService {
        get { self[TaskServiceKey.self] }
        set { self[TaskServiceKey.self] = newValue }
    }
}

private enum TaskServiceKey: DependencyKey {
    static let liveValue: TaskService = LiveTaskService()
}

