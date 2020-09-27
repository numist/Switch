// HAXElement.m
// Created by Rob Rix on 2011-01-06
// Copyright 2011 Rob Rix

#import "HAXElement+Protected.h"
#import "HAXButton.h"


@interface HAXElement ()

@property (nonatomic, strong) AXObserverRef observer __attribute__((NSObject));

@end


@implementation HAXElement

-(instancetype)initWithElementRef:(AXUIElementRef)elementRef {
	if((self = [super init])) {
		_elementRef = CFRetain(elementRef);
	}
	return self;
}

-(void)dealloc {
	if (_observer) {
		[self removeAXObserver];
	}
	if (_elementRef) {
		CFRelease(_elementRef);
		_elementRef = NULL;
	}
}

-(BOOL)isEqual:(id)object {
	return
		[object isKindOfClass:self.class]
	&&	CFEqual(self.elementRef, [object elementRef]);
}

-(NSUInteger)hash {
	return CFHash(self.elementRef);
}

-(void)setDelegate:(id<HAXElementDelegate>)delegate {
	if (delegate && !_observer) {
		[self addAXObserver];
	}
	_delegate = delegate;
}

-(id)getAttributeValueForKey:(NSString *)key error:(NSError **)error {
    CFTypeRef result = [self copyAttributeValueForKey:key error:error];
    return result ? CFBridgingRelease(result) : nil;
}

-(CFTypeRef)copyAttributeValueForKey:(NSString *)key error:(NSError **)error {
	NSParameterAssert(key != nil);
	CFTypeRef attributeRef = NULL;
	AXError result = AXUIElementCopyAttributeValue(self.elementRef, (__bridge CFStringRef)key, &attributeRef);
	if((result != kAXErrorSuccess) && error) {
		*error = [NSError errorWithDomain:NSStringFromClass(self.class) code:result userInfo:@{
			@"key": key,
			@"elementRef": (id)self.elementRef}
		];
	}
	return attributeRef;
}

-(BOOL)setAttributeValue:(CFTypeRef)value forKey:(NSString *)key error:(NSError **)error {
	NSParameterAssert(value != nil);
	NSParameterAssert(key != nil);
	AXError result = AXUIElementSetAttributeValue(self.elementRef, (__bridge CFStringRef)key, value);
	if((result != kAXErrorSuccess) && error) {
		*error = [NSError errorWithDomain:NSStringFromClass(self.class) code:result userInfo:@{
			@"key": key,
			@"elementRef": (id)self.elementRef
		}];
	}
	return result == kAXErrorSuccess;
}

-(BOOL)performAction:(NSString *)action error:(NSError **)error {
	NSParameterAssert(action != nil);
	AXError result = AXUIElementPerformAction(self.elementRef, (__bridge CFStringRef)action);
	if ((result != kAXErrorSuccess) && error) {
		*error = [NSError errorWithDomain:NSStringFromClass(self.class) code:result userInfo:@{
			@"action": action,
			@"elementRef": (id)self.elementRef
		}];
	}

	return result == kAXErrorSuccess;
}


-(id)elementOfClass:(Class)klass forKey:(NSString *)key error:(NSError **)error {
	AXUIElementRef subelementRef = (AXUIElementRef)[self copyAttributeValueForKey:key error:error];
	id result = nil;
	if (subelementRef) {
		result = [[klass alloc] initWithElementRef:subelementRef];
		CFRelease(subelementRef);
		subelementRef = NULL;
	}
	return result;
}


-(void)addAXObserver {
	if (self.observer) { return; }
	
	AXObserverRef observer;
	AXError err;
	pid_t pid;
	
	err = AXUIElementGetPid(self.elementRef, &pid);
	if (err != kAXErrorSuccess) { return; }
	
	err = AXObserverCreate(pid, axCallback, &observer);
	if (err != kAXErrorSuccess) { return; }
	
	err = AXObserverAddNotification(observer, self.elementRef, kAXUIElementDestroyedNotification, (__bridge void *)(self));
	if (err != kAXErrorSuccess) {
		CFRelease(observer);
		observer = NULL;
		return;
	}
	
	CFRunLoopAddSource([[NSRunLoop mainRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
	
	self.observer = observer;
	CFRelease(observer);
}

static void axCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
	[(__bridge HAXElement *)refcon didObserveNotification:(__bridge NSString *)notification];
}

-(void)didObserveNotification:(NSString *)notification {
	id<HAXElementDelegate> delegate = self.delegate;
	
	if ([notification isEqualToString:(__bridge NSString *)kAXUIElementDestroyedNotification] && [delegate respondsToSelector:@selector(elementWasDestroyed:)]) {
		[delegate elementWasDestroyed:self];
	}
}

-(void)removeAXObserver {
	if (!self.observer) { return; }
	
	(void)AXObserverRemoveNotification(self.observer, self.elementRef, kAXUIElementDestroyedNotification);
	
	CFRunLoopSourceRef observerRunLoopSource = AXObserverGetRunLoopSource(self.observer);
	if (observerRunLoopSource) {
		CFRunLoopRemoveSource([[NSRunLoop mainRunLoop] getCFRunLoop], observerRunLoopSource, kCFRunLoopDefaultMode);
	}
	
	self.observer = NULL;
}

-(BOOL)hasChildren {
    return (self.children.count > 0);
}

-(NSArray *)children {
    NSArray * axUIElements = nil;
    NSMutableArray * result = nil;
    
    axUIElements = [self getAttributeValueForKey:(__bridge NSString *)kAXChildrenAttribute error:NULL];
    if (axUIElements != nil) {
        result = [NSMutableArray arrayWithCapacity:[axUIElements count]];
        for (id elementI in axUIElements) {
            [result addObject:[[HAXElement alloc] initWithElementRef:(AXUIElementRef)(elementI)]];
        }
    }
    
    return result;
}

-(NSString *)role {
    NSString * result = [self getAttributeValueForKey:(__bridge NSString *)kAXRoleAttribute error:NULL];
    if ([result isKindOfClass:[NSString class]] == NO) {
        result = nil;
    }
    return result;
}

-(NSArray *) buttons {
    NSArray *axChildren = self.children;
    NSMutableArray *result = nil;

    if (axChildren) {
        result = [NSMutableArray arrayWithCapacity:axChildren.count];

        for (HAXElement *haxElementI in axChildren) {
            NSString * axRole = CFBridgingRelease([haxElementI copyAttributeValueForKey:(__bridge NSString *)kAXRoleAttribute error:NULL]);
            if (axRole == nil) {
                result = nil;
                break;
            }
            if ([axRole isEqualToString:(__bridge NSString *)kAXButtonRole]) {
                HAXButton *button = [[HAXButton alloc] initWithElementRef:(AXUIElementRef)haxElementI.elementRef];
                [result addObject:button];
            }
        }
    }

    return result;
}

-(NSString *)title {
    NSString * result = [self getAttributeValueForKey:NSAccessibilityTitleAttribute error:NULL];
    if ([result isKindOfClass:[NSString class]] == NO) {
        result = nil;
    }
    return result;
}

-(NSArray *)attributeNames {
    CFArrayRef attrNamesRef = NULL;
    AXUIElementCopyAttributeNames(_elementRef, &attrNamesRef);
    return attrNamesRef ? CFBridgingRelease(attrNamesRef) : nil;
}

-(pid_t)processIdentifier {
    pid_t result;
    if (AXUIElementGetPid (self.elementRef, &result) != kAXErrorSuccess) { return 0; }
    return result;
}

@end
