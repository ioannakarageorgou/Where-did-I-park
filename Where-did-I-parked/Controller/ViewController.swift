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

    @IBOutlet var backgroundGradientView: UIView!
    @IBOutlet weak var locationLabel: UIButton!
    @IBOutlet weak var justParkedButton: UIButton!
    @IBOutlet weak var findCarButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    let userDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientView()
        
        locationLabel.isHidden = true
        locationLabel.addBlurEffect(style: .light, cornerRadius: 20, padding: 0)
        justParkedButton.addBlurEffect(style: .light, cornerRadius: 10, padding: 0)
        findCarButton.addBlurEffect(style: .light, cornerRadius: 10, padding: 0)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if let currentLocation = loadUserLocation(), let currentAddress = loadUserAddress() {
            print("LOADED: currentLocation = \(currentLocation), currentAddress = \(currentAddress)")
            updateCurrentAddressButton(with: currentAddress)
        }
    }

    @IBAction func justParkedPressed(_ sender: Any) {
        print("justParkedPressed")
        DispatchQueue.global().async {
            self.locationManager.requestWhenInUseAuthorization()
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    @IBAction func findMyCarPressed(_ sender: Any) {
        if let parkingLocation = loadUserLocation() {
            openGoogleMap(to: parkingLocation)
        }
    }
    
    func setupGradientView() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor(rgb: 0x4543A4).cgColor, UIColor(rgb: 0xa2a1d1).cgColor]
        gradientLayer.shouldRasterize = true
        backgroundGradientView.layer.insertSublayer(gradientLayer, at: 0)
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
    
    func updateCurrentAddressButton(with title: String) {
        DispatchQueue.main.async {
            if !title.isEmpty {
                self.locationLabel.isHidden = false
                self.locationLabel.setTitle(title, for: .normal)
                self.locationLabel.titleLabel?.font = UIFont(name: "Nunito Medium", size: 18)
                self.locationLabel.titleLabel?.textColor = UIColor.white
                self.locationLabel.titleLabel?.numberOfLines = 0
                self.locationLabel.titleLabel?.lineBreakMode = .byWordWrapping
            }
        }
    }
    
    func openGoogleMap(to location: CLLocation) {
        if let parkingLocation = loadUserLocation() {
            let destLat = parkingLocation.coordinate.latitude
            let destLon = parkingLocation.coordinate.longitude
            
            if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                //if phone has an app(
                if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(Double(destLat)),\(Double(destLon))&directionsmode=walking") {
                    UIApplication.shared.open(url, options: [:])
                 }
            } else {
                //Open in browser
                if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(Double(destLat)),\(Double(destLon))&directionsmode=walking") {
                    UIApplication.shared.open(urlDestination)
                }
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
                        print("getUserAddress:: current address: \(address)")
                        currentAddress = address
                        self.saveUserAddress(currentAddress)
                        self.updateCurrentAddressButton(with: address)
                    }
                }

            }
        return currentAddress
    }
}
