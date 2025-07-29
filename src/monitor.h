#import "command.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface Monitor : NSObject <NSMenuDelegate>

@property(nonatomic) NSString *name;
@property(nonatomic) Command *command;
@property(nonatomic) int interval;
@property(nonatomic) bool pauseWhenOpen;

- (id)initWithConfig:(NSDictionary *)config;

- (void)start;
- (void)refresh;
- (void)stop;

@end

/* vim: set ft=objc: */
