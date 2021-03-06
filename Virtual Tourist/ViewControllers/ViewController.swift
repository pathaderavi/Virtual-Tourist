//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Ravikiran Pathade on 3/19/18.
//  Copyright © 2018 Ravikiran Pathade. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class ViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    var deleteMode:Bool = false
    
    @IBAction func editButton(_ sender: Any) {
        bottomToolbar.isHidden = !bottomToolbar.isHidden
        if !bottomToolbar.isHidden{
            mapView.frame.origin.y =   mapView.frame.origin.y - bottomToolbar.frame.height
            deleteMode = true
        }else{
            mapView.frame.origin.y = mapView.frame.origin.y + bottomToolbar.frame.height
            deleteMode = false
        }
    }
    @IBOutlet weak var bottomToolbar: UIToolbar!
    var dataController:DataController!
    var selectedPin:Pin!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    @IBOutlet weak var mapView: MKMapView!
    var allPins:[Pin]!
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func fetchResults() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key:"lattitude",ascending:false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
            allPins = fetchedResultsController.fetchedObjects
        }catch{
            fatalError("Cannot fetch")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomToolbar.isHidden = true
        fetchResults()
        
        mapView.delegate = self
        let longPress = UILongPressGestureRecognizer(target:self , action: #selector(addAnnotation(pressed:)))
        longPress.minimumPressDuration = 0.4
        mapView.addGestureRecognizer(longPress)
        
        var annotations = [MKPointAnnotation]()
        
        if let fetched = fetchedResultsController?.fetchedObjects{
            let count = fetched.count
            for pin in 0..<count{
                let currentPin = fetched[pin] as! Pin
                let annotation = MKPointAnnotation()
                let lat = currentPin.lattitude
                let long = currentPin.longitude
                let coordinate = CLLocationCoordinate2D(latitude:CLLocationDegrees(lat),longitude:CLLocationDegrees(long))
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            DispatchQueue.main.async {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(annotations)
                self.mapView.delegate = self
            }
        }
        
    }
    
    @objc func addAnnotation(pressed : UILongPressGestureRecognizer){
        DispatchQueue.global(qos: .userInitiated).async {
            
            if pressed.state == .began && !self.deleteMode{
                let location = pressed.location(in: self.mapView)
                let coordinates = self.mapView.convert(location, toCoordinateFrom: self.mapView)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinates
                self.selectedPin = Pin(context:self.dataController.viewContext)
                self.selectedPin.lattitude = coordinates.latitude
                self.selectedPin.longitude = coordinates.longitude
                
                try? self.dataController.viewContext.save()
                self.allPins.append(self.selectedPin)
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotation)
                }
        
            }
            
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        pinView!.canShowCallout = false
        pinView?.animatesDrop = true
        return pinView
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if deleteMode{
            fetchResults()
            let selectedIndex = allPins.index(where:{
                $0.longitude == view.annotation?.coordinate.longitude && $0.lattitude == view.annotation?.coordinate.latitude
            })
            let deletePin = allPins[selectedIndex!]
            
            fetchedResultsController.managedObjectContext.delete(deletePin)
            try? dataController.viewContext.save()
            self.mapView.removeAnnotation(view.annotation!)
            mapView.deselectAnnotation(view.annotation, animated: true)
        }else{
            let selectedIndex = allPins.index(where:{
                $0.longitude == view.annotation?.coordinate.longitude && $0.lattitude == view.annotation?.coordinate.latitude
            })
            tappedPin = allPins[selectedIndex!]
            mapView.deselectAnnotation(view.annotation, animated: true)
            latt = view.annotation?.coordinate.latitude
            long = view.annotation?.coordinate.longitude
            performSegue(withIdentifier: "PhotosView", sender: self)
        }
    }
    var latt:Double!
    var long:Double!
    var tappedPin:Pin!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "PhotosView"{
            if let photosController = segue.destination as? PhotosViewController{
                photosController.lattitude = latt
                photosController.longitude = long
                photosController.dataController = dataController
                photosController.pin = tappedPin
            }
        }
    }
    
}

