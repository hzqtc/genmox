#import "command.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface Monitor : NSObject <NSMenuDelegate>

@property(nonatomic) Command *command;
@property(nonatomic) int interval;

- (id)init;
- (id)initWithCommand:(Command *)initCommand andInterval:(int)checkInterval;

- (void)start;
- (void)monitorRoutine;

- (int)parseCommandOutputInJSON:(NSData *)jsonData;

- (void)menuAction:(id)sender;

@end

/* vim: set ft=objc: */
