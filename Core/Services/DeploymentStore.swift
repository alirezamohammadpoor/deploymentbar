import Combine
import Foundation

final class DeploymentStore: ObservableObject {
  @Published private(set) var deployments: [Deployment] = []

  func apply(deployments: [Deployment]) {
    // TODO: diff and publish updates.
    self.deployments = deployments
  }
}
