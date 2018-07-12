//
//  ProcessTests.m
//  LiquidCoreiOSTests
//
//  Created by Eric Lange on 7/10/18.
//  Copyright © 2018 LiquidPlayer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Process.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface ProcessTests : XCTestCase

@end

@interface MultiProcessDelegate : XCTestCase<ProcessDelegate>
@property (atomic, assign) int count;
@property (atomic, assign) int countdown;
@end
@implementation MultiProcessDelegate
- (void) onProcessStart:(Process*)process context:(JSContext*)context
{
    XCTAssertTrue([process isActive]);
    
    JSValue* function = [JSValue valueWithObject:^(int in) {
        return in + 1;
    } inContext:context];
    int mycount = self.count++;
    JSValue* incd = [function callWithArguments:@[[NSNumber numberWithInt:mycount]]];
    XCTAssertEqual([incd toInt32], mycount + 1);
}
- (void) onProcessAboutToExit:(Process*)process exitCode:(int)code {}
- (void) onProcessExit:(Process*)process exitCode:(int)code
{
    XCTAssertFalse([process isActive]);
    self.countdown --;
}
- (void) onProcessFailed:(Process*)process exception:(NSException*)exception
{
    XCTAssertTrue(false);
}
@end

@interface MultiThreadDelegate : XCTestCase<ProcessDelegate>
@property (atomic, assign) bool done;
@end
@implementation MultiThreadDelegate
- (void) onProcessStart:(Process*)process context:(JSContext*)ctx
{
    // Don't let the process exit until our thread finishes
    id<LoopPreserver> preserver = [process keepAlive];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [process sync:^(JSContext *context) {
            context[@"foo"] = @"bar";
            JSValue *value = [context evaluateScript:@"5 + 10"];
            XCTAssertEqual([value toInt32], 15);
            XCTAssertEqualObjects([context[@"foo"] toString], @"bar");
            context[@"dir_contents"] = ^(JSValue *err, NSArray * files) {
                NSLog(@"dir_contents = %@", files);
            };
            
            [context evaluateScript:
                                   @"(function() {"
                                   @"  var fs = require('fs');"
                                   @"  fs.readdir('/home',dir_contents);"
                                   @"})();"];
        }];
        // ok, we're done here
        [preserver letDie];
    });
}
- (void) onProcessAboutToExit:(Process*)process exitCode:(int)code {}
- (void) onProcessExit:(Process*)process exitCode:(int)code
{
    self.done = true;
}
- (void) onProcessFailed:(Process*)process exception:(NSException*)exception
{
    XCTAssertTrue(false);
}
@end

@interface ForceExitDelegate : XCTestCase<ProcessDelegate>
@property (atomic, assign) bool done;
@end
@implementation ForceExitDelegate
- (void) onProcessStart:(Process*)process context:(JSContext*)context
{
    [context evaluateScript:@"setInterval(function(){console.log('tick');},1000);"];
    [context evaluateScript:@"setTimeout(function(){process.exit(2);},500);"];
}
- (void) onProcessAboutToExit:(Process*)process exitCode:(int)code {}
- (void) onProcessExit:(Process*)process exitCode:(int)code
{
    XCTAssertEqual(code, 2);
    self.done = true;
}
- (void) onProcessFailed:(Process*)process exception:(NSException*)exception
{
    XCTAssertTrue(false);
}
@end

@implementation ProcessTests

- (void)testMultiProcess
{
    MultiProcessDelegate* delegate = [[MultiProcessDelegate alloc] init];
    delegate.countdown = 3;
    XCTAssertNotNil([[Process alloc] initWithDelegate:delegate id:@"_1" mediaAccessMask:PermissionsRW]);
    XCTAssertNotNil([[Process alloc] initWithDelegate:delegate id:@"_2" mediaAccessMask:PermissionsRW]);
    XCTAssertNotNil([[Process alloc] initWithDelegate:delegate id:@"_3" mediaAccessMask:PermissionsRW]);
    volatile int countdown = 100;
    while (countdown > 0) {
        countdown = delegate.countdown;
    }
}

- (void)testMultiThread
{
    MultiThreadDelegate *delegate = [[MultiThreadDelegate alloc] init];
    delegate.done = false;
    XCTAssertNotNil([[Process alloc] initWithDelegate:delegate id:@"_" mediaAccessMask:PermissionsRW]);
    volatile bool done = false;
    while (!done) {
        done = delegate.done;
    }
}

- (void)testForceExit
{
    ForceExitDelegate *delegate = [[ForceExitDelegate alloc] init];
    delegate.done = false;
    XCTAssertNotNil([[Process alloc] initWithDelegate:delegate id:@"forceExitTest" mediaAccessMask:PermissionsRW]);
    volatile bool done = false;
    while (!done) {
        done = delegate.done;
    }
    
    [Process uninstall:@"forceExitTest" scope:GLOBAL];
}
@end
