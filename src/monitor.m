#import "monitor.h"
#import <Cocoa/Cocoa.h>

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
  // Command to run when menu is open
  Command *menuOpenCommand;
  // Command to run when menu is closed
  Command *menuCloseCommand;
  // Flag indicate whether the dropdown is currently open
  bool isMenuOpen;
}

@synthesize command, name, pauseWhenOpen;

- (int)interval {
  return [timer timeInterval];
}

- (void)setInterval:(int)checkInterval {
  [timer invalidate];
  timer = nil;
  timer = [NSTimer timerWithTimeInterval:checkInterval
                                  target:self
                                selector:@selector(monitorRoutine)
                                userInfo:nil
                                 repeats:YES];
}

- (id)init {
  if (self = [super init]) {
    statusItem = [[NSStatusBar systemStatusBar]
        statusItemWithLength:NSVariableStatusItemLength];
    statusBarButton = statusItem.button;

    statusMenu = [NSMenu new];
    statusItem.menu = statusMenu;
    statusMenu.delegate = self;
    updateMenuItem =
        [[NSMenuItem alloc] initWithTitle:@"Refresh"
                                   action:@selector(updateMonitorAction:)
                            keyEquivalent:@"r"];
    [updateMenuItem setTarget:self];
    quitMenuItem =
        [[NSMenuItem alloc] initWithTitle:@"Quit"
                                   action:@selector(quitMonitorAction:)
                            keyEquivalent:@"q"];
    [quitMenuItem setTarget:self];

    menuCommandMap = [NSMutableDictionary dictionaryWithCapacity:100];
    refreshingMenuItems = [NSMutableSet setWithCapacity:100];
  }
  return self;
}

- (id)initWithConfig:(NSDictionary *)config {
  if ([self init]) {
    NSString *nameStr = config[@"name"];
    NSString *commandStr = config[@"command"];
    NSNumber *interval = config[@"interval"];
    NSLog(@"Initializing monitor with name %@, command %@ and interval %@",
          nameStr, commandStr, interval);

    if (nameStr && [nameStr length] > 0) {
      self.name = nameStr;
    } else {
      NSLog(@"Invalid command name: %@", name);
      return nil;
    }
    if (commandStr && [commandStr length] > 0) {
      self.command = [[Command alloc] initWithLaunchString:commandStr];
    } else {
      NSLog(@"[%@] Invalid command path: %@", name, commandStr);
      return nil;
    }
    if (interval) {
      self.interval = [interval intValue];
    } else {
      NSLog(@"[%@] Invalid command interval: %@", name, interval);
      return nil;
    }
    self.pauseWhenOpen = [config[@"pause_when_open"] boolValue];
  }
  return self;
}

- (void)start {
  NSLog(@"[%@] Starting monitor", self.name);
  [NSThread detachNewThreadSelector:@selector(monitorThreadMain)
                           toTarget:self
                         withObject:nil];
}

- (void)monitorThreadMain {
  @autoreleasepool {
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [self monitorRoutine];
    [[NSRunLoop currentRunLoop] run];
  }
}

- (void)updateMonitorAction:(id)sender {
  [self monitorRoutine];
}

- (void)refresh {
  [self monitorRoutine];
}

- (void)monitorRoutine {
  if (isMenuOpen && self.pauseWhenOpen) {
    return;
  }
  NSLog(@"[%@] Execute command: %@", self.name, [command description]);
  NSData *commandOutput = [command execute];
  if (commandOutput) {
    if ([self parseCommandOutputInJSON:commandOutput] != 0) {
      NSLog(@"[%@] Command gives incorrect output. Stopping monitor.",
            self.name);
      [self stop];
    }
  } else {
    NSLog(@"[%@] Command execution failed. Stopping monitor.", self.name);
    [self stop];
  }
}

