import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingSettings = false
    @State private var showingResults = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                StudySmartBackground()

                DocumentUploadView(
                    showingResults: $showingResults,
                    openSettings: { showingSettings = true }
                )
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
                .navigationDestination(isPresented: $showingResults) {
                    if viewModel.analysisResult != nil {
                        AnalysisView()
                    }
                }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: viewModel.analysisResult) { _, newValue in
            if newValue != nil {
                showingResults = true
            }
        }
    }
}
