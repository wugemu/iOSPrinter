//
//  DeviceListVC.m
//  HLBluetoothDemo
//
//  Created by jessie on 2018/6/14.
//  Copyright © 2018年 Halley. All rights reserved.
//

#import "DeviceListVC.h"
#import "SVProgressHUD.h"

@interface DeviceListVC ()
{
    UITableView *tableView;
}
@end

@implementation DeviceListVC 

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    [self initBluetooth];
}
-(void)initView{
    UILabel *titleLab=[[UILabel alloc] init];
    titleLab.frame=CGRectMake(([[UIScreen mainScreen] bounds].size.width-200)/2, 20, 200, 40);
    titleLab.text=@"选择设备";
    titleLab.textColor=[UIColor blackColor];
    titleLab.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:titleLab];
    
    tableView=[[UITableView alloc] init];
    tableView.frame=CGRectMake(0, 60, [[UIScreen mainScreen] bounds].size.width , [[UIScreen mainScreen] bounds].size.height-20);
    tableView.delegate=self;
    tableView.dataSource=self;
    [self.view addSubview:tableView];
    [tableView reloadData];
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
            [tableView reloadData];
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
                [tableView reloadData];
            }
        }
    };
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"deviceId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
    CBPeripheral *peripherral = dict[@"peripheral"];
    cell.textLabel.text = [NSString stringWithFormat:@"名称:%@",peripherral.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"信号强度:%@",dict[@"RSSI"]];
    if (peripherral.state == CBPeripheralStateConnected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = dict[@"peripheral"];
    if (self.complete) {
        self.complete(peripheral);
    }
    [self.navigationController popViewControllerAnimated:YES];
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
