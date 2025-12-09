import SwiftUI

struct ChatbotView: View {
    @Binding var isPresentedBot: Bool
    @EnvironmentObject var userPreferences: UserPreferences
    @StateObject private var viewModel = ChatbotViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome message
                        if viewModel.messages.isEmpty {
                            WelcomeMessageView()
                        }
                        
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.leading)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(spacing: 12) {
                TextField("Ask about hiking...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .darkGreen : .darkGreen)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        
        
        .navigationTitle("Hiking Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    viewModel.clearConversation()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.darkGreen)
                }
                .disabled(viewModel.messages.isEmpty)
            }
            ToolbarItem(placement: .navigationBarTrailing){
                Button(action: {
                    isPresentedBot = false
                                }){
                                    Image(systemName: "house.fill")
                                        .foregroundColor(.primaryGreen)
                        .controlSize(.large)
                                }
            }
        }
        
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        isInputFocused = false
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
}

// MARK: - View Model

class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []  // Using your existing model!
    @Published var isLoading = false
    
    private let openAIService = OpenAIService()
    private var conversationHistory: [[String: String]] = []
    
    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = ChatMessage(content: text, role: .user)  // Using your model
        await MainActor.run {
            messages.append(userMessage)
            isLoading = true
        }
        
        do {
            // Get AI response
            let response = try await openAIService.askHikingQuestion(
                text,
                conversationHistory: conversationHistory
            )
            
            // Add AI message
            let aiMessage = ChatMessage(content: response, role: .assistant)  // Using your model
            await MainActor.run {
                messages.append(aiMessage)
                isLoading = false
            }
            
            // Update conversation history
            conversationHistory.append(["role": "user", "content": text])
            conversationHistory.append(["role": "assistant", "content": response])
            
        } catch {
            await MainActor.run {
                let errorMessage = ChatMessage(
                    content: "Sorry, I encountered an error: \(error.localizedDescription)",
                    role: .assistant
                )
                messages.append(errorMessage)
                isLoading = false
            }
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        conversationHistory.removeAll()
    }
}

// MARK: - Welcome Message

struct WelcomeMessageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 60))
                .foregroundColor(.primaryGreen)
            
            Text("Hiking Assistant")
                .font(.title2)
                .bold()
            
            Text("Ask me anything about hiking!")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                SuggestionChip(text: "What gear do I need for a day hike?")
                SuggestionChip(text: "How do I prepare for high elevation?")
                SuggestionChip(text: "What are the best trails in Colorado?")
                SuggestionChip(text: "How can I improve my hiking endurance?")
            }
            .padding()
            .background(.borderColor1)
            .cornerRadius(12)
        }
        .padding()
    }
}

struct SuggestionChip: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.lightBlue)
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage  // Using your existing model!
    
    var body: some View {
        HStack {
            if message.role == .user {  // Changed from isUser
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.primaryBlue : Color(.systemGray5))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.primaryBlue)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role != .user {  // Changed from !isUser
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatbotView(isPresentedBot: .constant(true))
            .environmentObject(UserPreferences())
    }
}
