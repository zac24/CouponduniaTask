//
//  RestaurantListViewController.m
//  Restaurant List
//
//  Created by Prashant Dwivedi on 19/12/14.
//  Copyright (c) 2014 Prashant Dwivedi. All rights reserved.
//

#import "RestaurantListViewController.h"

@interface RestaurantListViewController ()

@end

@implementation RestaurantListViewController
//@synthesize locationManager;

#define CORNER_RADIUS 14.0f
#define FONT_SIZE 13.0f
#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 80.0f

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Native function called while loading the view.

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = Page_Title;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,[UIFont fontWithName:@"Helvetica Nueue" size:22.0], NSFontAttributeName,nil]];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(150, 250, 20, 30)];
    [self.spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    [self.spinner setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
    [self.spinner setColor:[UIColor blackColor]];
    [self.view addSubview:self.spinner];
    
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 &&
        [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse
        ) {
        // Will open an confirm dialog to get user's approval
        [_locationManager requestWhenInUseAuthorization];
    } else {
        [_locationManager startUpdatingLocation]; //Will update location immediately
    }
   
     [self getListOfRestaurants];
}

// Updates the user location

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currentLocation = [locations objectAtIndex:0];
    CLLocation *location = [locations lastObject];
     CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error){
     if (!(error)){
         CLPlacemark *placemark = [placemarks objectAtIndex:0];
         // to set the section title of UITableView
         [self.locationLabel setText: placemark.name];
         
     }
     else{
         NSLog(@"Geocode failed with error %@", error);
         NSLog(@"\nCurrent Location Not Detected\n");
     }
    }];
    self.myLocation = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    [_locationManager stopUpdatingLocation];
    [self getSortedArray:self.listDataDictionary];

}

// Takes the user authorization for accessing user's location

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"location status are not determined");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"User denied the location permission");
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:Location_turn_off message:Location_turn_msg_off delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            [_locationManager startUpdatingLocation]; //Will update location immediately
        } break;
        default:
            break;
    }
   
}

-(void)getListOfRestaurants{
    NSString *string = [NSString stringWithFormat:@"%@", BASE_URL];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // ============ Using AFNetworking library to contact sever and fetch data =============
    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dataDictionary = (NSDictionary *)responseObject;
        NSLog(@"success");
        if (dataDictionary){
            self.listDataDictionary = [dataDictionary valueForKey:@"data"];
            [self getSortedArray:self.listDataDictionary];
            [self.spinner stopAnimating];
        }
        else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:app_name message:No_data delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:Error message:[error localizedDescription]delegate:nil
                                                  cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
    }];
    [operation start];
}

-(void)getSortedArray:(NSDictionary*) dictionary
{
    self.sortedArray = [[dictionary allValues] sortedArrayUsingComparator:^(id firstObject,id secondObject) {
    CLLocation *firstPointLocation = [ self getLocationBasedOnLatLong:firstObject];
    CLLocation *secondPointLocation = [ self getLocationBasedOnLatLong:secondObject];
    
    CLLocationDistance distanceA = [firstPointLocation distanceFromLocation:self.myLocation];
    CLLocationDistance distanceB = [secondPointLocation distanceFromLocation:self.myLocation];
    
    if (distanceA < distanceB) {
        return NSOrderedAscending;
    } else if (distanceA > distanceB) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
    }];
    [self.restaurantListTableView reloadData];
}

-(CLLocation*)getLocationBasedOnLatLong:(NSArray *)object{
    CGFloat aLatitude = [[object valueForKey:@"Latitude"] floatValue];
    CGFloat aLongitude = [[object valueForKey:@"Longitude"] floatValue];
   return [[CLLocation alloc] initWithLatitude:aLatitude longitude:aLongitude];
}

-(void) updateLabelPropperties:(UILabel *)label tagForLabel:(NSInteger)tag {
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[UIFont fontWithName:@"Helvetica" size:13]];
    [label setTextColor:[UIColor lightGrayColor]];
    [label setTag:tag];
}

#pragma mark - Table view data source methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.sortedArray count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *CellIdentifier = @"Cell";
    UIImageView *restaurantImageView;
    UILabel *outletNameLabel;
    UILabel *offerDetailLabel;
    UILabel *categoryLabel;
    UILabel *neighbourNameLabel;
    UILabel *distancelabel;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier]; // reuse of tableViewCell
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] ;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
// ================ set frames and other properties for outlets Images ======================
        
        restaurantImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0f, 4.0f, 65.0f, 33.0f)];
        [restaurantImageView setBackgroundColor:[UIColor clearColor]];
        restaurantImageView.tag = 011;
        [cell.contentView addSubview:restaurantImageView];
        
