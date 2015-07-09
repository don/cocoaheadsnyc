//
//  ViewController.h
//  Thermometer
//
//  Created by Don Coleman on 7/2/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;

@end

