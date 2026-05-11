import XCTest
@testable import VercelBar

final class ErrorPromptBuilderTests: XCTestCase {

  // MARK: - Section presence

  func testHeaderIsAlwaysFirstLine() {
    let prompt = ErrorPromptBuilder.build(
      deployment: makeDeployment(),
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.hasPrefix("A Vercel deployment failed. Help me identify the root cause"))
  }

  func testBuildErrorWithLogsIncludesLogSectionAndOmitsCISection() {
    let deployment = makeDeployment(state: .error)
    let logs = [
      makeLogLine("> npm run build", lineNumber: 1),
      makeLogLine("Error: Cannot find module '@/lib/db'", isError: true, lineNumber: 2),
    ]

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: logs,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("## Vercel build error"))
    XCTAssertTrue(prompt.contains("Last 2 log lines:"))
    XCTAssertTrue(prompt.contains("> npm run build"))
    XCTAssertTrue(prompt.contains("Error: Cannot find module '@/lib/db'"))
    XCTAssertTrue(prompt.contains("```"))
    XCTAssertFalse(prompt.contains("## Failed CI checks"))
  }

  func testCIFailureOnlyOmitsBuildSectionAndListsChecks() {
    let deployment = makeDeployment(state: .ready)
    let failing = [
      FailingCheckInfo(name: "typecheck", detailsUrl: "https://github.com/org/repo/runs/1"),
      FailingCheckInfo(name: "lint", detailsUrl: nil),
    ]

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: failing
    )

    XCTAssertFalse(prompt.contains("## Vercel build error"))
    XCTAssertTrue(prompt.contains("## Failed CI checks"))
    XCTAssertTrue(prompt.contains("- typecheck: https://github.com/org/repo/runs/1"))
    XCTAssertTrue(prompt.contains("- lint: (no link)"))
    XCTAssertTrue(prompt.contains("CI job logs live on GitHub Actions"))
  }

  func testBothFailuresIncludeBothSections() {
    let deployment = makeDeployment(state: .error)
    let logs = [makeLogLine("Build failed")]
    let failing = [FailingCheckInfo(name: "lint", detailsUrl: "https://example.com/run")]

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: logs,
      buildLogError: nil,
      failingChecks: failing
    )

    XCTAssertTrue(prompt.contains("## Vercel build error"))
    XCTAssertTrue(prompt.contains("## Failed CI checks"))
  }

  // MARK: - Log-fetch fallbacks

  func testBuildErrorWithLogFetchFailureSurfacesTheErrorMessage() {
    let deployment = makeDeployment(state: .error)

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: "Network error",
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("## Vercel build error"))
    XCTAssertTrue(prompt.contains("could not fetch build logs: Network error"))
  }

  func testBuildErrorWithNoLogsAndNoFetchErrorFallsBackToPlaceholder() {
    let deployment = makeDeployment(state: .error)

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("no build log lines available"))
  }

  // MARK: - Metadata formatting

  func testCommitLineIncludesShortShaAndQuotedMessage() {
    let deployment = makeDeployment(
      commitMessage: "fix: handle null user",
      commitSha: "a1b2c3def4567"
    )

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("Commit: a1b2c3d — \"fix: handle null user\""))
  }

  func testCommitLineWithoutMessageShowsShortShaOnly() {
    let deployment = makeDeployment(commitMessage: nil, commitSha: "a1b2c3def4567")

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("Commit: a1b2c3d"))
    XCTAssertFalse(prompt.contains("—"))
  }

  func testMissingOptionalFieldsRenderGracefully() {
    let deployment = makeDeployment(
      branch: nil,
      target: nil,
      inspectorUrl: nil,
      commitMessage: nil,
      commitSha: nil
    )

    let prompt = ErrorPromptBuilder.build(
      deployment: deployment,
      buildLogTail: nil,
      buildLogError: nil,
      failingChecks: []
    )

    XCTAssertTrue(prompt.contains("Branch: (unknown)"))
    XCTAssertTrue(prompt.contains("Commit: (unknown)"))
    XCTAssertTrue(prompt.contains("Target: preview"))
    XCTAssertFalse(prompt.contains("Inspector:"))
  }

  // MARK: - Helpers

  private func makeDeployment(
    id: String = "dep_1",
    projectName: String = "my-app",
    branch: String? = "main",
    target: String? = "production",
    state: DeploymentState = .error,
    inspectorUrl: String? = "https://vercel.com/team/my-app/dep_1",
    commitMessage: String? = "fix: handle null user",
    commitSha: String? = "a1b2c3def456"
  ) -> Deployment {
    Deployment(
      id: id,
      projectId: "proj_1",
      projectName: projectName,
      branch: branch,
      target: target,
      state: state,
      url: "my-app-dep1.vercel.app",
      createdAt: Date(timeIntervalSince1970: 1_700_000_000),
      readyAt: nil,
      inspectorUrl: inspectorUrl,
      commitMessage: commitMessage,
      commitAuthor: "Ali",
      commitSha: commitSha,
      githubOrg: "alirezamohammadp",
      githubRepo: "deploymentbar",
      prId: 42
    )
  }

  private func makeLogLine(_ text: String, isError: Bool = false, lineNumber: Int = 1) -> LogLine {
    LogLine(lineNumber: lineNumber, text: text, isError: isError)
  }
}
