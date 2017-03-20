//
//  ViewController.swift
//  GCD
//
//  Created by Vuk on 2/18/17.
//  Copyright © 2017 Vuk. All rights reserved.//
//

import UIKit

class Simulator {
    func simulacijaSaMinimalnimVremenom(min: Int, max: Int) -> Double {
        let miliSek = (Int(arc4random()) % ((max - min) * 1000)) + (min * 1000)
        let vremeCekanja: Double = Double(miliSek) / 1000.0
        Thread.sleep(forTimeInterval: vremeCekanja)
        return vremeCekanja
    }
}

class RezultatiSimulacije: NSObject {
    var vremeSimulacije = Double()
    var ime = String()
}

protocol DelegatKupovineKarata {
    func prikaziRezultateKupovine(rezultat: RezultatiSimulacije) -> Void
}

class KupovinaKarataOperation: Operation {
    var ime = String()
    var delegat: DelegatKupovineKarata!
    
    init(ime: String) {
        self.ime = ime
    }
    
    override func main() {
        var ukupnoVreme = 0.0
        for _ in 0..<5 {
            if self.isCancelled {
                return
            }
            ukupnoVreme = ukupnoVreme + Simulator().simulacijaSaMinimalnimVremenom(min: 1, max: 3)
        }
        let rezultat = RezultatiSimulacije()
        rezultat.ime = self.ime
        rezultat.vremeSimulacije = ukupnoVreme
        
        
        (self.delegat as? NSObject)?.performSelector(onMainThread: (#selector(ViewController().prikaziRezultateKupovineKarata(_:))), withObject: rezultat, waitUntilDone: false)

    }
}

class ViewController: UIViewController {
    
    var spisakImena = ["Ana","Bojana","Ivana","Aleksandra","Marija"]
    var indexImena = 0
    
    @IBOutlet var ime: UILabel!
    @IBOutlet var klizac: UISlider!
    @IBOutlet var textBox: UITextView!
    @IBOutlet var resetuj: UIButton!
    @IBOutlet var kupiKarte: UIButton!
    
    var redZaKarte = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()
        pozadina()
    }
    
    func pozadina() {
        view.backgroundColor = UIColor.gray
        view.alpha = 0.9
        self.ime.text = self.spisakImena[self.indexImena]
    }
    
//    //Simulator
//    func simulacijaSaMinimalnimVremenom(min: Int, max: Int) -> Double {
//        let miliSek = (Int(arc4random()) % ((max - min) * 1000)) + (min * 1000)
//        let vremeCekanja: Double = Double(miliSek) / 1000.0
//        Thread.sleep(forTimeInterval: vremeCekanja)
//        return vremeCekanja
//    }
    

    @IBAction func akcijaKlizaca(_ sender: UISlider) {
        sender.maximumValue = 0.9
        sender.minimumValue = 0.2
        view.backgroundColor? = UIColor.gray.withAlphaComponent(CGFloat(sender.value))
    }
 
    @IBAction func kupovinaKarata(_ sender: UIButton) {
        
        var trenutnoURedu = spisakImena[indexImena]
        self.indexImena = self.indexImena + 1

        let kupovinaKarataNSOperation = BlockOperation { 
            let vremeKupovine: Double = Simulator().simulacijaSaMinimalnimVremenom(min: 2, max: 5)
            DispatchQueue.main.async { //serijski queue
                let poruka = "\(trenutnoURedu), kupila kartu za \(vremeKupovine) sekundi"
                self.stampaUTextBoxu(poruka: poruka)
            }
        }
        //ovo nisam morao da dodam, informativno se printa u konzoli
        kupovinaKarataNSOperation.completionBlock = {
            print("NSOperacija kupovine karata je gotova za \(trenutnoURedu)")
        }
        
        let vremeDobijanjaKarteOdKupovineNSOperation = BlockOperation { 
            let vremePlacanja: Double = Simulator().simulacijaSaMinimalnimVremenom(min: 4, max: 10)
            DispatchQueue.main.async { // serijski queue
                let poruka = "\(trenutnoURedu), je platila svoju kartu za \(vremePlacanja) sekundi"
                self.stampaUTextBoxu(poruka: poruka)
            }
        }
        //ovo sam dodao da bih u konzoli pratio kod koga je placanje stalo pomocu f/je observeValue
        vremeDobijanjaKarteOdKupovineNSOperation.addObserver(self, forKeyPath: "daLiJeOtkazano", options: NSKeyValueObservingOptions.new, context: &trenutnoURedu)
        //ovde se postavlja zavisnost vremenaDobijanjaKarte od prvobitnog izvrsenja kupovineKarate
        vremeDobijanjaKarteOdKupovineNSOperation.addDependency(kupovinaKarataNSOperation)
        //dodavanje u queue, nije vazan redosled kad su postavljeni dependensiji
        redZaKarte.addOperation(vremeDobijanjaKarteOdKupovineNSOperation)
        redZaKarte.addOperation(kupovinaKarataNSOperation)
        
        if indexImena <= spisakImena.count - 1 {
            self.ime.text! = self.spisakImena[self.indexImena]
        }
        else {
            self.ime.text! = "Nema vise nikoga u redu!"
            self.kupiKarte.isEnabled = false
        }
    }
    
    func prikaziRezultateKupovineKarata(rezultat: RezultatiSimulacije) {
        //
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "daLiJeOtkazano" {
            print("Placanje \(context) je otkazano")
        }
    }
    
    func stampaUTextBoxu(poruka: String) {
        var sadrzaj = String()
        if self.textBox.hasText {
            sadrzaj = self.textBox.text.appending("\n")
        }
        sadrzaj = sadrzaj.appending(poruka)
        self.textBox.text = sadrzaj
    }

    @IBAction func resetovanje(_ sender: UIButton) {
        self.indexImena = 0
        self.ime.text = spisakImena[indexImena]
        self.textBox.text = ""
        self.kupiKarte.isEnabled = true
    }
    
    @IBAction func otkazi(_ sender: UIButton) {
        redZaKarte.cancelAllOperations()
    }
    
    

}

