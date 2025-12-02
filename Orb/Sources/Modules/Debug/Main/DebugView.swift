import ComposableArchitecture
import SwiftUI

struct DebugView: View {
    
    @Bindable var store: StoreOf<DebugFeature>
    
    var body: some View {
        List {
                Section {
                    Button {
                        store.send(.view(.didTapClearKeychain))
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            
                            Text("Clear Keychain Data")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if store.isClearing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(store.isClearing)
                    
                    Button {
                        store.send(.view(.didTapClearTransactions))
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            
                            Text("Clear Transactions History")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if store.isClearing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(store.isClearing)
                    
                    Button {
                        store.send(.view(.didTapCrash))
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            
                            Text("Crash the App")
                                .foregroundStyle(.red)
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("Debug Actions")
                } footer: {
                    if !store.lastAction.isEmpty {
                        Text(store.lastAction)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Paste JSON with events array:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $store.eventsJSON)
                            .frame(minHeight: 200)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button {
                            store.send(.view(.didTapUpdateEvents))
                        } label: {
                            HStack {
                                if store.isUpdatingEvents {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.up.doc.fill")
                                }
                                
                                Text("Update Articles")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(store.eventsJSON.isEmpty ? Color.gray : Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(store.eventsJSON.isEmpty || store.isUpdatingEvents)
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("News Events (Admin)")
                } footer: {
                    Text("Updates all events via PUT /api/admin/events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shake gesture to open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Use these actions to test app behavior in different states.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
    }
}


