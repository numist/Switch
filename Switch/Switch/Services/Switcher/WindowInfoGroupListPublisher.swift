import Combine
import Foundation

struct WindowInfoGroupListPublisher: Publisher {
  typealias Output = [WindowInfoGroup]
  typealias Failure = Never // TODO: not strictly true if AX is disabled?

  func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
    let subscription = WindowInfoGroupListSubscription<S>()
    subscription.target = subscriber
    subscriber.receive(subscription: subscription)
    subscription.poll()
  }

  class WindowInfoGroupListSubscription<Target: Subscriber>: Subscription where Target.Input == Output {
    var target: Target?

    func request(_ demand: Subscribers.Demand) {
      // TODO: I'm sure there's a right thing to do wrt demand but I'm not doing it yet
      assert(demand == .unlimited)
    }

    func cancel() { target = nil }

    private func publish(_ list: [WindowInfoGroup]) {
      assert(Thread.isMainThread)
      guard let target = target else { return }

      // TODO: I'm sure there's a right thing to do wrt demand but I'm not doing it yet
      _ = target.receive(list)

      // Enqueue the next call
      self.poll(after: 0.1)
    }

    fileprivate func poll(after delay: TimeInterval = 0.0) {
      assert(Thread.isMainThread)

      // Reflect onto background thread for window list polling (it's slow, >20ms)
      DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
        let list = WindowInfoGroup.list(from: WindowInfo.get())

        // Reflect back onto main thread for publisher dispatch
        DispatchQueue.main.async {  self?.publish(list) }
      }
    }
  }
}
