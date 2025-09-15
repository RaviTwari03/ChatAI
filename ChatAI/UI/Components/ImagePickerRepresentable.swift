//
//  ImagePickerRepresentable.swift
//  ChatAI
//
//  Lightweight wrapper that returns a configured UIImagePickerController directly.
//  Availability and permission checks should be performed by the caller before presenting.

import SwiftUI
import UIKit

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    enum Source {
        case camera
        case photoLibrary
    }

    var sourceType: Source = .photoLibrary
    /// Called with a captured/picked UIImage or nil on cancel/failure
    var onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let picker = UIImagePickerController()
        switch sourceType {
        case .camera:
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        case .photoLibrary:
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onPick: (UIImage?) -> Void
        init(onPick: @escaping (UIImage?) -> Void) { self.onPick = onPick }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { self.onPick(nil) }
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            picker.dismiss(animated: true) { self.onPick(img) }
        }
    }
}
