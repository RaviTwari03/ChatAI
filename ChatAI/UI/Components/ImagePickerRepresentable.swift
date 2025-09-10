//
//  ImagePickerRepresentable.swift
//  ChatAI
//
//  Minimal UIKit camera/photo picker for SwiftUI with safe permission/availability checks.
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    enum Source {
        case camera
        case photoLibrary
    }

    var sourceType: Source = .photoLibrary
    /// Called with a captured/picked UIImage or nil on cancel/failure
    var onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        // Use a wrapper VC so we can present alerts when the source is not available
        let host = UIViewController()
        DispatchQueue.main.async {
            presentPicker(from: host, coordinator: context.coordinator)
        }
        return host
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

    // MARK: - Presentation & Safety
    private func presentPicker(from host: UIViewController, coordinator: Coordinator) {
        switch sourceType {
        case .camera:
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                showAlert(on: host, title: "Camera Unavailable", message: "This device doesn't have a camera.")
                self.onPick(nil)
                return
            }
            // Info.plist must include NSCameraUsageDescription or the app will crash on real device
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted { self.presentCamera(from: host, coordinator: coordinator) }
                        else { self.showDenied(on: host) }
                    }
                }
                return
            } else if status == .denied || status == .restricted {
                showDenied(on: host); self.onPick(nil); return
            }
            presentCamera(from: host, coordinator: coordinator)
        case .photoLibrary:
            guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                showAlert(on: host, title: "Photos Unavailable", message: "Photo library is not available.")
                self.onPick(nil)
                return
            }
            presentLibrary(from: host, coordinator: coordinator)
        }
    }

    private func presentCamera(from host: UIViewController, coordinator: Coordinator) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = coordinator
        host.present(picker, animated: true)
    }

    private func presentLibrary(from host: UIViewController, coordinator: Coordinator) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = coordinator
        host.present(picker, animated: true)
    }

    private func showDenied(on host: UIViewController) {
        showAlert(on: host, title: "Camera Permission", message: "Camera access is denied. Please enable it in Settings > Privacy > Camera.")
    }

    private func showAlert(on host: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let url = URL(string: UIApplication.openSettingsURLString) {
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                UIApplication.shared.open(url)
            }))
        }
        host.present(alert, animated: true)
    }
}
