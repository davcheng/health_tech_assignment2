//
//  ViewController.swift
//  Camelot
//
//  Created by Jill Sue on 3/5/17.
//  Copyright © 2017 Jill Sue. All rights reserved.
//

import UIKit
import ResearchKit
import CoreData

class ViewController: UIViewController {
    @IBAction func surveyTapped(_ sender: Any) {
        let taskViewController = ORKTaskViewController(task: SurveyTask, taskRun: nil)
        taskViewController.delegate = self
        present(taskViewController, animated: true, completion: nil)
    }
    
    @IBAction func memoryTapped(_ sender: Any) {
        let taskViewController = ORKTaskViewController(task: SpatialMemoryTask, taskRun: nil)
        taskViewController.delegate = self
        taskViewController.outputDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] , isDirectory: true) as URL
        present(taskViewController, animated: true, completion: nil)
    }
    @IBAction func fitnessTapped(_ sender: Any) {
        let taskViewController = ORKTaskViewController(task: FitnessCheckTask, taskRun: nil)
        taskViewController.delegate = self
        taskViewController.outputDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] , isDirectory: true) as URL
        present(taskViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}
extension ViewController : ORKTaskViewControllerDelegate {
    
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        //Handle results with taskViewController.result
        if (reason==ORKTaskViewControllerFinishReason.completed){
        if (taskViewController.task?.identifier=="SurveyTask"){
            saveData(step_result: taskViewController.result,path: "survey")
        }
        else if (taskViewController.task?.identifier=="FitnessCheck"){
            saveData(step_result: taskViewController.result,path: "fitness")

        }
        else if (taskViewController.task?.identifier=="SpatialMemory"){
            saveData(step_result: taskViewController.result,path: "memory")

        }
        }
        taskViewController.dismiss(animated: true, completion: nil)
        
        
    }
    
    func saveData(step_result:ORKResult,path:String){
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        
        let entity =
            NSEntityDescription.entity(forEntityName: "Result",
                                       in: managedContext)!
        
        let data_values = NSManagedObject(entity: entity,
                                          insertInto: managedContext)
        
        
        
        data_values.setValue(String(describing: step_result), forKeyPath: path)
        
        
        do {
            try managedContext.save()
            print("Saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

