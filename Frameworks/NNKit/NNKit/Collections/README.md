# NNKit Collections #

The code in this component gives collections superpowers.

## Category: NNComprehensions ##

The `NNComprehensions` category on `NSArray`, `NSSet`, and `NSOrderedSet` implements the following comprehensions:

### nn_filter: ###
Returns a new collection of the same (immutable) type that contains a subset of the items in the original array, as chosen by the method's argument, a block that takes an `id` and returns a `BOOL`.

#### Example: ####
``` objective-c
// Returns @[@3, @6, @9]
[@[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10] nn_filter:^(id item){ return (BOOL)!([item integerValue] % 3); }];
```

### nn_map: ###
Returns a new collection of the same (immutable) type that contains new values based on the result of the block parameter, which takes an id and returns an id.

Returning `nil` from the block is not supported. A separate filter step should be used first to remove unwanted items from the collection.

#### Example: ####
``` objective-c
// Returns @[@2, @4, @6, @8, @10, @12, @14, @16, @18, @20]
[@[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10] nn_map:^(id item){ return @([item integerValue] * 2); }];
```

### nn_reduce: ###
Returns a reduction of the collection as defined by the block parameter, which takes an accumulator value (an `id` which starts as nil) and an item and returns the new value of the accumulator.

#### Example: ####
``` objective-c
// Returns @55
[@[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10] nn_reduce:^(id acc, id item){ return @([acc integerValue] + [item integerValue]); }];
```
