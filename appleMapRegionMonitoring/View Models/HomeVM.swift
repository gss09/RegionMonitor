//
//  HomeVM.swift
//  appleMapRegionMonitoring
//
//  Created by GSS on 2021-04-25.
//

import Foundation
import CoreLocation
import MapKit

class HomeVM{
    // MARK: - Properties
    var locationManager = CLLocationManager()
    var displayUserLocationInCentre = false
    
    var schoolRegion = CLLocationCoordinate2D(latitude: 43.861433, longitude: -78.836460)
    var parkRegion = CLLocationCoordinate2D(latitude: 43.861870, longitude: -78.832683)
    var regionRadius :CLLocationDistance = 100
    var span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    var defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // defaultSpan used on the click of locationButton
    
    
    // MARK: - Configures mapView for region monitoring

    /**
     Configures mapView for region monitoring
     - Parameters :
     - location: location of the region
     - locationType : type of region from enum 'LocationType' i.e. school or park
     */
    
    func monitorRegionForNotifyingUserEntry(location:CLLocationCoordinate2D,locationType:LocationType){
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                let region = CLCircularRegion(center: location, radius: regionRadius, identifier: locationType.rawValue)
                region.notifyOnEntry = true
                region.notifyOnExit = false
                
                locationManager.startMonitoring(for: region)
            }
        }
    }
    
    // MARK: - Displays circlular region in the map
    /**
     Displays circlular region in the map
     - Parameters :
     - location: location of the region
     - mapView: mapView to draw circular regions
     - locationType : type of region from enum 'LocationType' i.e. school or park
     */
    func displayCirclularRegion(location: CLLocationCoordinate2D, mapView:MKMapView,locationType:LocationType) {
        let circle = MKCircle(center: location, radius: regionRadius)
        mapView.addOverlay(circle)
        
        /* Add annotation to the map based on the lat long of regions
         */
        
        addAnnotationToMapView(location: location, mapView: mapView, locationType: locationType)
    }
    
    // MARK: - Add annotations to mapView
    /**
     Add annotations to mapView
     - Parameters :
     - location: location of the region
     - mapView: mapView to draw circular regions
     - locationType : type of region from enum 'LocationType' i.e. school or park
     */
    func addAnnotationToMapView(location: CLLocationCoordinate2D, mapView:MKMapView,locationType:LocationType){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = locationType.rawValue
        mapView.addAnnotation(annotation)
        
        /* Get name from location and set subtitle for the annotation
         */
        
        getPlaceInfoFromLatLong(location: location, annotation: annotation)
    }
    
    // MARK: - Set subtitle for annotation
    /**
        Getting location name and locality and set it to subtitle of annotation
     - Parameters :
     - location: location of the region
     - annotation: annotation to displays the sub title
     */
    func getPlaceInfoFromLatLong(location: CLLocationCoordinate2D,annotation: MKPointAnnotation){
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) {
            (placemarks, error) -> Void in
            
            if error == nil {
                if let placemark = placemarks?[0] , let name = placemark.name , let locality = placemark.locality{
                    annotation.subtitle = name + ", " + locality
                }
            } else {
                // An error occurred during geocoding.
                print(error?.localizedDescription as? String)
            }
        }
    }
    
    // MARK: - Triggers local notification if app is not active and user enters in anyone of monitored region
    /**
     Triggers local notification if app is not active and user enters in anyone of monitored region
     - Parameters :
     - message: message to displayed in the body of notification
     */
    func displayNotification(message:String){
        if UIApplication.shared.applicationState != .active {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = message
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "locationUpdate",content: notificationContent,trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error: \(error)")
                }
            }
        }
    }
}


extension HomeViewController:CLLocationManagerDelegate{
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        viewModel.span = mapView.region.span
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - Triggers this func when user enters in anyone of monitored region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if region.identifier == LocationType.school.rawValue{
            Alerts.shared.displayAlertWithoutAction(title: "Location alert", alertTitle: "ok", message: "We welcome to school")
            viewModel.displayNotification(message: "We welcome to school")
        }else{
            Alerts.shared.displayAlertWithoutAction(title: "Location alert", alertTitle: "ok", message: "We welcome to park")
            viewModel.displayNotification(message: "We welcome to park")
        }
    }
    
    // MARK: - Location permission updated by user
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUsersLocationServicesAuthorization()
    }
    
}

extension HomeViewController: MKMapViewDelegate {
    
    // MARK: - Add circluar overlay to the monitored region
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var circleRenderer = MKCircleRenderer()
        if let overlay = overlay as? MKCircle {
            circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = .green
            circleRenderer.strokeColor = .gray
            circleRenderer.alpha = 0.4
        }
        return circleRenderer
    }
    
    // MARK: - Gets triggered based on user location updation
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let centerOfUserLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        /* displayUserLocationInCentre :- for checking if user enable location button to keep current location in the center of the mapView
         */
        
        if viewModel.displayUserLocationInCentre{
            let region = MKCoordinateRegion(center: centerOfUserLocation, span: viewModel.span)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
        }
    }
}

/* Specify different types of region names
 */
enum LocationType : String{
    case school = "School"
    case park = "Park"
}
