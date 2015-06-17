//
//  InterfaceController.h
//  Z8Remote WatchKit Extension
//
//  Created by Quinn Ebert on 2015-06-16.
//  Copyright (c) 2015 Quinn Ebert Networked Technology manufactured for Damien Dalli. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *lblSource;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *lblVolume;
@property (strong, nonatomic) IBOutlet WKInterfaceSlider *slider;

@end
