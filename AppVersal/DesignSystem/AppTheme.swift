//
//  AppTheme.swift
//  AppVersal
//

import SwiftUI
import UIKit
import Combine

public enum AppTheme {
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let card: CGFloat = 20
    }

    public enum Shadow {
        public static let card = ShadowStyle(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

public struct ShadowStyle {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

extension View {
    public func appCardStyle() -> some View {
        self
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppTheme.CornerRadius.card)
            .shadow(color: AppTheme.Shadow.card.color, radius: AppTheme.Shadow.card.radius, x: AppTheme.Shadow.card.x, y: AppTheme.Shadow.card.y)
    }
}
