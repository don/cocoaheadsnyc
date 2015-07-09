    //
//  ViewController.h
//  RoboSmart
//
//  Created by Don Coleman on 7/2/15.
//  Copyright (c) 2015 Don Coleman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>
    @property (strong, nonatomic) IBOutlet UISwitch *powerSwitch;
    @property (strong, nonatomic) IBOutlet UISlider *dimmerSlider;

//    - (void) onPowerSwitchChanged:(id)sender;
//    - (void) onDimmerChanged:(id)sender;

    - (void) on;
    - (void) off;
    - (void) brightness: (UInt8)level;
@end



