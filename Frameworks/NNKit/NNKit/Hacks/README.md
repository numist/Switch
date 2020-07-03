NNKit Hacks
===========

This portion of NNKit contains things that, while well-tested and reliable, shouldn't pass a sane person's test for acceptable complexity per unit utility.

Automatically Freed C Buffers
-----------------------------

Have a complicated function with a lot of logic and early returns? Avoid the possibility of forgetting to free your buffers with `nn_autofree`!

    @autoreleasepool {
        int *foo = nn_autofree(malloc(size));
    }

Don't forget, you're still in charge of NULLing your pointers, so it's easiest if you create your own autorelease pool, which will also create an extra scope for the buffer's pointer which it can't escape.

Strongified Property Access
---------------------------

Weak properties can be accessed with autoreleasing getters by either inheriting from or isa-swizzling `NNStrongifiedProperties`.

    @interface WeakDemo : NNStrongifiedProperties
    @property (weak) id foo;
    @end

    @interface WeakDemo (StrongAccessors)
    - (id)strongFoo;
    @end

    @implementation WeakDemo
    @end

    int main() {
        // Whenever you need an autoreleased reference to foo:
        [[WeakDemo new] strongFoo]
    }

If you already inherit from a more useful class, this behaviour can be "learned" by an existing object by using isa swizzling:

    @interface WeakDemo : NSObject
    @property (weak) id foo;
    @end

    @interface WeakDemo (StrongAccessors)
    - (id)strongFoo;
    @end

    @implementation WeakDemo
    @end

    int main() {
        id obj = [WeakDemo new];
        nn_object_swizzleIsa(obj, [NNStrongifiedProperties class]);

        // Whenever you need an autoreleased reference to foo:
        [obj strongFoo]
    }

This hack was concieved after enabling the `-Wreceiver-is-weak` warning in clang and learning about the race condition it polices.
