//
//  ViewController.swift
//  BucketListPhotos
//
//  Created by John Gallaugher on 4/25/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let defaultsData = UserDefaults.standard
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var imagePicker = UIImagePickerController()
    var structArray = [ImageInformation]()
    var returningFromSave = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        collectionView.delegate = self
        collectionView.dataSource = self
        imagePicker.delegate = self
        
        readData()
    }
    
    func writeData(image: UIImage) {
        if let imageData = UIImagePNGRepresentation(image) {
            var fileName = ""
            var indexPath: IndexPath!
            
            if (collectionView.indexPathsForSelectedItems?.count)! > 0, let selectedIndexPath = collectionView.indexPathsForSelectedItems?[0] {
                indexPath = selectedIndexPath
            }
            
            if returningFromSave {
                fileName = structArray[indexPath.row].fileName
            } else {
                fileName = NSUUID().uuidString
            }
            
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let writePath = documents + "/" + fileName
            do {
                try imageData.write(to: URL(fileURLWithPath: writePath))
                if returningFromSave {
                    structArray[indexPath.row] = ImageInformation(image: image, fileName: fileName, imageDescription: "")
                } else {
                    structArray.append(ImageInformation(image: image, fileName: fileName, imageDescription: ""))
                }
                let urlArray = structArray.map {$0.fileName!}
                defaultsData.set(urlArray, forKey: "photoURLs")
                collectionView.reloadData()
            } catch {
                print("Error in trying to write imageData for url \(writePath)")
            }
        } else {
            print("Error trying to convert image into a raw data file.")
        }
        returningFromSave = false
    }
    
    func readData() {
        if let urlArray = defaultsData.object(forKey: "photoURLs") as? [String] {
            for index in 0..<urlArray.count {
                let fileManger = FileManager.default
                let fileName = urlArray[index]
                let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let readPath = documents + "/" + fileName
                if fileManger.fileExists(atPath: readPath) {
                    let newImage = UIImage(contentsOfFile: readPath)!
                    structArray.append(ImageInformation(image: newImage, fileName: fileName, imageDescription: ""))
                } else {
                    print("Error: no file exists at path: \(readPath)")
                }
            }
            collectionView.reloadData()
        } else {
            print("Error reading in defaults data")
        }
    }
    
    @IBAction func unwindFromSave(sender: UIStoryboardSegue) {
        returningFromSave = true
        if let source = sender.source as? DetailViewController, let updatedStruct = source.detailStruct {
            if let indexPath = collectionView.indexPathsForSelectedItems?[0] {
                structArray[indexPath.row] = updatedStruct
                writeData(image: updatedStruct.image)
            } else {
                returningFromSave = false
            }
        } else {
            returningFromSave = false
        }
    }
    
    @IBAction func unwindFromDelete(sender: UIStoryboardSegue) {
        if let indexPath = collectionView.indexPathsForSelectedItems?[0] {
            deleteData(index: indexPath.row)
        }
    }
    
    func deleteData(index: Int) {
        let fileManager = FileManager.default
        let fileName = structArray[index].fileName
        
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//        let deletePath = documents.appending(fileName!)
        let deletePath = documents + "/" + fileName!
        do {
            try fileManager.removeItem(atPath: deletePath)
            structArray.remove(at: index)
            let urlArray = structArray.map {$0.fileName!}
            defaultsData.set(urlArray, forKey: "photoURLs")
            collectionView.reloadData()
        } catch {
            print("Error in trying to delete data at filename = \(fileName)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let destination = segue.destination as! DetailViewController
            let indexPath = collectionView.indexPathsForSelectedItems![0]
            destination.detailStruct = structArray[indexPath.row]
        }
    }
    
    @IBAction func photoLibraryButtonPressed(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return structArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCollectionViewCell
        cell.photoImageView.image = structArray[indexPath.row].image
        return cell
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImage = originalImage
        }
        
        if let selectedImage = selectedImage {
            dismiss(animated: true, completion: {self.writeData(image: selectedImage)})
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
