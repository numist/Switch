NNKit Services
==============

NNKit provides a framework for services running in your application, including dependency management, subscriber and observer dispatch, automatic starting and stopping of services based on subscriptions, and an easy mechanism to register all the services in your application in your app delegate, keeping your code small and readable.

What makes a service
--------------------

Services are classes that inherit from `NNService` and respond to `serviceType` with a type other than `NNServiceTypeNone`. The other two types are:

* `NNServiceTypePersistent`: the service will run as long as its dependencies (if any) are running.
* `NNServiceTypeOnDemand`: the service will run as long as its dependencies (if any) are running and at least one object has subscribed to the service using the service manager's `addSubscriber:forService:` method.

Dependency management
---------------------

Service dependencies are defined by the `dependencies` method, which returns an NSSet of class objects. Dependencies that are not already known to the service manager will be added automatically if possible.

Subscriber (and observer) message dispatch
------------------------------------------

Services whose instances dispatch messages to their subscribers must respond to `subscriberProtocol` with the appropriate protocol. Subscribers must conform to this protocol and will be checked at runtime. Sending a message to subscribers can be accomplished with code resembling the following:

``` objective-c
- (void)sendMessage;
{
    [(id<MYSubscriberProtocol>)self.subscriberDispatcher serviceWillDoThing:self];
}
```

Convenience hacks
-----------------

Automatically adding all services known to the runtime is accomplished by calling `registerAllPossibleServices` on a service manager, preferably the `sharedManager`.

Would you like to know more?
----------------------------

For a deeper dive into services, check out the [unit tests](https://github.com/numist/NNKit/blob/master/NNKitTests/NNServiceTests.m).
