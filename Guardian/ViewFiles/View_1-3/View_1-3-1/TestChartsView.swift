//
//  ChartView.swift
//  Guardian
//
//  Created by Teff on 2023/04/22.
//

import SwiftUI
import SwiftUICharts

struct TestChartsView: View {
    var bloodTestData: [BloodTest]
    var skinTestData: [SkinTest]
    var oralFoodChallengeData: [OralFoodChallenge]
    var selectedTestIndex: Int

    var body: some View {
        Group {
            if selectedTestIndex == 0 {
//                VStack {
//                    Text("IgEレベル推移")
//                        .font(.headline)
                LineChartView(data: bloodTestData.map { Double($0.bloodTestLevel) ?? 0 }.reversed(), title: "IgEレベル(UA/mL)")
//                }
            } else if selectedTestIndex == 1 {
//                VStack {
//                    Text("Skin Test Chart")
//                        .font(.headline)
                    LineChartView(data: skinTestData.map { Double($0.skinTestResultValue) ?? 0 }.reversed(), title: "膨疹径(mm)")
//                }
            } else {
//                VStack {
//                    Text("Oral Food Challenge Chart")
//                        .font(.headline)
                    LineChartView(data: oralFoodChallengeData.map { Double($0.oralFoodChallengeQuantity) ?? 0 }.reversed(), title: "摂取量(mm)")
//                }
            }
        }
    }
}
