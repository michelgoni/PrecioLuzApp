import Foundation

enum PricesPresetCatalog {
    private static let airConditionerPowerKW = 1.2
    private static let clothesDryerPowerKW = 2.5
    private static let dishwasherPowerKW = 1.5
    private static let electricHeaterPowerKW = 1.8
    private static let electricVehiclePowerKW = 7.2
    private static let inductionCooktopPowerKW = 1.8
    private static let ovenPowerKW = 2.2
    private static let washingMachinePowerKW = 2.0
    private static let waterHeaterPowerKW = 2.0

    static var all: [AppliancePreset] {
        [
            preset(
                shortDescription: String(localized: "prices.calculation.preset.airConditioner.description"),
                kind: .airConditioner,
                displayName: String(localized: "prices.calculation.preset.airConditioner.name"),
                powerKW: airConditionerPowerKW,
                symbolName: "fan"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.clothesDryer.description"),
                kind: .clothesDryer,
                displayName: String(localized: "prices.calculation.preset.clothesDryer.name"),
                powerKW: clothesDryerPowerKW,
                symbolName: "wind"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.dishwasher.description"),
                kind: .dishwasher,
                displayName: String(localized: "prices.calculation.preset.dishwasher.name"),
                powerKW: dishwasherPowerKW,
                symbolName: "drop"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.electricHeater.description"),
                kind: .electricHeater,
                displayName: String(localized: "prices.calculation.preset.electricHeater.name"),
                powerKW: electricHeaterPowerKW,
                symbolName: "thermometer.medium"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.electricVehicle.description"),
                kind: .electricVehicle,
                displayName: String(localized: "prices.calculation.preset.electricVehicle.name"),
                powerKW: electricVehiclePowerKW,
                symbolName: "car"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.inductionCooktop.description"),
                kind: .inductionCooktop,
                displayName: String(localized: "prices.calculation.preset.inductionCooktop.name"),
                powerKW: inductionCooktopPowerKW,
                symbolName: "cooktop"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.oven.description"),
                kind: .oven,
                displayName: String(localized: "prices.calculation.preset.oven.name"),
                powerKW: ovenPowerKW,
                symbolName: "flame"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.washingMachine.description"),
                kind: .washingMachine,
                displayName: String(localized: "prices.calculation.preset.washingMachine.name"),
                powerKW: washingMachinePowerKW,
                symbolName: "washer"
            ),
            preset(
                shortDescription: String(localized: "prices.calculation.preset.waterHeater.description"),
                kind: .waterHeater,
                displayName: String(localized: "prices.calculation.preset.waterHeater.name"),
                powerKW: waterHeaterPowerKW,
                symbolName: "drop.degreesign"
            ),
        ]
    }

    static func preset(for kind: AppliancePreset.Kind) -> AppliancePreset {
        all.first(where: { $0.kind == kind }) ?? fallbackPreset
    }

    private static var fallbackPreset: AppliancePreset {
        preset(
            shortDescription: String(localized: "prices.calculation.preset.washingMachine.description"),
            kind: .washingMachine,
            displayName: String(localized: "prices.calculation.preset.washingMachine.name"),
            powerKW: washingMachinePowerKW,
            symbolName: "washer"
        )
    }

    private static func preset(
        shortDescription: String,
        kind: AppliancePreset.Kind,
        displayName: String,
        powerKW: Double,
        symbolName: String
    ) -> AppliancePreset {
        AppliancePreset(
            displayName: displayName,
            kind: kind,
            powerKW: powerKW,
            shortDescription: shortDescription,
            symbolName: symbolName
        )
    }
}
