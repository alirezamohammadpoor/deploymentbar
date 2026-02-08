import SwiftUI
import AppKit

struct BuildLogWindow: View {
  let deploymentId: String
  let projectName: String
  let openURL: (URL) -> Void

  @StateObject private var viewModel: BuildLogViewModel

  @State private var searchText: String = ""
  @State private var showSearch: Bool = false
  @State private var autoScroll: Bool = true
  @State private var scrollProxy: ScrollViewProxy? = nil

  init(deploymentId: String, projectName: String, openURL: @escaping (URL) -> Void) {
    self.deploymentId = deploymentId
    self.projectName = projectName
    self.openURL = openURL
    self._viewModel = StateObject(wrappedValue: BuildLogViewModel(deploymentId: deploymentId))
  }

  var body: some View {
    VStack(spacing: 0) {
      // Toolbar
      toolbar

      Divider()

      // Log content
      if viewModel.isLoading && viewModel.logLines.isEmpty {
        loadingView
      } else if let error = viewModel.error {
        errorView(error)
      } else if viewModel.logLines.isEmpty {
        emptyView
      } else {
        logContentView
      }
    }
    .frame(minWidth: 400, idealWidth: 600, minHeight: 300, idealHeight: 500)
    .preferredColorScheme(.dark)
    .background(Geist.Colors.backgroundPrimary)
    .task {
      await viewModel.fetchLogs()
    }
  }

  // MARK: - Toolbar

  private var toolbar: some View {
    HStack(spacing: 12) {
      if showSearch {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
          TextField("Search logs...", text: $searchText)
            .textFieldStyle(.plain)
            .font(Geist.Typography.branchName)
          if !searchText.isEmpty {
            Button {
              searchText = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Geist.Colors.gray200)
        .cornerRadius(6)
      }

      Spacer()

      // Jump to first error
      if viewModel.hasErrors {
        Button {
          jumpToFirstError()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 11))
            Text("First Error")
              .font(.system(size: 11))
          }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.red)
      }

      // Auto-scroll toggle
      Toggle(isOn: $autoScroll) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.down.to.line")
            .font(.system(size: 11))
          Text("Auto-scroll")
            .font(.system(size: 11))
        }
      }
      .toggleStyle(.button)
      .controlSize(.small)

      // Search toggle
      Button {
        showSearch.toggle()
        if !showSearch {
          searchText = ""
        }
      } label: {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 11))
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
      .keyboardShortcut("f", modifiers: .command)

      // Copy all
      Button {
        copyAllLogs()
      } label: {
        HStack(spacing: 4) {
          Image(systemName: "doc.on.doc")
            .font(.system(size: 11))
          Text("Copy All")
            .font(.system(size: 11))
        }
      }
      .buttonStyle(.bordered)
      .controlSize(.small)

      // Refresh
      Button {
        Task {
          await viewModel.fetchLogs()
        }
      } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 11))
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
      .disabled(viewModel.isLoading)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Geist.Colors.backgroundSecondary)
  }

  // MARK: - Log Content

  private var logContentView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(filteredLogLines) { line in
            LogLineView(line: line, searchText: searchText)
              .id(line.id)
          }
        }
        .padding(.vertical, 4)
      }
      .onAppear {
        scrollProxy = proxy
      }
      .onChange(of: viewModel.logLines.count) { _, _ in
        if autoScroll, let lastLine = viewModel.logLines.last {
          withAnimation {
            proxy.scrollTo(lastLine.id, anchor: .bottom)
          }
        }
      }
    }
  }

  private var filteredLogLines: [LogLine] {
    if searchText.isEmpty {
      return viewModel.logLines
    }
    return viewModel.logLines.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
  }

  private var loadingView: some View {
    VStack(spacing: 12) {
      ProgressView()
        .scaleEffect(1.5)
      Text("Loading build logs...")
        .font(Geist.Typography.projectName)
        .foregroundColor(Geist.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorView(_ error: String) -> some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 32))
        .foregroundColor(Geist.Colors.statusBuilding)
      Text(error)
        .font(Geist.Typography.projectName)
        .foregroundColor(Geist.Colors.textSecondary)
        .multilineTextAlignment(.center)
      Button("Retry") {
        Task {
          await viewModel.fetchLogs()
        }
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyView: some View {
    VStack(spacing: 12) {
      Image(systemName: "doc.text")
        .font(.system(size: 32))
        .foregroundColor(Geist.Colors.textSecondary)
      Text("No build logs available")
        .font(Geist.Typography.projectName)
        .foregroundColor(Geist.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Actions

  private func jumpToFirstError() {
    if let firstError = viewModel.logLines.first(where: { $0.isError }) {
      withAnimation {
        scrollProxy?.scrollTo(firstError.id, anchor: .center)
      }
    }
  }

  private func copyAllLogs() {
    let text = viewModel.logLines.map { $0.text }.joined(separator: "\n")
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
  }
}

// MARK: - Log Line View

struct LogLineView: View {
  let line: LogLine
  let searchText: String

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      // Line number gutter
      Text("\(line.lineNumber)")
        .font(Geist.Typography.branchName)
        .foregroundColor(Geist.Colors.gray600)
        .frame(width: 40, alignment: .trailing)
        .padding(.trailing, 8)

      // Log text
      Text(attributedText)
        .font(Geist.Typography.branchName)
        .foregroundColor(line.isError ? Geist.Colors.statusError : Geist.Colors.textPrimary)
        .textSelection(.enabled)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 2)
    .background(line.isError ? Color.red.opacity(0.15) : Color.clear)
  }

  private var attributedText: AttributedString {
    var text = AttributedString(line.text)

    // Highlight search matches
    if !searchText.isEmpty {
      var searchRange = text.startIndex..<text.endIndex
      while let range = text[searchRange].range(of: searchText, options: .caseInsensitive) {
        text[range].backgroundColor = .yellow
        text[range].foregroundColor = .black
        searchRange = range.upperBound..<text.endIndex
      }
    }

    return text
  }
}

// MARK: - View Model

@MainActor
final class BuildLogViewModel: ObservableObject {
  let deploymentId: String

  @Published var logLines: [LogLine] = []
  @Published var isLoading: Bool = false
  @Published var error: String?

  var hasErrors: Bool {
    logLines.contains { $0.isError }
  }

  init(deploymentId: String) {
    self.deploymentId = deploymentId
  }

  func fetchLogs() async {
    isLoading = true
    error = nil

    do {
      let (client, teamId) = try APIClientFactory.create()
      let logs = try await client.fetchDeploymentEvents(deploymentId: deploymentId, teamId: teamId)
      logLines = logs
      isLoading = false
    } catch let apiError as APIError {
      error = apiError.userMessage
      isLoading = false
    } catch {
      self.error = "Failed to load logs"
      isLoading = false
    }
  }
}
