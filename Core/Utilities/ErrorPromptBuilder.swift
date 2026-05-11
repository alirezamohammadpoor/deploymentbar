import Foundation

struct ErrorPromptBuilder {
  static func build(
    deployment: Deployment,
    buildLogTail: [LogLine]?,
    buildLogError: String?,
    failingChecks: [FailingCheckInfo]
  ) -> String {
    var parts: [String] = []
    parts.append("A Vercel deployment failed. Help me identify the root cause and propose a fix.")
    parts.append("")
    parts.append("## Deployment context")
    parts.append("- Project: \(deployment.projectName)")
    parts.append("- Branch: \(deployment.branch ?? "(unknown)")")
    parts.append("- Commit: \(commitLine(for: deployment))")
    parts.append("- Target: \(deployment.target ?? "preview")")
    if let url = deployment.inspectorUrl, !url.isEmpty {
      parts.append("- Inspector: \(url)")
    }

    if deployment.state == .error {
      parts.append("")
      parts.append("## Vercel build error")
      if let lines = buildLogTail, !lines.isEmpty {
        parts.append("Last \(lines.count) log lines:")
        parts.append("")
        parts.append("```")
        parts.append(lines.map(\.text).joined(separator: "\n"))
        parts.append("```")
      } else if let error = buildLogError {
        parts.append("(could not fetch build logs: \(error))")
      } else {
        parts.append("(no build log lines available)")
      }
    }

    if !failingChecks.isEmpty {
      parts.append("")
      parts.append("## Failed CI checks")
      for check in failingChecks {
        let url = check.detailsUrl ?? "(no link)"
        parts.append("- \(check.name): \(url)")
      }
      parts.append("")
      parts.append("(CI job logs live on GitHub Actions at the links above and are not included here.)")
    }

    return parts.joined(separator: "\n")
  }

  private static func commitLine(for deployment: Deployment) -> String {
    let sha = deployment.shortCommitSha ?? "(unknown)"
    if let msg = deployment.commitMessage, !msg.isEmpty {
      return "\(sha) — \"\(msg)\""
    }
    return sha
  }
}
