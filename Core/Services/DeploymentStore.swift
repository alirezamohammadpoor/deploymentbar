import Combine
import Foundation

final class DeploymentStore: ObservableObject {
  @Published private(set) var deployments: [Deployment] = []
  var onStateChange: ((Deployment, DeploymentState, DeploymentState) -> Void)?

  func apply(deployments: [Deployment]) {
    let previousById = Dictionary(uniqueKeysWithValues: deploymentsById())
    for deployment in deployments {
      if let previous = previousById[deployment.id], previous.state != deployment.state {
        onStateChange?(deployment, previous.state, deployment.state)
      }
    }
    self.deployments = deployments.sorted { $0.createdAt > $1.createdAt }
  }

  private func deploymentsById() -> [(String, Deployment)] {
    deployments.map { ($0.id, $0) }
  }
}

extension DeploymentStore {
  static var mockDeployments: [Deployment] {
    let now = Date()
    return (0..<10).map { index in
      let state: DeploymentState
      switch index % 3 {
      case 0: state = .ready
      case 1: state = .building
      default: state = .error
      }

      return Deployment(
        id: "mock-\(index)",
        projectName: "Project \(10 - index)",
        branch: index % 2 == 0 ? "main" : "feature/alpha",
        state: state,
        url: "project-\(index).vercel.app",
        createdAt: now.addingTimeInterval(TimeInterval(-index * 90)),
        readyAt: state == .ready ? now.addingTimeInterval(TimeInterval(-index * 60)) : nil
      )
    }
  }
}
