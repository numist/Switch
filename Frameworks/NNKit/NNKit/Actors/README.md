NNKit Actor Model
=================

The classes in this component solve some common problems encountered when using the actor pattern in Objective-C.

NNCleanupProxy
--------------

A cleanup proxy is used to perform some kind of work after an object is deallocated. The proxy itself can be used as a message forwarder, so long as the methods are pre-declared using `-cacheMethodSignatureForSelector:`. The implementation of [`NSNotificationCenter+NNAdditions`](https://github.com/numist/NNKit/blob/master/NNKit/API%20Extension/NSNotificationCenter%2BNNAdditions.m) uses a cleanup proxy to provide its functionality.

NNMultiDispatchManager
----------------------

The multi-dispatch manager is a new mechanism to enable structured to-many message dispatch. Instead of using global notifications, which are very error-prone with magic keys into parochial `userInfo` dictionaries, multi-dispatch acts more like a delegate where observers conform to a common protocol, and messages belonging to that protocol that are sent to the multi-dispatch manager are forwarded to all of the observers. All protocol methods must return `void`, and methods decorated with `oneway` are dispatched asynchronously. All dispatch messages are sent on the main thread, and messages sent to the multi-dispatch manager can be sent on any thread.

#### Example: ####

``` objective-c
//
// Interface
//

@protocol MyProtocol <NSObject>
- (oneway void)foo:(id)bar;
@end


@interface MyDispatcher : NSObject

- (void)addObserver:(id<MyProtocol>)observer;
- (void)removeObserver:(id<MyProtocol>)observer;

@end

@interface MyObserver : NSObject <MyProtocol>

@end


//
// Implementation
//

@interface MyDispatcher ()

@property (nonatomic, strong, readonly) NNMultiDispatchManager *dispatchManager;

@end

@implementation MyDispatcher

+ (instancetype)sharedDispatcher;
{
    static MyDispatcher *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [MyDispatcher new];
    });
    return singleton;
}

- (id)init;
{
    if (!(self = [super init])) { return nil; }
    
    _dispatchManager = [[NNMultiDispatchManager alloc] initWithProtocol:@protocol(MyProtocol)];

    return self;
}

- (void)addObserver:(id<MyProtocol>)observer;
{
    [self.dispatchManager addObserver:observer];
}

- (void)removeObserver:(id<MyProtocol>)observer;
{
    [self.dispatchManager removeObserver:observer];
}

- (void)dispatchEvent;
{
    [(id<MyProtocol>)self.dispatchManager foo:[NSObject new]];
}

@end


@implementation MyObserver

- (id)init;
{
    if (!(self = [super init])) { return nil; }

    // There's no need to removeObserver in dealloc, since NNMultiDispatchManager references observers weakly.
    [[MyDispatcher sharedDispatcher] addObserver:self];

    return self;
}

- (oneway void)foo:(id)bar;
{
    // …
}

@end
```

NNPollingObject
---------------

Sometimes there is no way to have information pushed to you, and it has to be checked occasionally by a polling object. This base class provides basic interval and queue priority support with a polling worker thread that terminates when the object is released.

Subclasses need only override `-main` to use, and it's recommended that the built in `-postNotification:` method be used to emit events to interested parties. The `interval` property can be set to any time interval, with values less than or equal to zero causing the worker thread to terminate when it has finished its next scheduled iteration.

NNSelfInvalidatingObject
------------------------

Some objects may encapsulate resources that require work to clean up, such as an open file handle. In some cases, these operations can take time or may otherwise require that the actor be alive for an extended period of time after its owner has released it. Subclassing `NNSelfInvalidatingObject` allows this condition to be handled easily. Simply override `-invalidate`, and it is called asynchronously on the main queue once the internal refCount of the object has reached zero. When cleanup is complete, calling `[super invalidate]` puts the object in the nearest autorelease pool and it is finally destroyed on the next iteration of the runloop. Calling `[self invalidate]` early prevents it from being called when the object refCount reaches zero (the object is destroyed immediately).

This base class was inspired by [Andy Matuschak](https://github.com/andymatuschak).
