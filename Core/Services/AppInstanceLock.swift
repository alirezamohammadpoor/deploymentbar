import Foundation

protocol AppInstanceLockToken: AnyObject {}

final class AppInstanceLock: AppInstanceLockToken {
  private let fd: Int32

  private init(fd: Int32) {
    self.fd = fd
  }

  deinit {
    close(fd)
  }

  static func acquire(path: String = "/tmp/vercelbar.lock") -> AppInstanceLock? {
    let fd = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard fd >= 0 else { return nil }

    if flock(fd, LOCK_EX | LOCK_NB) == 0 {
      return AppInstanceLock(fd: fd)
    }

    close(fd)
    return nil
  }
}
