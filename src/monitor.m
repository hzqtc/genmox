#import <Cocoa/Cocoa.h>
#import "monitor.h"

@implementation Monitor {
  NSTimer *timer;
  NSStatusItem *statusItem;
  NSStatusBarButton *statusBarButton;
  NSMenu *statusMenu;
  NSMenuItem *updateMenuItem;
  NSMenuItem *quitMenuItem;
  // A map from menu item hash to command
  NSMutableDictionary *menuCommandMap;
  // A set of menu items that would trigger a refresh after executing
  NSMutableSet *refreshingMenuItems;
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
    updateMenuItem = [[NSMenuItem alloc] initWithTitle: @"Refresh"
                                                action: @selector(updateMenuAction:)
                                         keyEquivalent: @"r"];
    [updateMenuItem setTarget: self];
    quitMenuItem = [[NSMenuItem alloc] initWithTitle: @"Quit"
                                              action: @selector(terminate:)
                                       keyEquivalent: @"q"];

    menuCommandMap = [NSMutableDictionary dictionaryWithCapacity: 100];
    refreshingMenuItems = [NSMutableSet setWithCapacity: 100];
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
    return -1;
  }

  NSString *title = [jsonObject objectForKey: @"text"];
  if (title == nil) {
    NSLog(@"text is missing");
    return -1;
  }

  NSString *textColor = [jsonObject objectForKey: @"textcolor"];
  if (textColor != nil) {
    NSDictionary *attributes = @{
      NSForegroundColorAttributeName: [self colorFromHexString: textColor],
                 NSFontAttributeName: [NSFont systemFontOfSize: [NSFont systemFontSize]]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString: title
                                                                          attributes: attributes];
    statusBarButton.attributedTitle = attributedTitle;
  } else {
    statusBarButton.title = title;
  }

  NSString *imageSymbol = [jsonObject objectForKey: @"imagesymbol"];
  NSString *imagePath = [jsonObject objectForKey: @"image"];
  NSImage *image;
  if (imageSymbol != nil) {
    image = [NSImage imageWithSystemSymbolName: imageSymbol
                      accessibilityDescription: @""];
  } else if (imagePath != nil) {
    image = [[NSImage alloc] initWithContentsOfFile: imagePath];
  }
  if (image != nil) {
    image.template = YES;
    statusBarButton.image = image;
  }

  statusBarButton.toolTip = [jsonObject objectForKey: @"tooltip"];

  [statusMenu removeAllItems];
  [menuCommandMap removeAllObjects];
  [refreshingMenuItems removeAllObjects];
  NSArray *menuObjs = [jsonObject objectForKey: @"menus"];
  NSArray<NSMenuItem *> *menuItems = [self getMenuItems: menuObjs];
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
    NSString *menuItemTitleColor = [menuObj objectForKey: @"textcolor"];
    NSString *menuItemSubtitle = [menuObj objectForKey: @"subtext"];
    NSString *menuItemBadge = [menuObj objectForKey: @"badge"];
    NSString *menuItemCommand = [menuObj objectForKey: @"click"];
    NSString *menuItemKeyboard = [menuObj objectForKey: @"keyboard"];
    NSString *menuItemChecked = [menuObj objectForKey: @"checked"];
    BOOL menuItemRefresh = [[menuObj objectForKey: @"refresh"] boolValue];
    NSArray *submenuObjs = [menuObj objectForKey: @"submenus"];

    NSMenuItem *menuItem;
    if ([menuItemTitle isEqualToString: @"-"]) {
      menuItem = [NSMenuItem separatorItem];
    } else if (menuItemTitle && [menuItemTitle length] > 0) {
      menuItem = [[NSMenuItem alloc] initWithTitle: menuItemTitle
                                            action: nil
                                     keyEquivalent: menuItemKeyboard ?: @""];
      if (menuItemTitleColor != nil) {
        NSDictionary *attributes = @{
          NSForegroundColorAttributeName: [self colorFromHexString: menuItemTitleColor],
                     NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]
        };
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:menuItemTitle
                                                                              attributes:attributes];
        menuItem.attributedTitle = attributedTitle;
      }
      if (menuItemSubtitle != nil) {
        menuItem.subtitle = menuItemSubtitle;
      }
      if (menuItemBadge != nil) {
        menuItem.badge = [[NSMenuItemBadge alloc] initWithString: menuItemBadge];
      }
      if (menuItemCommand && [menuItemCommand length] > 0) {
        menuItem.target = self;
        menuItem.action = @selector(menuAction:);
        NSNumber *key = [NSNumber numberWithUnsignedInt: [menuItem hash]];
        [menuCommandMap setObject: menuItemCommand forKey: key];
        if (menuItemRefresh) {
          [refreshingMenuItems addObject: key];
        }
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
  [menuCommand execute: ^(NSData *outputData) {
    if ([refreshingMenuItems containsObject: key]) {
      NSLog(@"Refreshing after executing command");
      [self monitorRoutine];
    }
  }];
}

- (NSColor *) colorFromHexString: (NSString *) hexString {
  // Trim space and remove # if it exists
  NSString *colorString = [hexString stringByTrimmingCharactersInSet:
    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([colorString hasPrefix:@"#"]) {
    colorString = [colorString substringFromIndex:1];
  }

  if ([colorString length] == 0) {
    return [NSColor labelColor];
  } else if ([colorString length] != 6) {
    NSLog(@"Invalid text color: %@", colorString);
    return [NSColor labelColor];
  }

  unsigned int r, g, b;
  NSScanner *scanner;
  scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(0, 2)]];
  [scanner scanHexInt:&r];
  scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(2, 2)]];
  [scanner scanHexInt:&g];
  scanner = [NSScanner scannerWithString:[colorString substringWithRange:NSMakeRange(4, 2)]];
  [scanner scanHexInt:&b];

  return [NSColor colorWithCalibratedRed:(r / 255.0)
                                   green:(g / 255.0)
                                    blue:(b / 255.0)
                                   alpha:1.0];
}

@end

/* vim: set ft=objc: */
