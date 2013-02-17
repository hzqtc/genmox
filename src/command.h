#import <Foundation/Foundation.h>

@interface Command: NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *args;

-(id) initWithLaunchString: (NSString *) commandString;
-(NSData *) execute;
-(NSString *) description;

@end

/* vim: set ft=objc: */
