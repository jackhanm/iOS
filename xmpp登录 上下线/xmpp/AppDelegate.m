//
//  AppDelegate.m
//  xmpp
//
//  Created by yuhao on 16/5/16.
//  Copyright © 2016年 infinitt. All rights reserved.
//

#import "AppDelegate.h"
#import "XMPPFramework.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPLogging.h"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
@interface AppDelegate ()<XMPPStreamDelegate>

/**
 *  在xmpp中，负责数据传输的类 ： xmppstream
 *
 *  针对不同的传输内容，会调用不同的代理方法
 *  @param launchOptions =
 *
 *  @return
 */
@property (nonatomic,strong)XMPPStream *xmppStream;
/**
 *  连接到服务器
 */
- (void)connect;
/**
 *  断开连接
 */
- (void)disconnect;
/**
 *  上线
 */
- (void)goOnline;

/**
 *  下线
 */
- (void)goOffline;
@end

@implementation AppDelegate







- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    //允许颜色输出
    [DDTTYLogger sharedInstance].colorsEnabled = YES;
    // 设置颜色
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor redColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    //初始化ddlog。添加负责日至输出的logger，ttyloger就是负责控制太输出的
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor darkGrayColor]
                                     backgroundColor:nil forFlag:XMPP_LOG_FLAG_SEND_RECV];
    [DDLog addLogger:[DDTTYLogger sharedInstance]
        withLogLevel:XMPP_LOG_FLAG_SEND_RECV | XMPP_LOG_FLAG_INFO];

//    [self connect];
    return YES;
}
//注销激活状态
- (void)applicationWillResignActive:(UIApplication *)application {
    
    [self disconnect];
}

//变成激活状态
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
        [self connect];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}
#pragma mark - xmpp方法
- (XMPPStream *)xmppStream
{
    if (_xmppStream == nil) {
        //实例话XMPPStream,负责数据传输，监听数据传输的状态
        _xmppStream = [[XMPPStream alloc]init];
        //设置XMppStram的代理，监听数据传输的情况，并且指定坚挺的工作队列
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return _xmppStream;
}
- (void)connect
{
    //主机名，配置openfire服务器时，设置主机的名字
    //需要连接到服务器的名称
     NSString *hostName = @"yuhaodemacbook-pro.local";
    //JId在xmpp协议中扮演了非常重要的角色，通过JID能够区分出所有的用户，和服务器
    // 一个JID对应整个即时通讯系统中的一个"节点"
    // 从用户角度看：JID ＝ 用户名 ＋ @ ＋ 主机名字
    XMPPJID *myjid = [XMPPJID  jidWithString:@"zhangsan@yuhaodemacbook-pro.local"];
    self.xmppStream.hostName = hostName;
    self.xmppStream.myJID = myjid;
    
    /**
     *  连接到服务器，祝集合端口号
     超时时长是可以选的，如果不选XMPPStreamTimeoutNone
     如果主机名活着myID没有设置，此方法返回NO，并且设置错误信息
     问题：如何知道连接的结果呢？连接的动作，本质上是“告诉服务器我来了”！
     */
    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:NULL];
}
- (void)disconnect {
    // 发送消息给服务器，要断开连接
    [self.xmppStream disconnect];
}
//上线
- (void)goOnline
{
    //需要将上线消息发送给服务器
    XMPPPresence *p = [XMPPPresence presence];
     DDLogInfo(@"上线通知 %@", p);
    //将节点发送给服务器
    [self.xmppStream sendElement:p];
}
// 下线
- (void)goOffline {
    // 下线通知
    // available上线，unavailable是离线
    XMPPPresence *p = [XMPPPresence presenceWithType:@"unavailable"];
    DDLogInfo(@"%@", p);
    
    [self.xmppStream sendElement:p];
}
#pragma mark 代理方法

// 完成服务器的连接
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogInfo(@"连接到服务器");
    //由xmppstream将密码发送给服务器，确认用户的身份能够使用长连接
    [self.xmppStream authenticateWithPassword:@"YUHAO620905" error:NULL];
}
- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogInfo(@"  断开连接");
    //通知服务器下线
    [self goOffline];
}
//授权成功
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogInfo( @"登录成功");
    [self goOnline];
    
}
//授权不成功
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    DDLogInfo(@"密码错误");
}
#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.yunpin.xmpp" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"xmpp" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"xmpp.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
