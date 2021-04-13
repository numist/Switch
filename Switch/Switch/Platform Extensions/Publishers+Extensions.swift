import Combine

// swiftlint:disable nesting

extension Publishers {
  class SubscribersCounterPublisher<Upstream: Publisher>: Publisher {
    var hasSubscribers: Bool { return subscriberCount > 0 }
    private var subscriberCount = 0
    private let upstream: Upstream
    private let callback: ((Int) -> Void)?

    init(upstream: Upstream, callback: ((Int) -> Void)? = nil) {
      self.upstream = upstream
      self.callback = callback
    }

    private func increase() {
      subscriberCount += 1
      self.callback?(subscriberCount)
    }

    private func decrease() {
      subscriberCount -= 1
      self.callback?(subscriberCount)
    }

    // MARK: Publisher conformance

    typealias Output = Upstream.Output
    typealias Failure = Upstream.Failure

    func receive<S: Subscriber>(subscriber: S)
    where Upstream.Failure == S.Failure, Upstream.Output == S.Input {
      self.increase()
      upstream.receive(
        subscriber: SubscribersCounterSubscriber<S>(
          counter: self,
          subscriber: subscriber
        )
      )
    }

    // MARK: -
    private class SubscribersCounterSubscriber<S: Subscriber>: Subscriber {
      private let counter: SubscribersCounterPublisher<Upstream>
      private let subscriber: S

      init (counter: SubscribersCounterPublisher<Upstream>, subscriber: S) {
        self.counter = counter
        self.subscriber = subscriber
      }

      // MARK: Subscriber conformance

      typealias Input = S.Input
      typealias Failure = S.Failure

      func receive(subscription: Subscription) {
        subscriber.receive(
          subscription: SubscribersCounterSubscription<Upstream>(
            counter: counter,
            subscription: subscription
          )
        )
      }

      func receive(_ input: S.Input) -> Subscribers.Demand {
        return subscriber.receive(input)
      }

      func receive(completion: Subscribers.Completion<S.Failure>) {
        subscriber.receive(completion: completion)
      }
    }

    // MARK: -
    private class SubscribersCounterSubscription<Upstream: Publisher>: Subscription {
      let counter: SubscribersCounterPublisher<Upstream>
      let wrapped: Subscription
      private var cancelled = false

      init(counter: SubscribersCounterPublisher<Upstream>, subscription: Subscription) {
        self.counter = counter
        self.wrapped = subscription
      }

      deinit { if !cancelled { counter.decrease() } }

      // MARK: Subscription conformance

      func request(_ demand: Subscribers.Demand) { wrapped.request(demand) }

      func cancel() {
        precondition(!cancelled)
        wrapped.cancel()
        counter.decrease()
        cancelled = true
      }
    }
  }
}
