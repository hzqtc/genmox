#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    [application setDelegate:appDelegate];
    [application run];
  }
  return 0;
}
