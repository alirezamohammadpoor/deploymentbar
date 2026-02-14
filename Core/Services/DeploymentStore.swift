import Combine
import Foundation

final class DeploymentStore: ObservableObject {
  @Published private(set) var deployments: [Deployment] = []
  @Published private(set) var checkStatuses: [String: AggregateCheckStatus] = [:]
  var onStateChange: ((Deployment, DeploymentState, DeploymentState) -> Void)?
  var onCheckStatusChange: ((Deployment, AggregateCheckStatus) -> Void)?
  private var didInitialLoad = false

  func apply(deployments: [Deployment]) {
    let previousById = Dictionary(uniqueKeysWithValues: deploymentsById())
    for deployment in deployments {
      if let previous = previousById[deployment.id] {
        if previous.state != deployment.state {
          onStateChange?(deployment, previous.state, deployment.state)
        }
      } else if didInitialLoad, deployment.state == .ready || deployment.state == .error {
        onStateChange?(deployment, .building, deployment.state)
      }
    }
    didInitialLoad = true
    self.deployments = deployments.sorted { $0.createdAt > $1.createdAt }

    // Clean up stale check statuses
    let currentIds = Set(deployments.map(\.id))
    for key in checkStatuses.keys where !currentIds.contains(key) {
      checkStatuses.removeValue(forKey: key)
    }
  }

  func applyCheckStatus(_ status: AggregateCheckStatus, for deploymentId: String) {
    let previous = checkStatuses[deploymentId]
    checkStatuses[deploymentId] = status

    // Fire callback when transitioning from running (or nil) to passed/failed
    if (previous == nil || previous == .running) && (status == .passed || status == .failed) {
      if let deployment = deployments.first(where: { $0.id == deploymentId }) {
        onCheckStatusChange?(deployment, status)
      }
    }
  }

  var deploymentIdsNeedingCheckPoll: [String] {
    deployments.compactMap { deployment in
      guard deployment.state == .ready || deployment.state == .error else { return nil }
      let current = checkStatuses[deployment.id]
      guard current == nil || current == .running else { return nil }
      return deployment.id
    }
  }

  private func deploymentsById() -> [(String, Deployment)] {
    deployments.map { ($0.id, $0) }
  }
}

extension DeploymentStore {
  static var mockDeployments: [Deployment] {
    let now = Date()
    let commitMessages = [
      "fix: resolve hydration error on cart page",
      "feat: add dark mode support",
      "chore: update dependencies",
      "fix: correct typo in login form",
      "feat: implement user profile page",
      "refactor: extract common components",
      "docs: update README with new API",
      "test: add unit tests for auth flow",
      "fix: handle edge case in checkout",
      "feat: add search functionality"
    ]
    let authors = ["Ali K.", "Jane D.", "John S.", "Sarah M.", "Mike B."]

    return (0..<10).map { index in
      let state: DeploymentState
      switch index % 4 {
      case 0: state = .ready
      case 1: state = .building
      case 2: state = .error
      default: state = .queued
      }

      let hasPR = index % 3 == 0

      return Deployment(
        id: "mock-\(index)",
        projectId: "project-\(index)",
        projectName: "Project \(10 - index)",
        branch: index % 2 == 0 ? "main" : "feature/alpha",
        target: index % 2 == 0 ? "production" : nil,
        state: state,
        url: "project-\(index).vercel.app",
        createdAt: now.addingTimeInterval(TimeInterval(-index * 90)),
        readyAt: state == .ready ? now.addingTimeInterval(TimeInterval(-index * 60)) : nil,
        inspectorUrl: "https://vercel.com/team/project-\(index)/mock-\(index)",
        commitMessage: commitMessages[index % commitMessages.count],
        commitAuthor: authors[index % authors.count],
        commitSha: "abc\(index)def\(index)123\(index)456",
        githubOrg: hasPR ? "vercel" : nil,
        githubRepo: hasPR ? "next.js" : nil,
        prId: hasPR ? 42 + index : nil
      )
    }
  }
}
