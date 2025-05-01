#import <Cocoa/Cocoa.h>
#import "monitor.h"

@implementation Monitor {
    NSTimer *timer;
    NSStatusItem *statusItem;
    NSStatusBarButton *statusBarButton;
    NSMenu *statusMenu;
    NSMenuItem *updateMenuItem;
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
        statusBarButton = statusItem.button;

        statusMenu = [NSMenu new];
        [statusItem setMenu: statusMenu];
        updateMenuItem = [[NSMenuItem alloc] initWithTitle: @"Update Now"
                                                    action: @selector(updateMenuAction:)
                                             keyEquivalent: @""];
        [updateMenuItem setTarget: self];
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

-(void) updateMenuAction: (id) sender {
    [self monitorRoutine];
}

-(void) monitorRoutine {
    NSData *commandOutput;

    if (command) {
        NSLog(@"Execute command: %@", [command description]);
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
    else {
        [NSApp terminate: self];
    }
}

-(int) parseCommandOutputInJSON: (NSData *) jsonData {
    NSError *e = nil;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData: jsonData
                                                               options: 0
                                                                 error: &e];
    if (jsonObject == nil) {
        NSLog(@"JSON parse error: %@", e);
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"JSON output: %@", jsonString);
        return -1;
    }

    statusBarButton.title = [jsonObject objectForKey: @"text"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile: [jsonObject objectForKey: @"image"]];
    image.template = YES;
    NSImage *altImage = [[NSImage alloc] initWithContentsOfFile: [jsonObject objectForKey: @"altimage"]];
    altImage.template = YES;
    statusBarButton.image = image;
    statusBarButton.alternateImage = altImage;
    statusBarButton.toolTip = [jsonObject objectForKey: @"tooltip"];

    [statusMenu removeAllItems];
    [menuCommandMap removeAllObjects];

    NSArray *menuObjs = [jsonObject objectForKey: @"menus"];
    NSArray<NSMenuItem *> *menuItems = [self getMenuItems:menuObjs];
    for (NSMenuItem *item in menuItems) {
      [statusMenu addItem: item];
    }

    if ([statusMenu numberOfItems] > 0) {
        [statusMenu addItem: [NSMenuItem separatorItem]];
    }
    [statusMenu addItem: updateMenuItem];
    [statusMenu addItem: quitMenuItem];

    return 0;
}

-(NSArray<NSMenuItem *> *) getMenuItems: (NSArray *) menuObjs  {
    NSMutableArray<NSMenuItem *> *menuItems = [NSMutableArray array];
    for (NSDictionary *menuObj in menuObjs) {
        NSString *menuItemTitle = [menuObj objectForKey: @"text"];
        NSString *menuItemCommand = [menuObj objectForKey: @"click"];
        NSString *menuItemKeyboard = [menuObj objectForKey: @"keyboard"];
        NSString *menuItemChecked = [menuObj objectForKey: @"checked"];
        NSArray *submenuObjs = [menuObj objectForKey: @"submenus"];

        NSMenuItem *menuItem;
        if ([menuItemTitle isEqualToString: @"-"]) {
            menuItem = [NSMenuItem separatorItem];
        }
        else if ([menuItemTitle length] > 0) {
            menuItem = [[NSMenuItem alloc] initWithTitle: menuItemTitle
                                                  action: nil
                                           keyEquivalent: menuItemKeyboard];
            if ([menuItemCommand length] > 0) {
                menuItem.target = self;
                menuItem.action = @selector(menuAction:);
                NSNumber *key = [NSNumber numberWithUnsignedInt: [menuItem hash]];
                [menuCommandMap setObject: menuItemCommand forKey: key];
            }

            if (menuItemChecked && [menuItemChecked caseInsensitiveCompare:@"true"] == NSOrderedSame) {
                menuItem.state = NSControlStateValueOn;
            }

            if (submenuObjs && submenuObjs.count > 0) {
              NSMenu *submenu = [NSMenu new];
              NSArray<NSMenuItem *> *submenuItems = [self getMenuItems: submenuObjs];
              for (NSMenuItem *item in submenuItems) {
                [submenu addItem: item];
              }
              menuItem.submenu = submenu;
            }
        }

        if (menuItem) {
            [menuItems addObject: menuItem];
        }
    }
    return [menuItems copy];
}

-(void) menuAction: (id) sender {
    NSNumber *key = [NSNumber numberWithUnsignedInt: [sender hash]];
    Command *menuCommand = [[Command alloc] initWithLaunchString: [menuCommandMap objectForKey: key]];
    [menuCommand execute];
}

@end

/* vim: set ft=objc: */
