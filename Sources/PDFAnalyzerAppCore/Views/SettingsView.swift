import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAPIKey = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: API Key
                Section {
                    HStack {
                        if showingAPIKey {
                            TextField("API Anahtarı", text: $viewModel.apiKey)
                                .autocorrectionDisabled()
                                #if os(iOS)
                                .textInputAutocapitalization(.never)
                                #endif
                        } else {
                            SecureField("API Anahtarı", text: $viewModel.apiKey)
                        }
                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.apiKey.isEmpty {
                        Label(
                            "API anahtarı gerekli. Gemini API anahtarınızı girin.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    } else {
                        Label("API anahtarı ayarlandı.", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Gemini API Anahtarı")
                } footer: {
                    Text("API anahtarınızı Google AI Studio'dan (aistudio.google.com) ücretsiz alabilirsiniz.")
                }

                // MARK: Model
                Section {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(modelDisplayName(model)).tag(model)
                        }
                    }
                } header: {
                    Text("Gemini Modeli")
                } footer: {
                    Text(modelDescription(viewModel.selectedModel))
                }

                // MARK: About
                Section("Hakkında") {
                    LabeledContent("Uygulama", value: "PDF Analiz")
                    LabeledContent("Sürüm", value: "1.0.0")
                    LabeledContent("Yapay Zeka", value: "Google Gemini API")
                }

                // MARK: Danger zone
                Section {
                    Button(role: .destructive) {
                        viewModel.clearAll()
                        dismiss()
                    } label: {
                        Label("Tüm Verileri Temizle", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func modelDisplayName(_ model: String) -> String {
        switch model {
        case "gemini-3.1-flash":      return "Gemini 3.1 Flash (Önerilen)"
        case "gemini-3.1-pro":        return "Gemini 3.1 Pro"
        case "gemini-3.1-flash-lite": return "Gemini 3.1 Flash Lite"
        case "gemini-3.1-flash-image": return "Gemini 3.1 Flash Image"
        default:                      return model
        }
    }

    private func modelDescription(_ model: String) -> String {
        switch model {
        case "gemini-3.1-flash":
            return "Hızlı ve yetenekli. Çoğu belge için idealdir."
        case "gemini-3.1-pro":
            return "En yüksek kalite. Büyük belgeler için uygundur, ancak daha yavaş olabilir."
        case "gemini-3.1-flash-lite":
            return "Dengeli hız ve kalite. Hafif belgeler için uygundur."
        case "gemini-3.1-flash-image":
            return "Görsel içerikli belgeler için optimize edilmiştir."
        default:
            return ""
        }
    }
}
