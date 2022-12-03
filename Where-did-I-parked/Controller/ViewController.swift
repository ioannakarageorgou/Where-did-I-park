//
//  ViewController.swift
//  Where-did-I-parked
//
//  Created by Ioanna Karageorgou on 28/11/22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var locationLabel: UIButton!
    @IBOutlet weak var justParkedButton: UIButton!
    @IBOutlet weak var findCarButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationLabel.isHidden = true
        justParkedButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        findCarButton.addBlurEffect(style: .regular, cornerRadius: 10, padding: 0)
        
        map.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if let currentLocation = loadUserLocation(), let currentAddress = loadUserAddress() {
            print("LOADED: currentLocation = \(currentLocation), currentAddress = \(currentAddress)")
            removeOldAnnotations()
            addPinToCurrentLocation(currentLocation)
            updateCurrentAddressButton(with: currentAddress)
        }
        
//        self.overrideUserInterfaceStyle = .dark
//        let darkLayer = CALayer()
//        darkLayer.frame = self.view.bounds
//        darkLayer.compositingFilter = "darkMode"
//        darkLayer.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7).cgColor
//        self.map.layer.addSublayer(darkLayer)

    }

    @IBAction func justParkedPressed(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
//            locationManager.requestLocation()
        }
    }
    
    func saveUserLocation(_ location: CLLocation) {
        if let encodedLocation = try? NSKeyedArchiver.archivedData(withRootObject: location, requiringSecureCoding: false) {
            userDefaults.set(encodedLocation, forKey: "savedLocation")
        }
    }
    
    func loadUserLocation() -> CLLocation? {
        if let loadedLocation = userDefaults.data(forKey: "savedLocation"),
           let decodedLocation = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(loadedLocation) as? CLLocation {
            return decodedLocation
        }
        return nil
    }
    
    func saveUserAddress(_ address: String) {
        userDefaults.set(address, forKey: "savedAddress")
    }
    
    func loadUserAddress() -> String? {
        if let loadedAddress = userDefaults.string(forKey: "savedAddress") {
            return loadedAddress
        }
        return nil
    }
    
    func addPinToCurrentLocation(_ location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: true)
        
        let mkAnnotation: MKPointAnnotation = MKPointAnnotation()
        mkAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
        map.addAnnotation(mkAnnotation)
    }
    
    func updateCurrentAddressButton(with title: String) {
        DispatchQueue.main.async {
            if !title.isEmpty {
                self.locationLabel.isHidden = false
                self.locationLabel.addBlurEffect(style: .regular, cornerRadius: 20, padding: 0)
                self.locationLabel.setTitle(title, for: .normal)
            }
        }
    }
}

//MARK: - CLLocation Manager Delegate Methods

extension ViewController : CLLocationManagerDelegate {
    
////    This method can cause UI unresponsiveness if invoked on the main thread. Instead, consider waiting for the `-locationManagerDidChangeAuthorization:` callback and checking `authorizationStatus` first.
////
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        if manager.authorizationStatus == CLAuthorizationStatus.denied {
//            // The user denied authorization
//        } else if manager.authorizationStatus == CLAuthorizationStatus.authorizedAlways {
//            // The user accepted authorization
//        }
//    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManager.didFailWithError \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            
            removeOldAnnotations()
            addPinToCurrentLocation(location)
            
            saveUserLocation(location)
            let currentAddress = getUserAddress(location)
            saveUserAddress(currentAddress)
        }
    }
    
    func getUserAddress(_ location: CLLocation) -> String {
        var currentAddress: String = ""
        let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { (placemarksArray, error) in
                print(placemarksArray!)
                if (error) == nil {
                    if placemarksArray!.count > 0 {
                        let placemark = placemarksArray?[0]
                        let address = "\(placemark?.thoroughfare ?? "") \(placemark?.subThoroughfare ?? "") \(placemark?.locality ?? "") \(placemark?.postalCode ?? "") \(placemark?.country ?? "")"
                        print("current address: \(address)")
                        currentAddress = address
                        print("currentAddress = \(currentAddress)")
                        self.saveUserAddress(currentAddress)
                        self.updateCurrentAddressButton(with: address)
                    }
                }

            }
        return currentAddress
    }
    
    func removeOldAnnotations() {
        let annotations = self.map.annotations
        print("Removing old annotations (\(annotations.count)")
        for annotation in annotations {
            self.map.removeAnnotation(annotation)
        }
    }
}

//MARK: - MKMap View Delegate Methods

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        annotationView.markerTintColor = UIColor(rgb: 0x4543A4)
        annotationView.glyphImage = UIImage(named: "car.rear")
        return annotationView
    }
}
