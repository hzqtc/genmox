#import "command.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface Monitor : NSObject <NSMenuDelegate>

@property(nonatomic) NSString *name;
@property(nonatomic) Command *command;
@property(nonatomic) int interval;
@property(nonatomic) bool pauseWhenOpen;

- (id)init;
- (id)initWithConfig:(NSDictionary *)config;

- (void)start;
- (void)monitorRoutine;
- (void)stop;

- (int)parseCommandOutputInJSON:(NSData *)jsonData;

- (void)menuAction:(id)sender;

@end

/* vim: set ft=objc: */
