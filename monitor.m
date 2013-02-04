#import <Cocoa/Cocoa.h>
#import "monitor.h"

@implementation Monitor {
    NSTimer *timer;
    NSStatusItem *statusItem;
    NSMenu *statusMenu;
    NSMenuItem *quitMenuItem;
    NSMutableDictionary *menuCommandMap;
}

@synthesize command;

-(int) interval {
    return [timer timeInterval];
}

-(void) setInterval: (int) checkInterval {
    [timer invalidate];
    timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval: checkInterval
                                             target: self
                                           selector: @selector(monitorRoutine)
                                           userInfo: nil
                                            repeats: YES];
}

-(id) init {
    if (self = [super init]) {
        statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength];

        statusMenu = [NSMenu new];
        [statusItem setMenu: statusMenu];
        quitMenuItem = [[NSMenuItem alloc] initWithTitle: @"Quit"
                                                  action: @selector(terminate:)
                                           keyEquivalent: @"q"];

        menuCommandMap = [NSMutableDictionary dictionaryWithCapacity: 10];
    }
    return self;
}

-(id) initWithCommand: (Command *) initCommand andInterval: (int) checkInterval {
    if ([self init]) {
        self.command = initCommand;
        self.interval = checkInterval;
    }
    return self;
}

-(void) start {
    [self monitorRoutine];
}

-(void) monitorRoutine {
    NSData *commandOutput;

    if (command) {
        commandOutput = [command execute];
    }
    else {
        NSLog(@"No command specified.");
        [NSApp terminate: self];
    }

    if (commandOutput) {
        if ([self parseCommandOutputInJSON: commandOutput] != 0) {
            NSLog(@"Command gives incorrect output.");
            [NSApp terminate: self];
        }
    }
}

-(int) parseCommandOutputInJSON: (NSData *) jsonData {
    NSError *e = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData: jsonData
                                                               options: 0
                                                                 error: &e];
    if (jsonObject == nil) {
        NSLog(@"JSON parse error: %@", e);
        return -1;
    }

    [statusItem setTitle: [jsonObject objectForKey: @"text"]];
    NSString *imagePath = [jsonObject objectForKey: @"image"];
    [statusItem setImage: [[NSImage alloc] initWithContentsOfFile: imagePath]];
    [statusItem setToolTip: [jsonObject objectForKey: @"tooltip"]];

    [statusMenu removeAllItems];
    [menuCommandMap removeAllObjects];

    NSArray *menuObjs = [jsonObject objectForKey: @"menus"];
    for (NSDictionary *menuObj in menuObjs) {
        NSString *menuItemTitle = [menuObj objectForKey: @"text"];
        NSString *menuItemCommand = [menuObj objectForKey: @"click"];
        NSString *menuItemKeyboard = [menuObj objectForKey: @"keyboard"];

        NSMenuItem *menuItem;
        if ([menuItemTitle isEqualToString: @"-"]) {
            menuItem = [NSMenuItem separatorItem];
        }
        else if ([menuItemTitle length] > 0) {
            menuItem = [[NSMenuItem alloc] initWithTitle: menuItemTitle
                                                  action: nil
                                           keyEquivalent: menuItemKeyboard];
            if ([menuItemCommand length] > 0) {
                [menuItem setTarget: self];
                [menuItem setAction: @selector(menuAction:)];
                NSNumber *key = [NSNumber numberWithUnsignedInt: [menuItem hash]];
                [menuCommandMap setObject: menuItemCommand forKey: key];
            }
        }

        [statusMenu addItem: menuItem];
    }

    if ([statusMenu numberOfItems] > 0) {
        [statusMenu addItem: [NSMenuItem separatorItem]];
    }
    [statusMenu addItem: quitMenuItem];

    return 0;
}

-(void) menuAction: (id) sender {
    NSNumber *key = [NSNumber numberWithUnsignedInt: [sender hash]];
    Command *menuCommand = [[Command alloc] initWithLaunchString: [menuCommandMap objectForKey: key]];
    [menuCommand execute];
    [self monitorRoutine];
}

@end

/* vim: set ft=objc: */
