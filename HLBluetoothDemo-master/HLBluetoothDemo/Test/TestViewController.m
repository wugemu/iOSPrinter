//
//  TestViewController.m
//  HLBluetoothDemo
//
//  Created by jessie on 2018/6/13.
//  Copyright © 2018年 Halley. All rights reserved.
//

#import "TestViewController.h"
#import "BLEDetailViewController.h"
#import "HLBLEManager.h"
#import "SVProgressHUD.h"
#import "HLPrinter.h"
#import "DeviceListVC.h"

@interface TestViewController ()
{
    Boolean flag;
}
@property (strong, nonatomic)   NSMutableArray    *deviceArray;  /**< 蓝牙设备个数 */
@property (strong, nonatomic)   NSMutableArray    *infos;  /**< 详情数组 */
@property (strong, nonatomic)   CBCharacteristic  *chatacter;  /**< 可写入数据的特性 */
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _deviceArray = [[NSMutableArray alloc] init];
    _infos=[[NSMutableArray alloc] init];
    [self initView];
    [self initBluetooth];
}

-(void)initView{
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame=CGRectMake(150, 200, 80, 50);
    [btn addTarget:self action:@selector(goSelectDevic) forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn setTitle:@"打印" forState:UIControlStateNormal];
    btn.titleLabel.textColor=[UIColor blackColor];
    btn.backgroundColor=[UIColor blueColor];
    [self.view addSubview:btn];
}
-(void)initBluetooth{
    HLBLEManager *manager = [HLBLEManager sharedInstance];
    __weak HLBLEManager *weakManager = manager;
    manager.stateUpdateBlock = ^(CBCentralManager *central) {
        NSString *info = nil;
        switch (central.state) {
            case CBCentralManagerStatePoweredOn:
                info = @"蓝牙已打开，并且可用";
                //三种种方式
                // 方式1
                [weakManager scanForPeripheralsWithServiceUUIDs:nil options:nil];
                //                // 方式2
                //                [central scanForPeripheralsWithServices:nil options:nil];
                //                // 方式3
                //                [weakManager scanForPeripheralsWithServiceUUIDs:nil options:nil didDiscoverPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
                //
                //                }];
                break;
            case CBCentralManagerStatePoweredOff:
                info = @"蓝牙可用，未打开";
                break;
            case CBCentralManagerStateUnsupported:
                info = @"SDK不支持";
                break;
            case CBCentralManagerStateUnauthorized:
                info = @"程序未授权";
                break;
            case CBCentralManagerStateResetting:
                info = @"CBCentralManagerStateResetting";
                break;
            case CBCentralManagerStateUnknown:
                info = @"CBCentralManagerStateUnknown";
                break;
        }
        
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD showInfoWithStatus:info ];
    };
    
    manager.discoverPeripheralBlcok = ^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheral.name.length <= 0) {
            return ;
        }
        
        if (self.deviceArray.count == 0) {
            NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
            [self.deviceArray addObject:dict];
        } else {
            BOOL isExist = NO;
            for (int i = 0; i < self.deviceArray.count; i++) {
                NSDictionary *dict = [self.deviceArray objectAtIndex:i];
                CBPeripheral *per = dict[@"peripheral"];
                if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                    isExist = YES;
                    NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
                    [_deviceArray replaceObjectAtIndex:i withObject:dict];
                }
            }
            if (!isExist) {
                NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
                [self.deviceArray addObject:dict];
            }
        }
    };
}
-(void)goSelectDevic{
    flag=YES;
    if(self.deviceArray.count>1){
        DeviceListVC *vc=[[DeviceListVC alloc] init];
        vc.deviceArray=_deviceArray;
        vc.complete = ^(CBPeripheral *peripheral){
            [self loadBLEInfo:peripheral];//判断是否支持服务
        };
        [self.navigationController pushViewController:vc animated:YES];
    }else if(self.deviceArray.count==1){
        [SVProgressHUD showSuccessWithStatus:@"正在搜索打印服务"];
        [self loadBLEInfo:self.deviceArray[0][@"peripheral"]];//判断是否支持服务
    }else{
        NSString *info=@"未发现打印设备";
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD showInfoWithStatus:info ];
    }
}
-(void)goPrint{
    if(!flag){
        return;
    }
    flag=NO;
    HLPrinter *printer = [self getPrinter];
    if(self.chatacter==nil){
        NSString *info=@"正在搜索打印服务";
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD showInfoWithStatus:info ];
        return;
    }
    NSData *mainData = [printer getFinalData];
    HLBLEManager *bleManager = [HLBLEManager sharedInstance];
    if (self.chatacter.properties & CBCharacteristicPropertyWrite) {
        [bleManager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithResponse completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
            if (!error) {
                NSLog(@"写入成功");
            }else{
                NSString *info=@"未发现打印设备";
                [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
                [SVProgressHUD showInfoWithStatus:info ];
            }
        }];
    } else if (self.chatacter.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [bleManager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithoutResponse];
    }
}

