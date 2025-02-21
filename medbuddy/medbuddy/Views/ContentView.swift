import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @State private var showingConsentAlert = false
    @State private var pendingRecording = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Previous Summaries Tab
            SummariesView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.purple)
    }
}

struct HomeView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @State private var showingConsentAlert = false
    @State private var pendingRecording = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "1A1A1A")
                .ignoresSafeArea()
            
            // Listening Overlay
            if viewModel.audioRecorder.isRecording {
                ListeningOverlay()
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 30) {
                // Header
                Text("HOSPITAL BUDDY")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Spacer()
                
                // Summary Card
                if !viewModel.summary.isEmpty {
                    SummaryCard(summary: viewModel.summary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Recording Button and Processing State
                ZStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .frame(width: 85, height: 85)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    RecordButton(isRecording: viewModel.audioRecorder.isRecording) {
                        print("Button tapped, isRecording: \(viewModel.audioRecorder.isRecording)")
                        if viewModel.audioRecorder.isRecording {
                            print("HomeView: Stopping recording")
                            viewModel.stopRecording()
                        } else {
                            print("HomeView: Starting consent flow")
                            pendingRecording = true
                            showingConsentAlert = true
                        }
                    }
                    .disabled(viewModel.isProcessing)
                    .opacity(viewModel.isProcessing ? 0.5 : 1)
                }
                .frame(width: 85, height: 85)
                
                // Status Text
                Text(statusText)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom)
                }
            }
            .padding()
        }
        .animation(.spring(), value: viewModel.summary)
        .sheet(isPresented: $showingConsentAlert) {
            ConsentView(isPresented: $showingConsentAlert) {
                if pendingRecording {
                    viewModel.startRecording()
                    pendingRecording = false
                }
            }
        }
    }
    
    private var statusText: String {
        if viewModel.isProcessing {
            return "Processing your recording..."
        } else if viewModel.audioRecorder.isRecording {
            return "Recording... Tap to stop"
        } else {
            return "Tap the microphone to start recording"
        }
    }
}

struct ListeningOverlay: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: scale
                )
                .onAppear {
                    scale = 1.2
                }
            
            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: 150, height: 150)
            
            Text("Listening")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct SummaryHistoryCard: View {
    let summary: Summary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(summary.timestamp.formatted())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SummariesView: View {
    @StateObject private var summariesStore = SummariesStore.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(summariesStore.summaries) { summary in
                    SummaryHistoryCard(summary: summary)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Previous Summaries")
        }
    }
}

struct SettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            List {
                // About Section
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Developed by CodeBlue")
                            .font(.subheadline)
                        Text("for MedHack 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button(action: {
                        // Share functionality will go here
                    }) {
                        Label("Share Medical Summary", systemImage: "square.and.arrow.up")
                    }
                }
                
                // Profile Section
                Section("Profile") {
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Label("Profile Settings", systemImage: "person.circle")
                            Spacer()
                            if !profileManager.profile.name.isEmpty {
                                Text(profileManager.profile.name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingProfile) {
                ProfileEditView(isPresented: $showingProfile)
            }
        }
    }
}

struct ProfileEditView: View {
    @Binding var isPresented: Bool
    @StateObject private var profileManager = ProfileManager.shared
    @State private var profile: Profile = ProfileManager.shared.profile
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $profile.name)
                    DatePicker("Date of Birth", 
                             selection: $profile.dateOfBirth,
                             displayedComponents: .date)
                    TextField("Phone Number", text: $profile.phoneNumber)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    profileManager.updateProfile(profile)
                    isPresented = false
                }
            )
        }
    }
}

struct ConsentView: View {
    @Binding var isPresented: Bool
    let onAccept: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recording Consent")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You are confirming that consent has been given to record this conversation")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            Button(action: {
                onAccept()
                isPresented = false
            }) {
                Text("I Accept")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
            
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }
}

struct SummaryBox: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(content)
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SummaryCard: View {
    let summary: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(summary)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            .padding()
        }
    }
}

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 85, height: 85)
                
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(isRecording ? .purple : .gray)
                    .overlay {
                        if isRecording {
                            Circle()
                                .stroke(Color.purple, lineWidth: 2)
                                .frame(width: 85, height: 85)
                                .scaleEffect(1.2)
                                .opacity(0.5)
                                .animation(
                                    Animation.easeInOut(duration: 1)
                                        .repeatForever(autoreverses: true),
                                    value: isRecording
                                )
                        }
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
        .frame(width: 85, height: 85)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
} 