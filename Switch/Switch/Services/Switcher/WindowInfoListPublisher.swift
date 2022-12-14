import Combine
import Foundation

final class WindowInfoListPublisher: Publisher {
  static let shared = WindowInfoListPublisher()

  private typealias Subject = PassthroughSubject<Output, Failure>

  private let subject: Subject
  private let counter: Publishers.SubscribersCounterPublisher<Subject>

  private var timer: Timer?
  private var workInProgress = false

  private init() {
    assert(Thread.isMainThread)
    subject = PassthroughSubject<Output, Failure>()
    counter = Publishers.SubscribersCounterPublisher<Subject>(upstream: subject)
  }

  private func startPoll() {
    assert(Thread.isMainThread)

    guard counter.hasSubscribers else { return }
    guard !workInProgress else { return }

    timer?.invalidate()
    timer = nil

    workInProgress = true

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let list = WindowInfo.get()
      DispatchQueue.main.async {
        self?.completePoll(with: list)
      }
    }
  }

  private func completePoll(with result: [WindowInfo]) {
    assert(Thread.isMainThread)

    self.workInProgress = false

    if self.counter.hasSubscribers {
      // Schedule another iteration
      self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] _ in
        guard let self = self else { return }
        self.timer = nil
        self.startPoll()
      })

      self.subject.send(result)
    }
  }

  // MARK: Publisher conformance
  typealias Output = [WindowInfo]
  typealias Failure = Never // TODO(numist): not strictly true if AX is disabled?

  func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
    assert(Thread.isMainThread)
    counter.receive(subscriber: subscriber)
    startPoll()
  }
}
