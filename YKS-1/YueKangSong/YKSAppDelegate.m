//
//  AppDelegate.m
//  YueKangSong
//
//  Created by gongliang on 15/5/12.
//  Copyright (c) 2015年 YKS. All rights reserved.
//
#import "YKSAppDelegate.h"
#import "YKSAreaManager.h"
#import "YKSConstants.h"
#import <UMengSocial/UMSocial.h>
#import <UMengAnalytics/MobClick.h>
#import <UMSocialWechatHandler.h>
#import <XGPush/XGPush.h>
#import <XGPush/XGSetting.h>
#import "YKSUserModel.h"
#import "GZBaseRequest.h"
#import "HealthKitUtils.h"
#import "YKSWelcomeViewController.h"

@interface YKSAppDelegate ()<UIAlertViewDelegate>
@property(nonatomic)NSInteger isforceupdate;
@end

@implementation YKSAppDelegate




+ (YKSAppDelegate *)sharedAppDelegate
{
    return (YKSAppDelegate *)([UIApplication sharedApplication].delegate);
}

- (NSDictionary *)baseInfo {
    if (!_baseInfo) {
        _baseInfo  = [[NSUserDefaults standardUserDefaults] objectForKey:@"kBaseInfo"];
    }
    return _baseInfo;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (self.isforceupdate) {
        
        //tiao
        
        NSString *url = @"itms-apps://itunes.apple.com/lookup?id=1018635146";
        
        
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:url]];
        
    }else{
        if (buttonIndex==0) {
            //quxiao
        }else{
            NSString *URL = @"itms-apps://itunes.apple.com/lookup?id=1018635146";
            [[UIApplication sharedApplication]openURL:[NSURL URLWithString:URL]];

        }
        
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    NSString *URL = @"http://itunes.apple.com/app/id1018635146?mt=8";
//    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:URL]];
    NSLog(@"%@",XcodeAppVersion);
    // Override point for customization after application launch.[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
    [GZBaseRequest getBackgroundVersionAndcallBack:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject)) {
            NSInteger newversion = [responseObject[@"data"][@"ver"] integerValue];
            NSInteger xcodevers = [XcodeAppVersion integerValue];
            
            self.isforceupdate = [responseObject[@"data"][@"isforceupdate"]integerValue];
            self.isforceupdate = 0;
            if (newversion>xcodevers) {
                NSString *msg = responseObject[@"msg"];
                
                
                if (self.isforceupdate==0) {
                    UIAlertView *a = [[UIAlertView alloc]initWithTitle:@"更新" message:msg delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    [a show];
                }else{
                    UIAlertView *a = [[UIAlertView alloc]initWithTitle:@"更新" message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
                    [a show];
                }
            }
        }
    }];
    
    
    
    
    sleep(2.0);
    BOOL isShowWelcome = [[[NSUserDefaults standardUserDefaults] objectForKey:kShowWelcome] boolValue];

    YKSWelcomeViewController *vc = [[YKSWelcomeViewController alloc] init];
    //先来个固定的搞一下
    if (!isShowWelcome) {
        self.window.rootViewController = vc;
    }
    
    [self setNavigationBarUI];
    [YKSAreaManager getBeijingAreaInfo:^(id areaInfo) {
       //NSLog(@"areaInfo = %@", areaInfo);
    }];
    [GZBaseRequest baseInfocallback:^(id responseObject, NSError *error) {
        if (ServerSuccess(responseObject)) {
            self.baseInfo = responseObject[@"data"];
            [[NSUserDefaults standardUserDefaults] setObject:responseObject[@"data"] forKey:@"kBaseInfo"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
        }
    }];
    [self initialUMeng];
    [self initialXGPush:launchOptions];
    [HealthKitUtils sharedInstance];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return  [UMSocialSnsService handleOpenURL:url];
}
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return  [UMSocialSnsService handleOpenURL:url];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    //NSString * deviceTokenStr = [XGPush registerDevice:deviceToken];
    void (^successBlock)(void) = ^(void){
        //成功之后的处理
        NSLog(@"[XGPush]register successBlock");
    };
    void (^errorBlock)(void) = ^(void){
        //失败之后的处理
        NSLog(@"[XGPush]register errorBlock");
    };
    //注册设备
    [[XGSetting getInstance] setChannel:@"appstore"];
    [[XGSetting getInstance] setGameServer:@"悦康送"];
    
    NSString * deviceTokenStr = [XGPush registerDevice:deviceToken successCallback:successBlock errorCallback:errorBlock];
    
    //如果不需要回调
    //[XGPush registerDevice:deviceToken];
    [YKSUserModel shareInstance].deviceToken = deviceTokenStr;
    if ([YKSUserModel isLogin]) {
        [GZBaseRequest modifyToken:deviceTokenStr callback:^(id responseObject, NSError *error) {
            NSLog(@"上传devicetoken");
        }];
    }
    
    //打印获取的deviceToken的字符串
    NSLog(@"deviceTokenStr is %@",deviceTokenStr);
}

//如果deviceToken获取不到会进入此事件
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    
    NSString *str = [NSString stringWithFormat: @"Error: %@",err];
    
    NSLog(@"%@",str);
    
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    //推送反馈(app运行时)
    [XGPush handleReceiveNotification:userInfo];
    
     void (^successBlock)(void) = ^(void){
     //成功之后的处理
     NSLog(@"[XGPush]handleReceiveNotification successBlock");
     };
     
     void (^errorBlock)(void) = ^(void){
     //失败之后的处理
     NSLog(@"[XGPush]handleReceiveNotification errorBlock");
     };
     
     void (^completion)(void) = ^(void){
     //失败之后的处理
     NSLog(@"[xg push completion]userInfo is %@",userInfo);
     };
     
     [XGPush handleReceiveNotification:userInfo
                       successCallback:successBlock
                         errorCallback:errorBlock
                            completion:completion];
}
#pragma mark - custom
- (void)setNavigationBarUI {
    [[UINavigationBar appearance] setBarTintColor:kNavigationBar_back_color];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
}

- (void)initialUMeng {
    [UMSocialData setAppKey:kUMAppkey];
    [UMSocialWechatHandler setWXAppId:@"wxdd50133f4733fe7c"
                            appSecret:@"ff89f09c7f0591a132a75f1231b64a09"
                                  url:@"http://api.yuekangsong.com/huodongpage.php"];
    [MobClick startWithAppkey:kUMAppkey];
}

- (void)initialXGPush:(NSDictionary *)launchOptions {
    [XGPush startApp:2200097979 appKey:@"IK7R117D8EEY"];
    [self registerRemoteNotification];
    //注销之后需要再次注册前的准备
    /*
    void (^successCallback)(void) = ^(void){
        //如果变成需要注册状态
        if(![XGPush isUnRegisterStatus]) {
            [self registerRemoteNotification];
        }
    };
    [XGPush initForReregister:successCallback];
     */
    
    //推送反馈回调版本示例
    void (^successBlock)(void) = ^(void){
        //成功之后的处理
        NSLog(@"[XGPush]handleLaunching's successBlock");
    };

    void (^errorBlock)(void) = ^(void){
        //失败之后的处理
        NSLog(@"[XGPush]handleLaunching's errorBlock");
    };
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [XGPush handleLaunching:launchOptions successCallback:successBlock errorCallback:errorBlock];
}

- (void)registerRemoteNotification {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationSettings *uns = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:uns];
    } else {
        UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
    }
}


@end