- (int)parseCommandOutputInJSON:(NSData *)jsonData {
  NSError *e = nil;
  NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:0
                                                               error:&e];
  if (jsonObject == nil) {
    NSLog(@"[%@] JSON parse error: %@", self.name, e);
    return -1;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    NSString *title = [jsonObject objectForKey:@"text"];
    NSString *textColor = [jsonObject objectForKey:@"textcolor"];
    if (textColor != nil) {
      NSDictionary *attributes = @{
        NSForegroundColorAttributeName : [self colorFromHexString:textColor],
        NSFontAttributeName : [NSFont systemFontOfSize:[NSFont systemFontSize]]
      };
      NSAttributedString *attributedTitle =
          [[NSAttributedString alloc] initWithString:title
                                          attributes:attributes];
      statusBarButton.attributedTitle = attributedTitle;
    } else {
      statusBarButton.title = title;
    }

    NSString *imageSymbol = [jsonObject objectForKey:@"imagesymbol"];
    NSString *imagePath = [jsonObject objectForKey:@"image"];
    NSImage *image;
    if (imageSymbol != nil) {
      image = [NSImage imageWithSystemSymbolName:imageSymbol
                        accessibilityDescription:@""];
    } else if (imagePath != nil) {
      image = [[NSImage alloc] initWithContentsOfFile:imagePath];
    }
    if (image != nil) {
      image.template = YES;
      statusBarButton.image = image;
    }

    statusBarButton.toolTip = [jsonObject objectForKey:@"tooltip"];

    [statusMenu removeAllItems];
    [menuCommandMap removeAllObjects];
    [refreshingMenuItems removeAllObjects];
    NSArray *menuObjs = [jsonObject objectForKey:@"menus"];
    NSArray<NSMenuItem *> *menuItems = [self getMenuItems:menuObjs];
    for (NSMenuItem *item in menuItems) {
      [statusMenu addItem:item];
    }

    if ([statusMenu numberOfItems] > 0) {
      [statusMenu addItem:[NSMenuItem separatorItem]];
    }
    [statusMenu addItem:updateMenuItem];
    [statusMenu addItem:quitMenuItem];

    NSString *menuOpen = [jsonObject objectForKey:@"menuopen"];
    if (menuOpen != nil) {
      menuOpenCommand = [[Command alloc] initWithLaunchString:menuOpen];
    } else {
      menuOpenCommand = nil;
    }
    NSString *menuClose = [jsonObject objectForKey:@"menuclose"];
    if (menuClose != nil) {
      menuCloseCommand = [[Command alloc] initWithLaunchString:menuClose];
    } else {
      menuCloseCommand = nil;
    }
  });

  return 0;
}

- (NSArray<NSMenuItem *> *)getMenuItems:(NSArray *)menuObjs {
  NSMutableArray<NSMenuItem *> *menuItems = [NSMutableArray array];
  for (NSDictionary *menuObj in menuObjs) {
    NSString *menuItemTitle = [menuObj objectForKey:@"text"];
    NSString *menuItemTitleColor = [menuObj objectForKey:@"textcolor"];
    NSString *menuItemImageColor = [menuObj objectForKey:@"imagecolor"];
    NSString *menuItemSubtitle = [menuObj objectForKey:@"subtext"];
    NSString *menuItemBadge = [menuObj objectForKey:@"badge"];
    NSString *menuItemCommand = [menuObj objectForKey:@"click"];
    NSString *menuItemKeyboard = [menuObj objectForKey:@"keyboard"];
    NSString *menuItemChecked = [menuObj objectForKey:@"checked"];
    BOOL menuItemRefresh = [[menuObj objectForKey:@"refresh"] boolValue];
    NSArray *submenuObjs = [menuObj objectForKey:@"submenus"];
    BOOL isSectionHeader = [[menuObj objectForKey:@"sectionheader"] boolValue];

    NSMenuItem *menuItem;
    if ([menuItemTitle isEqualToString:@"-"]) {
      menuItem = [NSMenuItem separatorItem];
    } else if (isSectionHeader) {
      menuItem = [NSMenuItem sectionHeaderWithTitle:menuItemTitle];
    } else if (menuItemTitle && [menuItemTitle length] > 0) {
      menuItem = [[NSMenuItem alloc] initWithTitle:menuItemTitle
                                            action:nil
                                     keyEquivalent:menuItemKeyboard ?: @""];
      if (menuItemTitleColor != nil) {
        NSDictionary *attributes = @{
          NSForegroundColorAttributeName :
              [self colorFromHexString:menuItemTitleColor],
          NSFontAttributeName :
              [NSFont systemFontOfSize:[NSFont systemFontSize]]
        };
        NSAttributedString *attributedTitle =
            [[NSAttributedString alloc] initWithString:menuItemTitle
                                            attributes:attributes];
        menuItem.attributedTitle = attributedTitle;
      }
      if (menuItemImageColor != nil) {
        NSSize size = NSMakeSize(16, 16);
        NSColor *color = [self colorFromHexString:menuItemImageColor];
        CGFloat cornerRadius = 4.0; // Adjust as needed
        NSImage *image = [[NSImage alloc] initWithSize:size];
        [image lockFocus];
        [color setFill];
        NSBezierPath *path = [NSBezierPath
            bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height)
                              xRadius:cornerRadius
                              yRadius:cornerRadius];
        [path fill];
        [image unlockFocus];
        menuItem.image = image;
      }
      if (menuItemSubtitle != nil) {
        menuItem.subtitle = menuItemSubtitle;
      }
      if (menuItemBadge != nil) {
        menuItem.badge = [[NSMenuItemBadge alloc] initWithString:menuItemBadge];
      }
      if (menuItemCommand && [menuItemCommand length] > 0) {
        menuItem.target = self;
        menuItem.action = @selector(menuAction:);
        NSNumber *key = [NSNumber numberWithUnsignedInt:[menuItem hash]];
        [menuCommandMap setObject:menuItemCommand forKey:key];
        if (menuItemRefresh) {
          [refreshingMenuItems addObject:key];
        }
      }

      if (menuItemChecked &&
          [menuItemChecked caseInsensitiveCompare:@"true"] == NSOrderedSame) {
        menuItem.state = NSControlStateValueOn;
      }

      if (submenuObjs && submenuObjs.count > 0) {
        NSMenu *submenu = [NSMenu new];
        NSArray<NSMenuItem *> *submenuItems = [self getMenuItems:submenuObjs];
        for (NSMenuItem *item in submenuItems) {
          [submenu addItem:item];
        }
        menuItem.submenu = submenu;
      }
    }

    if (menuItem) {
      [menuItems addObject:menuItem];
    }
  }
  return [menuItems copy];
}

