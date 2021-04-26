//
//  ViewController.swift
//  appleMapRegionMonitoring
//
//  Created by GSS on 2021-04-25.
//

import UIKit
import MapKit

class HomeViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    
    // MARK: - Properties
    let viewModel = HomeVM()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /* Get current location and set the current location to the center of mapView
         */
        checkUsersLocationServicesAuthorization()
    }
    
    
    // MARK: - Checking location permission status
    func checkUsersLocationServicesAuthorization(){
        
        /* Checking location permission status from device
         If allowed : then configure the map, regions for monitoring
         if not allowed : then displayes alert to user, in alert on the click of 'Setting' button it open's the location permission setting in the device , if user change the permissions to allow, then it configure the map , regions for monitoring
         */
        
        if CLLocationManager.locationServicesEnabled() {
            viewModel.locationManager.delegate = self
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                // Request when-in-use authorization initially
                // This is the first and the ONLY time you will be able to ask the user for permission
                viewModel.locationManager.requestWhenInUseAuthorization()
                break
                
            case .restricted, .denied:
                // Disable location features
                let alert = UIAlertController(title: "Allow Location Access", message: "App needs access to your location. Turn on Location Services in your device settings.", preferredStyle: UIAlertController.Style.alert)
                
                // Button to Open Settings
                alert.addAction(UIAlertAction(title: "Settings", style: UIAlertAction.Style.default, handler: { action in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    }
                }))
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                break
                
            case .authorizedWhenInUse, .authorizedAlways:
                
                /* Configure the map , regions for monitoring
                 */
                
                configureMap()
                configureRegions()
                
                break
            }
        }
    }
    
    
    // MARK: - Configure map for location updates
    func configureMap(){
        
        /* Configuring map for displaying user location, requesting location permission
         Also checking if app is launched in any one of the region i.e. school or park
         Displays alert to user if app is active or triggers local push notification, displays user's current location , set mapView zoom level to current location
         */
        
        viewModel.locationManager.delegate = self
        viewModel.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        viewModel.locationManager.pausesLocationUpdatesAutomatically = false
        viewModel.locationManager.allowsBackgroundLocationUpdates = true
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        
        //Zoom to user location
        if let userLocation = viewModel.locationManager.location {
            let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(viewRegion, animated: false)
            
            /* School region :- for checking if current location of user lies in the school region
             */
            let schoolCircle = MKCircle(center: viewModel.schoolRegion, radius: viewModel.regionRadius as CLLocationDistance)
            if userLocation.distance(from: CLLocation(latitude: viewModel.schoolRegion.latitude, longitude: viewModel.schoolRegion.longitude)) < schoolCircle.radius {
                Alerts.shared.displayAlertWithoutAction(title: "Location alert", alertTitle: "ok", message: "We welcome to school")
                viewModel.displayNotification(message: "We welcome to school")
            }
            
            /* Park region :- for checking if current location of user lies in the park region
             */
            let parkCircle = MKCircle(center: viewModel.parkRegion, radius: viewModel.regionRadius as CLLocationDistance)
            if userLocation.distance(from: CLLocation(latitude: viewModel.parkRegion.latitude, longitude: viewModel.parkRegion.longitude)) < parkCircle.radius {
                Alerts.shared.displayAlertWithoutAction(title: "Location alert", alertTitle: "ok", message: "We welcome to park")
                viewModel.displayNotification(message: "We welcome to park")
            }
        }
        
        /* Checking if location services are allowed by user or not
         If allowed : then it checks for location updates
         */
        if CLLocationManager.locationServicesEnabled(){
            viewModel.locationManager.requestAlwaysAuthorization()
            viewModel.locationManager.requestWhenInUseAuthorization()
            viewModel.locationManager.startUpdatingLocation()
            viewModel.locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    // MARK: - Configures mapView for region monitoring 
    func configureRegions(){
        
        /* Displays circlular region in the map
         */
        viewModel.displayCirclularRegion(location: viewModel.schoolRegion, mapView: mapView, locationType: .school)
        viewModel.displayCirclularRegion(location: viewModel.parkRegion, mapView: mapView, locationType: .park)
        
        /* Monitors mapView for getting observed for user entering and exiting to the region
         */
        viewModel.monitorRegionForNotifyingUserEntry(location: viewModel.schoolRegion, locationType: .school)
        viewModel.monitorRegionForNotifyingUserEntry(location: viewModel.parkRegion, locationType: .park)
    }
    
    
    /* Enable/disable the mapView to keep the user location in centre of the map, also changes the text of button
       Set the focus of map to the current location
     */
    @IBAction func enableUserLocationInCenterButtonAction(_ sender: UIButton) {
        viewModel.displayUserLocationInCentre = !viewModel.displayUserLocationInCentre
        let buttonTitle = viewModel.displayUserLocationInCentre ? "Undo user location in center" : "Keep user location in center"
        locationButton.setTitle(buttonTitle, for: .normal)
        
        /* Get current location and set the current location to the center of mapView
         */
        if let userLocation = viewModel.locationManager.location{
            let centerOfUserLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            let region = MKCoordinateRegion(center: centerOfUserLocation, span: viewModel.defaultSpan)
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
        }
    }
}

