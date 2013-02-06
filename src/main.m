#import <Cocoa/Cocoa.h>
#import "monitor.h"

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];

        NSArray *processArgs =  [[NSProcessInfo processInfo] arguments];
        if ([processArgs count] != 3) {
            printf("Usage: %s [interval] '[command]'\n", [[processArgs objectAtIndex: 0] UTF8String]);
            return 1;
        }
        Command *command = [[Command alloc] initWithLaunchString: [processArgs objectAtIndex: 2]];
        Monitor *monitor = [[Monitor alloc] initWithCommand: command
                                                andInterval: [[processArgs objectAtIndex: 1] intValue]];
        [monitor start];

        [NSApp run];
    }
    return 0;
}