- (void)menuAction:(id)sender {
  NSNumber *key = [NSNumber numberWithUnsignedInt:[sender hash]];
  Command *menuCommand =
      [[Command alloc] initWithLaunchString:[menuCommandMap objectForKey:key]];
  [menuCommand execute];
  if ([refreshingMenuItems containsObject:key]) {
    NSLog(@"[%@] Refreshing after executing command", self.name);
    [self monitorRoutine];
  }
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
  // Trim space and remove # if it exists
  NSString *colorString = [hexString
      stringByTrimmingCharactersInSet:[NSCharacterSet
                                          whitespaceAndNewlineCharacterSet]];
  if ([colorString hasPrefix:@"#"]) {
    colorString = [colorString substringFromIndex:1];
  }

  if ([colorString length] == 0) {
    return [NSColor labelColor];
  } else if ([colorString length] != 6) {
    NSLog(@"[%@] Invalid text color: %@", self.name, colorString);
    return [NSColor labelColor];
  }

  unsigned int r, g, b;
  NSScanner *scanner;
  scanner = [NSScanner
      scannerWithString:[colorString substringWithRange:NSMakeRange(0, 2)]];
  [scanner scanHexInt:&r];
  scanner = [NSScanner
      scannerWithString:[colorString substringWithRange:NSMakeRange(2, 2)]];
  [scanner scanHexInt:&g];
  scanner = [NSScanner
      scannerWithString:[colorString substringWithRange:NSMakeRange(4, 2)]];
  [scanner scanHexInt:&b];

  return [NSColor colorWithCalibratedRed:(r / 255.0)
                                   green:(g / 255.0)
                                    blue:(b / 255.0)
                                   alpha:1.0];
}

- (void)menuWillOpen:(NSMenu *)menu {
  isMenuOpen = true;
  if (menuOpenCommand != nil) {
    NSLog(@"[%@] Executing menu open command", self.name);
    [menuOpenCommand execute];
  }
}

- (void)menuDidClose:(NSMenu *)menu {
  isMenuOpen = false;
  if (menuCloseCommand != nil) {
    NSLog(@"[%@] Executing menu close command", self.name);
    [menuCloseCommand execute];
  }
}

- (void)stop {
  NSLog(@"[%@] Stopping monitor", self.name);
  [timer invalidate];
  timer = nil;
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
  });
}

- (void)quitMonitorAction:(id)sender {
  [self stop];
}
@end

/* vim: set ft=objc: */
