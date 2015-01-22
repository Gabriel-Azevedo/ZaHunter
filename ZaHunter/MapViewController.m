//
//  MapViewController.m
//  ZaHunter
//
//  Created by Gabriel Borri de Azevedo on 1/22/15.
//  Copyright (c) 2015 Gabriel Enterprises. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "Pizzeria.h"

@interface MapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property NSMutableArray *annotationsArray;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.annotationsArray = [NSMutableArray new];
    self.mapView.delegate = self;
    [self pinEachRestaurant];
    self.mapView.showsUserLocation = YES;
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];

   if (![[annotation title] isEqualToString:@"Current Location"])
    {
        pin.image = [UIImage imageNamed:@"pizza"];
    }
    pin.canShowCallout = YES;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return pin;


}

-(void)pinEachRestaurant
{
    for (int i = 0; i < 4; i++)
    {
        Pizzeria *pizzeria = [self.pizzeriasArray objectAtIndex:i];
        CLLocationDegrees longitude = pizzeria.coordinate.longitude;

        CLLocationDegrees latitude = pizzeria.coordinate.latitude;
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

        MKPointAnnotation *annotation = [MKPointAnnotation new];
        annotation.title = [[pizzeria mapItem] name];
        annotation.coordinate  = coordinate;

        [self.mapView addAnnotation:annotation];
        [self.annotationsArray addObject:annotation];
    }
    [self.mapView showAnnotations:self.annotationsArray animated:YES];
}

@end
