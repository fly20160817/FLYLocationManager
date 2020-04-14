//
//  FLYLocationManager.m
//  zhibo
//
//  Created by fly on 2016/12/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import "FLYLocationManager.h"
#import <UIKit/UIKit.h>

@interface FLYLocationManager () < NSCopying, NSMutableCopying, CLLocationManagerDelegate >

@property (nonatomic, strong) CLLocationManager * locationManager;
@property (nonatomic, copy) LocationBlock locationBlock;
@property (nonatomic, copy) ErrorBlock error;

@end

@implementation FLYLocationManager

#pragma mark - 单利 （保证无论通过怎样的方式创建出来，都只有一个实例）

static FLYLocationManager * _sharedManager;

+ (instancetype)sharedManager
{
    if ( _sharedManager == nil )
    {
        _sharedManager = [[self alloc] init];
    }
    return _sharedManager;
}

//分配内存地址的时候调用 (当执行alloc的时候，系统会自动调用分配内存地址的方法)
+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    if ( !_sharedManager )
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _sharedManager = [super allocWithZone:zone];
        });
    }
    return _sharedManager;
}

//保证copy这个对象的时候，返回的还是这个单利，不会生成新的 (这个方法需要在头部声明代理)
-(id)copyWithZone:(NSZone *)zone
{
    return _sharedManager;
}

//保证copy这个对象的时候，返回的还是这个单利，不会生成新的 (这个方法需要在头部声明代理)
-(id)mutableCopyWithZone:(NSZone *)zone
{
    return _sharedManager;
}



#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch ( status )
    {
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"位置授权状态：未决定");
            [self.locationManager requestAlwaysAuthorization];
            break;
            
        case kCLAuthorizationStatusRestricted:
            NSLog(@"位置授权状态：无法授权定位");
            break;
            
        case kCLAuthorizationStatusDenied:
            NSLog(@"位置授权状态：用户拒绝");
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"位置授权状态：始终定位");
            break;
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"位置授权状态：使用时定位");
            break;
            
        default:
            NSLog(@"位置授权状态：系统出新状态啦～");
            break;
    }
}

//刷新当前位置的代理
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = [locations lastObject];
    
    self.latitude = location.coordinate.latitude;
    self.longitude = location.coordinate.longitude;
    
    if ( self.locationBlock )
    {
        self.locationBlock(location);
        //Block调用完之后置空，不然每次走这个代理时都会调用外部的Block
        self.locationBlock = nil;
    }
    
    
    //%f只会默认输入小数点后6位，需要多输出，强制指定就可以了
    NSLog(@"经纬度  %.10f，%.10f ", location.coordinate.longitude,location.coordinate.latitude);
}

//当设备获取坐标失败时调用该方法
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"位置信息获取失败：%@", error);
    
    if ( error )
    {
        [self checkError:error];
        
        !self.error ?: self.error(error);
    }
}



#pragma mark - LocationManager

//获取一次位置信息
- (void)requestLocation:(LocationBlock)location error:(ErrorBlock)error
{
    if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied )
    {
        [FLYLocationManager alertOpenAuthorization];
        
        NSError * e = [NSError errorWithDomain:@"用户拒绝了定位权限" code:999 userInfo:nil];
        error(e);
        return;
    }
    
    self.locationBlock = location;
    self.error = error;
    
    //如果没有授权过，系统会去询问，询问过会回来继续执行这句
    [self.locationManager requestLocation];
}

//开始更新位置
- (void)startUpdatingLocation
{
    if ( [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied )
    {
        [FLYLocationManager alertOpenAuthorization];
        return;
    }
    
    //如果没有授权过，系统会去询问，询问过会回来继续执行这句
    [self.locationManager startUpdatingLocation];
}

//停止更新位置
- (void)stopUpdatingLocation
{
    [self.locationManager stopUpdatingLocation];
}



#pragma mark - private methods

//引导用户打开定位服务
+ (void)alertOpenAuthorization
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"请您开启位置权限" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction * alert1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction * alert2 = [UIAlertAction actionWithTitle:@"前往" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];

        [[UIApplication sharedApplication] openURL:url];
        
    }];
    
    [alertController addAction:alert1];
    [alertController addAction:alert2];
    
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

//将提取错误的方法专门提炼出来
- (void)checkError:(NSError *)error
{
    //判断错误码对应的错误原因
    switch ( error.code )
    {
        case kCLErrorNetwork:
            NSLog(@"网络相关错误");
            break;
            
        case kCLErrorDenied:
            NSLog(@"对位置或范围的访问被用户拒绝");
            break;
            
        case kCLErrorLocationUnknown:
            NSLog(@"location当前未知，但是将继续尝试");
            break;
            
        default:
            NSLog(@"其他原因，位置信息获取失败");
            break;
    }
}



#pragma mark - setters and getters

-(CLLocationManager *)locationManager
{
    if ( _locationManager == nil )
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        //设置定位的精确度
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        //设置定位的刷新频率 (单位是米,移动多少距离刷新)
        _locationManager.distanceFilter = 1;
        
        
        
        /*后定定位时添加的代码*/
        
        //如果这个属性设置成YES（默认的也是YES），那么系统会检测如果设备有一段时间没有移动，就会自动停掉位置更新服务。这里需要注意的是，一旦定位服务停止了，只有当用户再次开启App的时候定位服务才会重新启动。
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        
        //允许后台位置更新 (如果设置成YES,还需要配置plist列表,增加"Required background modes"(数组),添加"App registers for location updates"元素)
        //[_locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    return _locationManager;
}

@end


