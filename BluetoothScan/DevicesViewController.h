//
//  DevicesViewController.h
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface DevicesViewController : UIViewController <CBCentralManagerDelegate, /*CBPeripheralDelegate,*/ UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UISwitch *powerSwitch;
@property (strong, nonatomic) IBOutlet UISlider *dimmerSlider;

@end

