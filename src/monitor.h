#import <Foundation/Foundation.h>
#import "command.h"

@interface Monitor: NSObject

@property Command *command;
@property int interval;

-(id) init;
-(id) initWithCommand: (Command *) initCommand andInterval: (int) checkInterval;

-(void) start;
-(void) monitorRoutine;

-(int) parseCommandOutputInJSON: (NSData *) jsonData;

-(void) menuAction: (id) sender;

@end

/* vim: set ft=objc: */
