//
//  main.m
//  relaunch
//
//  Created by Scott Perry on 03/11/14.
//  Copyright © 2014 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Inspiration from relaunch.m: https://github.com/andymatuschak/Sparkle/blob/7316a00e9c92f54c552076a44c38241c0f1bf975/relaunch.m
//

#import "SWTerminationListener.h"


int main (int argc, const char * argv[])
{
    if (argc != 3) { return EXIT_FAILURE; }

    @autoreleasepool {
        [NSApplication sharedApplication];

        static SWTerminationListener *listener;
        listener = [[SWTerminationListener alloc] initWithExecutablePath:argv[1] parentProcessId:atoi(argv[2])];
        
        [[NSApplication sharedApplication] run];
    }

    return EXIT_SUCCESS;
}
