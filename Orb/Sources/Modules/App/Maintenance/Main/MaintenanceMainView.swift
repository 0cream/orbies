import SwiftUI
import ComposableArchitecture

@ViewAction(for: MaintenanceMainFeature.self)
struct MaintenanceMainView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<MaintenanceMainFeature>
    
    // MARK: - UI
    
    var body: some View {
        VStack {
            Text("MaintenanceMain View")
                .font(.title)
            
            // TODO: - Add your view implementation
        }
    }
} 