- (HLPrinter *)getPrinter
{
    
    HLPrinter *printer = [[HLPrinter alloc] init];
    NSString *wltitle = @"蜂途物流 | ";
    NSString *wlno = @"1234567890121345";
    [printer appendText:wltitle alignment:HLTextAlignmentLeft];
    [printer appendText:wlno alignment:HLTextAlignmentLeft fontSize:HLFontSizeTitleMiddle];
    [printer appendSeperatorLine];
    //----------------
    NSString *wltype = @"包装类型：纸箱  |  发货日期：2018-04-05";
    [printer appendText:wltype alignment:HLTextAlignmentLeft];
    [printer appendSeperatorLine];
    //----------------
    // 条形码
    [printer appendBarCodeWithInfo:wlno];
    [printer appendSeperatorLine];
    //----------------
    NSString *wladdr = @"目的地信息 | ";
    NSString *wladdrinfo1 = @"杭州市场部";
    NSString *wladdrinfo2 = @"西湖区古墩路1331号";
    [printer appendText:wladdr alignment:HLTextAlignmentLeft];
    [printer appendText:wladdrinfo1 alignment:HLTextAlignmentLeft fontSize:HLFontSizeTitleMiddle];
    [printer appendNewLine];
    [printer appendText:wladdrinfo2 alignment:HLTextAlignmentLeft ];
    [printer appendSeperatorLine];
    //-----------------
    NSString *wlgood = @"货物信息 | ";
    NSString *wlgoodinfo1 = @" 100kg 0.1 |  收件人  |  3/5  ";
    NSString *wlgoodinfo2 = @" 发货网点：杭州市一部  |  备注：     ";
    [printer appendText:wlgood alignment:HLTextAlignmentLeft];
    [printer appendText:wlgoodinfo1 alignment:HLTextAlignmentLeft];
    [printer appendNewLine];
    [printer appendText:wlgoodinfo2 alignment:HLTextAlignmentLeft];
    [printer appendSeperatorLine];

    return printer;
}

- (void)loadBLEInfo:(CBPeripheral *)peripheral
{
    [_infos removeAllObjects];
    HLBLEManager *manager = [HLBLEManager sharedInstance];
    [manager connectPeripheral:peripheral
                connectOptions:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}
        stopScanAfterConnected:YES
               servicesOptions:nil
        characteristicsOptions:nil
                 completeBlock:^(HLOptionStage stage, CBPeripheral *peripheral, CBService *service, CBCharacteristic *character, NSError *error) {
                     switch (stage) {
                         case HLOptionStageConnection:
                         {
                             if (error) {
                                 [SVProgressHUD showErrorWithStatus:@"连接失败"];
                                 
                             } else {
//                                 [SVProgressHUD showSuccessWithStatus:@"连接成功"];
                             }
                             break;
                         }
                         case HLOptionStageSeekServices:
                         {
                             if (error) {
                                 [SVProgressHUD showSuccessWithStatus:@"查找服务失败"];
                             } else {
//                                 [SVProgressHUD showSuccessWithStatus:@"查找服务成功"];
                                 [_infos addObjectsFromArray:peripheral.services];
                                 [self checkService];
                             }
                             break;
                         }
                         case HLOptionStageSeekCharacteristics:
                         {
                             // 该block会返回多次，每一个服务返回一次
                             if (error) {
                                 NSLog(@"查找特性失败");
                             } else {
                                 NSLog(@"查找特性成功");
                                 [self checkService];
                             }
                             break;
                         }
                         case HLOptionStageSeekdescriptors:
                         {
                             // 该block会返回多次，每一个特性返回一次
                             if (error) {
                                 NSLog(@"查找特性的描述失败");
                             } else {
                                 //                                 NSLog(@"查找特性的描述成功");
                             }
                             break;
                         }
                         default:
                             break;
                     }
    }];
}

-(void)checkService{
    for (int i=0; i<[_infos count]; i++) {
        CBService *service = _infos[i];
        for (int j=0; j<service.characteristics.count; j++) {
            CBCharacteristic *character = [service.characteristics objectAtIndex:j];
            CBCharacteristicProperties properties = character.properties;
            /**
             CBCharacteristicPropertyWrite和CBCharacteristicPropertyWriteWithoutResponse类型的特性都可以写入数据
             但是后者写入完成后，不会回调写入完成的代理方法{peripheral:didWriteValueForCharacteristic:error:},
             因此，你也不会受到block回调。
             所以首先考虑使用CBCharacteristicPropertyWrite的特性写入数据，如果没有这种特性，再考虑使用后者写入吧。
             */
            //
            if (properties & CBCharacteristicPropertyWrite) {
                //        if (self.chatacter == nil) {
                //            self.chatacter = character;
                //        }
                self.chatacter = character;
                [self goPrint];//找到服务进行打印
                return;
            }
        }
    }
    [SVProgressHUD showSuccessWithStatus:@"未搜索到打印服务"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
