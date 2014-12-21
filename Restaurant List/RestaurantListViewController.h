//
//  RestaurantListViewController.h
//  Restaurant List
//
//  Created by Prashant Dwivedi on 19/12/14.
//  Copyright (c) 2014 Prashant Dwivedi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RestaurantListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
{
    //CLLocationManager *locationManager;
}

@property (nonatomic, strong) IBOutlet UITableView *restaurantListTableView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDictionary *listDataDictionary;
@property (nonatomic, assign) BOOL locationStatus;
@property (nonatomic, strong) NSArray *sortedArray;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) CLLocation *myLocation;

@end
