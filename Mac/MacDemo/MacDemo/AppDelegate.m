//
//  AppDelegate.m
//  MacDemo
//
//  Created by JinTao on 2020/12/7.
//

#import "AppDelegate.h"
#import "HZIPCGlobalHeader.h"
#import "HZIPCMachServer.h"

@interface AppDelegate () <NSMachPortDelegate>
@property (nonatomic, strong) HZIPCMachServer *machServer;
@property (nonatomic, strong) id<NSObject> activity;
@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    //NSLog(@"%s", __func__);
    //[self XPCTest];
    self.machServer = [[HZIPCMachServer alloc] init];
    [self.machServer run];
    //[self nsConnectionTest];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 注册这个活动, 要不, 切到其它App不到一分钟后, 此App代码里的计时器会不准, 大大减少执行次数
    self.activity = [NSProcessInfo.processInfo beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep reason:@"后台传数据"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [NSProcessInfo.processInfo endActivity:self.activity];
}

- (void)applicationWillHide:(NSNotification *)notification {
    //NSLog(@"%s", __func__);
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    //NSLog(@"%s", __func__);
}

- (void)applicationDidChangeOcclusionState:(NSNotification *)notification {
    //NSLog(@"%s %@", __func__, notification);
}

#pragma mark - XPC Test
- (void)XPCTest {
    // 用NSXPCConnection和plugin通信, 没有找到连接插件的方法, 在当前应用的服务内可以正常通信
    //NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.Anywii.CoreMediaIOPluginDemo" options:0];
    // serviceName为服务的bundle ID, 要在工程中添加这个服务, xcode新建一个XPC Service即可
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"com.Anywii.CoreMediaIOPluginDemo"];
    // 远程接口
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HZXPCProtocol)];
    // 获取远程接口调用对象
    self.remoteObjectProxy = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"出错了: %@", error);
    }];
    [connection resume];
    // 对象调用接口方法
    // 只调前面的方法, 不调这个方法, 服务不会启动
    [self.remoteObjectProxy test:@"2222" reply:^(NSString *replyString) {
        NSLog(@"收到了回复: %@", replyString);
    }];
}

#pragma mark - NSConnection Test
- (void)nsConnectionTest {
    // 用一条线程维护 NSConnection
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            // 正常建立的工程, 在其它 App 上访问不了, 把 Capability 里的 App Sandbox 删掉后就能正常连接
            NSConnection *connection = [[NSConnection alloc] init];
            // 用来响应其它线程调用方法的对象
            connection.rootObject = self;
            BOOL ret = [connection registerName:@"com.Anywii.MacDemo"];
            if (!ret) {
                NSLog(@"error");
            }
            NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
            [currentRunLoop run];
            NSLog(@"");
        }
    });
}

- (void)connectionTest {
    NSLog(@"connection 方法调用");
}

@end
