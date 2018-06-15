//
//  DeviceListVC.h
//  HLBluetoothDemo
//
//  Created by jessie on 2018/6/14.
//  Copyright © 2018年 Halley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HLBLEManager.h"
@interface DeviceListVC : UIViewController <UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic)   NSMutableArray              *deviceArray;  /**< 蓝牙设备个数 */
@property(nonatomic,copy)void(^complete)(CBPeripheral *peripheral);//完成回调
@end
