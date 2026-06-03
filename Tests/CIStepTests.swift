import XCTest
@testable import VercelBar

final class CIStepTests: XCTestCase {

  private func check(
    _ name: String,
    id: Int = 1,
    status: String = "queued",
    conclusion: String? = nil
  ) -> GitHubCheckRunDTO {
    GitHubCheckRunDTO(id: id, name: name, status: status, conclusion: conclusion, detailsUrl: nil)
  }

  // MARK: - Status mapping

  func testStatusMapping() {
    XCTAssertEqual(CIStep.status(for: check("lint", status: "queued")), .queued)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "in_progress")), .running)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "success")), .passed)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "failure")), .failed)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "timed_out")), .failed)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "cancelled")), .failed)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "skipped")), .skipped)
    XCTAssertEqual(CIStep.status(for: check("lint", status: "completed", conclusion: "neutral")), .skipped)
  }

  // MARK: - Pipeline assembly

  func testEmptyChecksProducesNoPipeline() {
    XCTAssertTrue(CIStep.pipeline(checks: [], deployState: .ready).isEmpty)
  }

  func testPipelineAppendsSyntheticDeployStep() {
    let steps = CIStep.pipeline(
      checks: [check("lint", status: "completed", conclusion: "success")],
      deployState: .building)
    XCTAssertEqual(steps.count, 2)
    XCTAssertEqual(steps.last?.name, "Deploy")
    XCTAssertEqual(steps.last?.status, .running) // building → running
  }

  func testPipelinePreservesCheckOrderThenDeploy() {
    let names = CIStep.pipeline(
      checks: [check("lint", id: 1), check("test", id: 2), check("build", id: 3)],
      deployState: .ready).map(\.name)
    XCTAssertEqual(names, ["lint", "test", "build", "Deploy"])
  }

  // MARK: - Store retention (additive; aggregate behavior unchanged)

  func testApplyCheckStatusStoresRunsAndPreservesAggregate() {
    let store = DeploymentStore()
    let runs = [check("lint", status: "completed", conclusion: "success")]
    store.applyCheckStatus(.passed, failingChecks: [], checkRuns: runs, for: "dep1")
    XCTAssertEqual(store.checkStatuses["dep1"], .passed)
    XCTAssertEqual(store.checkRuns["dep1"], runs)
    XCTAssertNil(store.failingChecks["dep1"]) // empty failing → not stored

    let failing = [FailingCheckInfo(name: "test", detailsUrl: nil)]
    let runs2 = [check("test", status: "completed", conclusion: "failure")]
    store.applyCheckStatus(.failed, failingChecks: failing, checkRuns: runs2, for: "dep2")
    XCTAssertEqual(store.checkStatuses["dep2"], .failed)
    XCTAssertEqual(store.failingChecks["dep2"], failing)
    XCTAssertEqual(store.checkRuns["dep2"], runs2)

    store.applyCheckStatus(.none, failingChecks: [], checkRuns: [], for: "dep1")
    XCTAssertNil(store.checkRuns["dep1"]) // empty runs → removed
  }
}
