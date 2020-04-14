//
//  FLYLocationManager.h
//  zhibo
//
//  Created by fly on 2016/12/21.
//  Copyright © 2016年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^LocationBlock)(CLLocation * location);

@interface FLYLocationManager : NSObject

//调用startUpdatingLocation开始更新位置后，过一点时间这两个属性才会有值
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;


+ (instancetype)sharedManager;


/**获取一次位置信息（不需要调用开始更新位置）*/
- (void)requestLocation:(LocationBlock)location;

/**开始更新位置*/
- (void)startUpdatingLocation;
/**停止更新位置*/
- (void)stopUpdatingLocation;

@end
