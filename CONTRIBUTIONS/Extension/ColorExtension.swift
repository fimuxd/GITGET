//
//  ColorExtension.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import SwiftUI

extension Color {
    static var background: Color {
        Color("WidgetBackground")
    }

    static var level0: Color {
        Color("lv0")
    }

    // MARK: - Default Theme
    static var default1: Color { .palette(0.675, 0.902, 0.678) }
    static var default2: Color { .palette(0.251, 0.769, 0.388) }
    static var default3: Color { .palette(0.188, 0.631, 0.306) }
    static var default4: Color { .palette(0.129, 0.431, 0.224) }

    // MARK: - Classic Theme
    static var classic1: Color { .palette(0.775, 0.876, 0.545) }
    static var classic2: Color { .palette(0.517, 0.754, 0.435) }
    static var classic3: Color { .palette(0.274, 0.553, 0.251) }
    static var classic4: Color { .palette(0.169, 0.332, 0.161) }

    // MARK: - Black and White Theme
    static var blackAndWhite1: Color { .palette(0.851, 0.851, 0.851) }
    static var blackAndWhite2: Color { .palette(0.651, 0.651, 0.651) }
    static var blackAndWhite3: Color { .palette(0.251, 0.251, 0.251) }
    static var blackAndWhite4: Color { .palette(0.149, 0.149, 0.149) }

    // MARK: - Jeju Ocean Theme
    static var jejuOcean1: Color { .palette(178, 255, 218) }
    static var jejuOcean2: Color { .palette(51, 245, 183) }
    static var jejuOcean3: Color { .palette(0, 195, 200) }
    static var jejuOcean4: Color { .palette(0, 133, 164) }

    // MARK: - Halloween Theme
    static var halloween1: Color { .palette(255, 227, 146) }
    static var halloween2: Color { .palette(242, 116, 6) }
    static var halloween3: Color { .palette(191, 53, 5) }
    static var halloween4: Color { .palette(38, 1, 1) }

    // MARK: - Warm Winter Theme
    static var warm1: Color { .palette(240, 211, 190) }
    static var warm2: Color { .palette(192, 105, 76) }
    static var warm3: Color { .palette(115, 59, 47) }
    static var warm4: Color { .palette(33, 64, 64) }

    // MARK: - Fall Theme
    static var fall1: Color { .palette(254, 245, 108) }
    static var fall2: Color { .palette(242, 182, 7) }
    static var fall3: Color { .palette(217, 142, 6) }
    static var fall4: Color { .palette(64, 50, 12) }

    // MARK: - Freestyle Theme
    static var freestyle1: Color { .palette(190, 253, 255) }
    static var freestyle2: Color { .palette(255, 133, 133) }
    static var freestyle3: Color { .palette(20, 17, 242) }
    static var freestyle4: Color { .palette(6, 1, 115) }

    // MARK: - Christmas Theme
    static var christmas1: Color { .palette(255, 225, 135) }
    static var christmas2: Color { .palette(239, 36, 52) }
    static var christmas3: Color { .palette(21, 132, 68) }
    static var christmas4: Color { .palette(115, 2, 2) }

    private static func palette(_ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1.0) -> Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    private static func palette(_ red: Int, _ green: Int, _ blue: Int, alpha: Double = 1.0) -> Color {
        palette(Double(red) / 255.0, Double(green) / 255.0, Double(blue) / 255.0, alpha: alpha)
    }
}
