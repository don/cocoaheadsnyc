//
//  DeviceTableViewCell.h
//  BluetoothScan
//
//  Created by Mike Bell on 6/3/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UILabel *lblUUID;
@property (weak, nonatomic) IBOutlet UILabel *lblRSSI;

@end