// ====================== setting the frames and other properties for outlets Name ========================
        
        outletNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(CELL_CONTENT_MARGIN, 0.0f, CELL_CONTENT_WIDTH -(CELL_CONTENT_MARGIN +5), 25.0f)];
        [outletNameLabel setBackgroundColor:[UIColor clearColor]];
        [outletNameLabel setFont:[UIFont fontWithName:@"Helvetica" size:15]];
        [outletNameLabel setTag:1];
        [cell.contentView addSubview:outletNameLabel];
        
// ===================== setting the frames and properties for other Labels ===============================
        
        offerDetailLabel = [[UILabel alloc]initWithFrame:CGRectMake(CELL_CONTENT_MARGIN, 22.0f, CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN +5), 15.0f)];
        [self updateLabelPropperties:offerDetailLabel tagForLabel:2];
        [cell.contentView addSubview:offerDetailLabel];
        
        categoryLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 38.0f, CELL_CONTENT_WIDTH - 6, 15.0f)];
        [self updateLabelPropperties:categoryLabel tagForLabel:3];
        [cell.contentView addSubview:categoryLabel];
        
        neighbourNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(90, 60.0f, CELL_CONTENT_WIDTH - 85, 15.0f)];
        [self updateLabelPropperties:neighbourNameLabel tagForLabel:4];
        [cell.contentView addSubview:neighbourNameLabel];
        
        distancelabel = [[UILabel alloc]initWithFrame:CGRectMake(10.0f, 60.0f, CELL_CONTENT_WIDTH - 55, 15.0f)];
        [self updateLabelPropperties:distancelabel tagForLabel:5];
        [cell.contentView addSubview:distancelabel];
    }
    
// ================ Inserting the restaurant info into UILabels and imageView =================

    if(!restaurantImageView){
        restaurantImageView = (UIImageView *) [cell viewWithTag:011];
    }
    NSString *imageUrl = [[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"LogoURL"];
    [restaurantImageView setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"navbar.png"]];
    
    if(!outletNameLabel)
        outletNameLabel = (UILabel *)[cell viewWithTag:1];
    [outletNameLabel setText:[[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"OutletName"]];
    
    NSString *offerCount = [[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"NumCoupons"];
    NSString *offerString;
    if (![offerCount intValue] == 0 && [offerCount intValue] > 1) {
        offerString = @" offers";
    }else{
        offerString = @" offer";
    }
    offerCount = [[NSString stringWithFormat:@"%@",offerCount] stringByAppendingString:offerString];
    if (!offerDetailLabel)
        offerDetailLabel = (UILabel*)[cell viewWithTag:2];
    [offerDetailLabel setText:offerCount];
    
    NSString *categoriesName = [[NSString alloc]init];
    NSInteger categoryCount = [[[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"Categories" ]count];
    NSInteger count;
    if (categoryCount >=3) {
        count = 3;
    }else{
        count = categoryCount;
    }
    for (int i = 0; i< count; i++){
        NSString *tmpCategory = [[[[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"Categories" ]objectAtIndex:i]valueForKey:@"Name"];
        tmpCategory = [@" • " stringByAppendingString:tmpCategory];
        if ([tmpCategory isEqual:[NSNull null]] || tmpCategory == NULL) {
        }else{
            categoriesName = [categoriesName stringByAppendingString:tmpCategory];
        }
    }
    
    if (!categoryLabel)
        categoryLabel = (UILabel*)[cell viewWithTag:3];
    [categoryLabel setText:categoriesName];
    
    NSString *neighbourName = [[self.sortedArray objectAtIndex:indexPath.row] valueForKey:@"NeighbourhoodName"];
    if (!neighbourNameLabel)
        neighbourNameLabel = (UILabel*)[cell viewWithTag:4];
    [neighbourNameLabel setText:neighbourName];
    
    if (!distancelabel)
        distancelabel = (UILabel*)[cell viewWithTag:5];
    CLLocation *locA = [self getLocationBasedOnLatLong:[self.sortedArray objectAtIndex:indexPath.row]];
    CLLocationDistance distance = [self.myLocation distanceFromLocation:locA];
    NSString *distanceString = [NSString stringWithFormat:@"%.1fmi",(distance/1609.344)];
    [distancelabel setText:distanceString];

    return cell;
}

#pragma mark - Table view delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    // view for tableView section header
    UIImageView *imageView = [[UIImageView alloc]init] ;
    [imageView setBackgroundColor:[UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0]];
    imageView.frame = CGRectMake(0,0,320,30);
    
    self.locationLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 0, 310, 30)];
    [self.locationLabel setFont:[UIFont fontWithName:@"Helvetica" size:13]];
    [self.locationLabel setTextAlignment:NSTextAlignmentLeft];
    [self.locationLabel setBackgroundColor:[UIColor clearColor]];
    [imageView addSubview:self.locationLabel];
    return imageView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    // These methods aren't available in iOS7 and can give error in Xcode 5.x
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)threadStartAnimating:(id)data
{
    [self.spinner startAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
