internal import Combine
import SwiftUI
import ToastWindow

@MainActor
class Message: ObservableObject {

    static let shared = Message()

    private var toastManager: ToastManager?

    private init() {}

    func register(_ manager: ToastManager) {
        self.toastManager = manager
    }

    func show(_ message: String, duration: Double = 2) {
        toastManager?.showToast(duration: duration) {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.6))
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                .frame(maxWidth: 350)
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func showError(_ message: String, duration: Double = 2) {
        toastManager?.showToast(duration: duration) {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundColor(.red)

                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.6))
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                .frame(maxWidth: 350)
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
