import SwiftUI

struct CancelGuide: Codable {
    let steps: [String]
    let url: String
}

struct CancelGuideView: View {
    let subscriptionName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var guide: CancelGuide?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let guide = guide {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Steps to Cancel")
                            .font(.headline)
                        
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.blue))
                                
                                Text(step)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                    
                    if let url = URL(string: guide.url) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Open Cancellation Page", systemImage: "arrow.up.right.square")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No specific guide for \(subscriptionName)")
                            .font(.headline)
                        Text("Try searching for 'cancel \(subscriptionName)' in your browser or look for account settings in the app.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                        
                        Button {
                            let query = "how to cancel \(subscriptionName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "https://www.google.com/search?q=\(query)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Search on Google", systemImage: "magnifyingglass")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Cancel \(subscriptionName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            loadGuide()
        }
    }
    
    private func loadGuide() {
        guard let url = Bundle.main.url(forResource: "CancelGuides", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let guides = try? JSONDecoder().decode([String: CancelGuide].self, from: data) else {
            return
        }
        
        // Try exact match or fuzzy match
        if let directGuide = guides[subscriptionName] {
            self.guide = directGuide
        } else {
            // Fuzzy match: check if any key is contained in subscriptionName or vice versa
            let match = guides.first { key, _ in
                subscriptionName.localizedCaseInsensitiveContains(key) || key.localizedCaseInsensitiveContains(subscriptionName)
            }
            self.guide = match?.value
        }
    }
}

#Preview {
    CancelGuideView(subscriptionName: "Netflix")
}
