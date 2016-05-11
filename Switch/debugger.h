//
//  debugger.h
//  Debugger
//
//  Created by Scott Perry on 8/11/11.
//  Public domain.
//

#ifdef __OBJC__

#ifndef _DEBUGGER_H_
#define _DEBUGGER_H_

#include <assert.h>
#include <stdbool.h>

// Compatibility with non-clang compilers.
#ifndef __has_builtin
#define __has_builtin(x) 0
#endif

/*
 * The TODO macro allows TODO items to appear as compiler warnings.
 * Always enabled—if you've got something you still need to do, do it before you ship!
 */
#define DO_PRAGMA(x) _Pragma (#x)
#define TODO(x) DO_PRAGMA(message ("TODO - " x))

#ifdef DEBUG
     bool AmIBeingDebugged(void);

    #pragma mark - DebugBreak implementations for all known platforms

    // Legacy implementations of DebugBreak vary considerably based on architecture and platform.
    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        // iOS DebugBreak initial implementations provided by http://iphone.m20.nl/wp/?p=1 (now defunct). This code has been largely rewritten.
        #if defined(__arm__)
            #pragma mark - iOS(arm)

            #define DebugBreak() \
                do { \
                    if(AmIBeingDebugged()) { \
                        __asm__ __volatile__ ( \
                            "mov r0, %0\n" \
                            "mov r1, %1\n" \
                            "mov r12, #37\n" \
                            "swi 128\n" \
                            : : "r" (getpid ()), "r" (SIGINT) : "r12", "r0", "r1", "cc" \
                        ); \
                    } \
                } while (false)

        #elif defined(__i386__) || defined(__x86_64__)
            #pragma mark - iOS(x86)

            #define DebugBreak() \
                do { \
                    if(AmIBeingDebugged()) { \
                        __asm__ __volatile__ ( \
                            "pushl %0\n" \
                            "pushl %1\n" \
                            "push $0\n" \
                            "movl %2, %%eax\n" \
                            "int $0x80\n" \
                            "add $12, %%esp\n" \
                            : : "g" (SIGINT), "g" (getpid ()), "n" (37) : "eax", "cc"); \
                    } \
                } while (false)

        #else
            #pragma mark - iOS(unknown)
            #warning Debugger: Current iOS architecture not supported, please report (Debugger integration disabled)
            #define DebugBreak()
        #endif
    #elif TARGET_OS_MAC
        // Mac DebugBreak initial implementations provided by: http://cocoawithlove.com/2008/03/break-into-debugger.html
        #if defined(__ppc64__) || defined(__ppc__)
            #pragma mark - desktop(ppc)

            #define DebugBreak() \
                if(AmIBeingDebugged()) \
                { \
                    __asm__( \
                        "li r0, 20\n" \
                        "sc\n" \
                        "nop\n" \
                        "li r0, 37\n" \
                        "li r4, 2\n" \
                        "sc\n" \
                        "nop\n" \
                        : : : "memory","r0","r3","r4" \
                    ); \
                }

        #elif defined(__x86_64__) || defined(__i386__)
            #pragma mark - desktop(x86)
            #define DebugBreak() if(AmIBeingDebugged()) {__asm__("int $3\n" : : );}
        #else
            #pragma mark - desktop(unknown)
            #warning Debugger: Current desktop architecture not supported, please report (Debugger integration disabled)
            #define DebugBreak()
        #endif
    #else
        #pragma mark - unknown()
        #warning Debugger: Current platform not supported, please report (Debugger integration disabled)
        #define DebugBreak()
    #endif

#pragma mark - High(er) level debugging macros
    #define NotTested() do { \
                Log(@"NOT TESTED"); \
                DebugBreak(); \
            } while(0)

    // The Log, Assert, and NotReached macros are much more mundane, serving to prevent the incidence of NSLog calls in Release builds, improve logging in Debug builds, and kill the program.
    #ifndef Log
        #define Log(fmt, ...) do { \
                    NSLog(@"%@:%d %@", [[[NSString alloc] initWithCString:(__FILE__) encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__, [NSString stringWithFormat:(fmt), ##__VA_ARGS__]); \
                } while(0)
    #endif

    // The Check and NotTested functions emit a log message and will break a watching debugger if possible.
    #define Check(exp) _InternalCheck((exp), __FILE__, __LINE__, #exp)
    static inline _Bool _InternalCheck(_Bool result, char *filename, unsigned lineno, char *expr) {
        if (!result) {
            Log(@"%s:%u: Failed check `%s` %@", filename, lineno, expr, [NSThread callStackSymbols]);
            DebugBreak();
        }
        return result;
    }

    // Assert is ALWAYS FATAL on DEBUG! If the error was recoverable, you should be using Check() or Bail…Unless()!
    #define Assert(exp) do { \
                if (!(exp)) { \
                    Log(@"Failed assertion `%s`", #exp); \
                    DebugBreak(); \
                    abort(); \
                } \
            } while(0)

    // NotReached is ALWAYS FATAL on DEBUG! If the code path is intentionally reachable, you should be using NotTested()!
    #define NotReached() do { \
                Log(@"Entered THE TWILIGHT ZONE"); \
                DebugBreak(); \
                abort(); \
            } while(0)

    // Macros that affect control flow on condition
    #define BailUnless(exp,return_value) do { \
                if (!(exp)) { \
                    Log(@"Failed check `%s`, bailing.", #exp); \
                    DebugBreak(); \
                    return return_value; \
                } \
            } while(0)
    #define BailWithBlockUnless(exp,block) do { \
                if (!(exp)) { \
                    Log(@"Failed check `%s`, bailing.", #exp); \
                    DebugBreak(); \
                    return block(); \
                } \
            } while(0)
    #define BailWithGotoUnless(exp,label) do { \
                if (!(exp)) { \
                    Log(@"Failed check `%s`, bailing.", #exp); \
                    DebugBreak(); \
                    goto label; \
                } \
            } while(0)
#else // DEBUG
#pragma mark - Debugging stubs
    #define DebugBreak()

    #ifndef Log
        #define Log(...)
    #endif

    #define Check(exp) _InternalCheck((exp), __FILE__, __LINE__, #exp)
    static inline _Bool _InternalCheck(_Bool result, char *filename, unsigned lineno, char *expr) {
        if (!result) {
            Log(@"%s:%u: Failed check `%s`", filename, lineno, expr);
        }
        return result;
    }

    #define NotTested()

    // Assert degrades into an assert on builds without DEBUG defined. (assert can be disabled by defining NDEBUG)
    #define Assert(exp) assert(exp)

    // NotReached is non-fatal on builds without DEBUG defined, but due to the unpredictable nature of code generation around __builtin_unreachable, your app will be unlucky if it survives.
    #if __has_builtin(__builtin_unreachable)
        #define NotReached() __builtin_unreachable()
    #else
        #define NotReached()
    #endif

    // Macros that affect control flow on condition
    #define BailUnless(exp,return_value) do { \
            if (!(exp)) { \
                return return_value; \
            } \
        } while(0)
    #define BailWithBlockUnless(exp,block) do { \
            if (!(exp)) { \
                return block(); \
            } \
        } while(0)
    #define BailWithGotoUnless(exp,label) do { \
            if (!(exp)) { \
                goto label; \
            } \
        } while(0)
#endif // DEBUG

#endif // _DEBUGGER_H_

#endif // __OBJC__
