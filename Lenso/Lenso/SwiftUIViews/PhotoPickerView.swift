//
//  PhotoPickerView.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import SwiftUI

struct PhotoPickerView: View {
    let title: String
    let systemImageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImageName)
                    .font(.system(size: 28, weight: .medium))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 24)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(TileButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}

private struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tileBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            // Dual shadows for visibility on dark backgrounds: a deeper soft shadow and a subtle top highlight
            .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 14)
            .shadow(color: Color.white.opacity(0.08), radius: 2, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    private var tileBackgroundColor: Color {
        // Always-dark background
        Color(red: 0.12, green: 0.12, blue: 0.12) // ~#1F1F1F
    }
}

struct PhotoPickerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PhotoPickerView(title: "Albüm", systemImageName: "photo.on.rectangle") {}
                .padding()
                .frame(width: 180, height: 160)
                .background(Color.black)
                .previewDisplayName("Dark")
                .preferredColorScheme(.dark)

            PhotoPickerView(title: "Album", systemImageName: "photo.on.rectangle") {}
                .padding()
                .frame(width: 180, height: 160)
                .background(Color(uiColor: .systemBackground))
                .previewDisplayName("Light")
                .preferredColorScheme(.light)
        }
    }
}
