import SwiftUI

struct ErrorView: View {
    struct PermissionButton {
        let title: String
        let action: () -> Void
    }

    let description: String
    let button: PermissionButton
    
    var body: some View {
        VStack {
            LottieView(name: "error")
                .frame(height: 150)
                .padding(.bottom, 50)
            Text(description)
                .multilineTextAlignment(.center)
                .padding(.bottom, 25)
                .padding(.horizontal, 20)
                .font(.system(size: 18))
                .foregroundColor(Color.black)
            Button(
                action: button.action,
                label: {
                    Text(button.title)
                        .foregroundColor(.white)
                        .padding()
                        .font(.system(size: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25).stroke(Color.white, lineWidth: 2)
                        )
                }
            )
            .background(Color.green)
            .cornerRadius(25)
        }
    }
}
