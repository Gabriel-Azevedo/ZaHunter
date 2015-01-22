//
//  Pizzeria.h
//  ZaHunter
//
//  Created by Gabriel Borri de Azevedo on 1/21/15.
//  Copyright (c) 2015 Gabriel Enterprises. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Pizzeria : NSObject

@property MKMapItem *mapItem;
@property float metersAway;
@property float time;
@property CLLocationCoordinate2D coordinate;

@end
