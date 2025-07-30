#import "AppDelegate.h"
#import "ConfigLoader.h"
#import "command.h"
#import "monitor.h"

@implementation AppDelegate {
  NSString *configPath;
  NSMutableArray *monitors;
  NSTimer *monitorCheckTimer;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  monitors = [[NSMutableArray alloc] init];

  NSArray *processArgs = [[NSProcessInfo processInfo] arguments];

  // Check for --help or -h flag
  for (NSString *arg in processArgs) {
    if ([arg isEqualToString:@"--help"] || [arg isEqualToString:@"-h"]) {
      printf("Usage: %s [-f <config_file_path>]\n",
             [[processArgs objectAtIndex:0] UTF8String]);
      printf("       %s [--help | -h]\n",
             [[processArgs objectAtIndex:0] UTF8String]);
      printf("\n");
      printf("Options:\n");
      printf(
          "  -f, --config-file <path>  Specify a JSON configuration file.\n");
      printf(
          "  -h, --help                Display this help message and exit.\n");
      [NSApp terminate:nil];
      return;
    }
  }

  // Check for --config-file or -f command line flag
  for (int i = 0; i < [processArgs count]; i++) {
    NSString *arg = [processArgs objectAtIndex:i];
    if ([arg isEqualToString:@"--config-file"] || [arg isEqualToString:@"-f"]) {
      if (i + 1 < [processArgs count]) {
        configPath = [processArgs objectAtIndex:i + 1];
        NSLog(@"Using config file from command line: %@", configPath);
        break;
      }
    }
  }

  // If not found, check ~/.config/genmox.json
  if (!configPath) {
    NSString *homeDir = NSHomeDirectory();
    NSString *userConfigPath =
        [homeDir stringByAppendingPathComponent:@".config/genmox.json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:userConfigPath]) {
      configPath = userConfigPath;
      NSLog(@"Using user config file: %@", configPath);
    }
  }

  if (!configPath) {
    NSLog(@"Error: No config file found.");
    [NSApp terminate:nil];
    return;
  }

  NSError *error = nil;
  NSArray *monitorConfigs = [ConfigLoader loadConfigFromFile:configPath
                                                       error:&error];
  if (!monitorConfigs) {
    NSLog(@"Error loading monitor configurations: %@", error);
    [NSApp terminate:nil];
    return;
  }

  [self startMonitors:monitorConfigs];

  monitorCheckTimer =
      [NSTimer scheduledTimerWithTimeInterval:10.0
                                       target:self
                                     selector:@selector(checkMonitors)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)startMonitors:(NSArray *)monitorConfigs {
  for (NSDictionary *config in monitorConfigs) {
    Monitor *monitor = [[Monitor alloc] initWithConfig:config];
    if (monitor) {
      [monitors addObject:monitor];
      [monitor start];
    }
  }
}

- (void)checkMonitors {
  NSLog(@"Checking monitors...");

  NSMutableArray *monitorsToRestart = [[NSMutableArray alloc] init];
  for (Monitor *monitor in monitors) {
    if (!monitor.isActive) {
      NSLog(@"Monitor '%@' is inactive. Preparing to restart.", monitor.name);
      [monitorsToRestart addObject:monitor];
    }
  }

  if (monitorsToRestart.count == 0) {
    return;
  }

  NSError *error = nil;
  NSArray *monitorConfigs = [ConfigLoader loadConfigFromFile:configPath
                                                       error:&error];
  if (!monitorConfigs) {
    NSLog(@"Error loading monitor configurations: %@", error);
    [NSApp terminate:nil];
    return;
  }

  for (Monitor *monitor in monitorsToRestart) {
    // Remove the inactive monitor from the active list
    [monitors removeObject:monitor];

    // Find its original config and try to restart
    for (NSDictionary *config in monitorConfigs) {
      if ([config[@"name"] isEqualToString:monitor.name]) {
        NSLog(@"Attempting to restart monitor '%@'.", monitor.name);
        Monitor *newMonitor = [[Monitor alloc] initWithConfig:config];
        if (newMonitor) {
          [monitors addObject:newMonitor];
          [newMonitor start];
        }
      }
    }
  }
}

@end
