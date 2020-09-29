import Foundation

extension Thread {
  typealias Block = @convention(block) () -> Void

  @objc private func nnk_run(block: Block) { block() }

  /**
   Perform block on thread synchronously.

   - parameter block: Work to be executed.
   */
  func sync(_ block: @escaping Block) {
    guard Thread.current != self else { return block() }
    perform(#selector(nnk_run(block:)), on: self, with: block, waitUntilDone: true)
  }
}
