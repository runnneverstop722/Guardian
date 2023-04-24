//
//  ChartView.swift
//  Guardian
//
//  Created by Teff on 2023/04/22.
//

import SwiftUI
import SwiftUICharts

struct ChartsView: View {
    var bloodTestData: [BloodTest]
    var skinTestData: [SkinTest]
    var oralFoodChallengeData: [OralFoodChallenge]
    var selectedTestIndex: Int

    var body: some View {
        Group {
            if selectedTestIndex == 0 {
                LineChartView(data: bloodTestData.map { Double($0.bloodTestLevel) ?? 0 }.reversed(), title: "IgEレベル(UA/mL)")
                    .imageScale(.large)
            } else if selectedTestIndex == 1 {
                    LineChartView(data: skinTestData.map { Double($0.skinTestResultValue) ?? 0 }.reversed(), title: "膨疹径(mm)")
            } else {
                    LineChartView(data: oralFoodChallengeData.map { Double($0.oralFoodChallengeQuantity) ?? 0 }.reversed(), title: "摂取量(mm)")
            }
        }
    }
}
