//
//  PermissionPromptView.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import SwiftUI

struct PermissionPromptView: View {
    let message: String
    let buttonTitle: String
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            // Dark overlay that covers the entire container
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "folder")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.6))

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .font(.system(size: 18, weight: .semibold))
                    .lineSpacing(4)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Button(action: onContinue) {
                    Text(buttonTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
                .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 10)
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
struct PermissionPromptView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionPromptView(
            message: "permission.prompt.message",
            buttonTitle: "permission.prompt.button",
            onContinue: {}
        )
        .background(Color.black)
        .preferredColorScheme(.dark)
        .previewLayout(.sizeThatFits)
    }
}
#endif


