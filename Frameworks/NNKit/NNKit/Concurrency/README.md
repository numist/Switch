NNKit Concurrency
=================

NNKit provides tools to help make concurrency less of a headache, following the model of islands of serialization in a sea of concurrency. Since not all code can be expected to follow this model, NNKit also assumes that the only safe manner of passing messages between modules is on the main thread, and recievers are expected to get off the main thread as needed.

NNDelegateProxy
---------------

The `NNDelegateProxy` class provides a mechanism to ensure that all messages sent to a delegate are dispatched on the main thread. 

### Example ###

    // You should already have a protocol for your use of the delegate pattern:
    @protocol MYClassDelegate <NSObject>
    - (void)objectCalledDelegateMethod:(id)obj;
    @end


    @interface MYClass : NSObject

    // And should already have a weak property for your delegate in your class declaration:
    @property (nonatomic, weak) id<MYClassDelegate> delegate;

    // Add a strong reference to a new property, the delegate proxy:
    @property (strong) id<MYClassDelegate> delegateProxy;

    @end

    @implementation MYClass

    - (instancetype)init;
    {
        if (!(self = [super init])) { return nil; }
        
        // Initialize the delegate proxy, feel free to set the delegate later if you don't have one handy.
        _delegateProxy = [NNDelegateProxy proxyWithDelegate:nil protocol:@protocol(MYClassDelegate)];
        
        // …
        
        return self;
    }

    // If you have a writable delegate property, you'll need a custom delegate setter to ensure that the proxy gets updated:
    - (void)setDelegate:(id<MYClassDelegate>)delegate;
    {
        self->_delegate = delegate;
        
        ((NNDelegateProxy *)self.delegateProxy).delegate = delegate;
        // NOTE: A cast is necessary here because the delegateProxy property is typed id<MYClassDelegate> to retain as much static checking as possible elsewhere in your code, which fails here because the compiler doesn't realise that it's still an NNDelegateProxy under the hood.
    }

    - (void)method;
    {
        // Who cares how we got to where we are, or where that even is; when it's time to dispatch a delegate message just send it to the proxy:
        [self.delegateProxy objectCalledDelegateMethod:self];
    }

    @end

This proxy class was inspired by [Andy Matuschak](https://github.com/andymatuschak).
