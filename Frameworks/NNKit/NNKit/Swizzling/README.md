NNKit Swizzling
===============

NNKit provides robust, general-purpose swizzling utilities.

If you think this is a good idea, you should probably stop and make sure that your needs are not a symptom of more severe architectural problems.

Isa Swizzling
-------------

Robust isa swizzling is provided using the `nn_object_swizzleIsa` function. The following conditions must be met:

* The object is an instance of the swizzling class's superclass, or a subclass of the swizzling class's superclass.
* The swizzling class does not add any ivars or non-dynamic properties.

An object has been swizzled by a class if it responds YES to `isKindOfClass:` with the swizzling class as an argument. Protocols can also be used, and queried using `conformsToProtocol:`, as usual.

To avoid any confusion, your swizzling class should not implement an allocator or initializer. They will never be called for swizzled objects.

### Usage ###

First, you'll need to define your swizzling class. For example:

    @interface MYClass : NSObject <NSDog>
    @property (nonatomic, readonly) NSUInteger random;
    - (void)duck;
    @end
    
    @implementation MYClass
    - (NSUInteger)random { return 7; }
    - (void)duck { NSLog(@"quack!"); }
    - (void)dog { NSLog(@"woof!"); }
    @end

To swizzle your object and use its newfound functionality, just call `nn_object_swizzleIsa`:

    #import <NNKit/nn_isaSwizzling.h>
        
    @implementation MYCode
    - (void)main {
        NSObject *bar = [[NSObject alloc] init];
        nn_object_swizzleIsa(bar, [MYClass class]);
        if ([bar isKindOfClass:[MYClass class]]) {
            [(MYClass *)bar duck];
        }
        if ([bar conformsToProtocol:@protocol(NSDog)]) {
            [(id<MYProtocol>)bar dog];
        }
    }
    @end

See the tests for more explicit examples of what is supposed to work and what is supposed to be an error.

Credits
=======

If not for [Rob Rix](https://github.com/robrix/), the Swizzling component of NNKit would not exist. Which probably would have been a good thing.
