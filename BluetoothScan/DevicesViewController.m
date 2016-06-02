//
//  DevicesViewController.m
//  BluetoothScan
//
//  Created by Mike Bell on 6/2/16.
//  Copyright © 2016 Chariot Solutions. All rights reserved.
//

#import "DevicesViewController.h"

@interface DevicesViewController () {
    NSMutableArray *devices;
}

@end

@implementation DevicesViewController

- (void)viewDidLoad {
    devices = [NSMutableArray arrayWithObjects:@"BT Device1", @"BT Device2", @"BT Device3", nil];
    [super viewDidLoad];
}

// tableView methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [devices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"deviceCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [devices objectAtIndex:[indexPath row]];
    return cell;
}

@end
