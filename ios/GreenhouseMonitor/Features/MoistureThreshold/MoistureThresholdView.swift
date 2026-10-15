//
//  MoistureThresholdView.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import SwiftUI

struct MoistureThresholdView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var viewModel: MoistureThresholdViewModel
	
	init(viewModel: MoistureThresholdViewModel) {
		self.viewModel = viewModel
	}
	
	var body: some View {
		NavigationStack {
			Form {
				Section {
					Text("Set the acceptable soil-moisture range for this sensor.")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.listRowBackground(Color.clear)
						.listRowInsets(
							EdgeInsets(
								top: 0,
								leading: 10,
								bottom: 8,
								trailing: 0
							)
						)
					
					thresholdField(
						title: "Minimum (%)",
						value: Binding(
							get: {
								viewModel.moistureThreshold.isEmpty ? "" : Int(viewModel.moistureThreshold.minMoisture).description
							},
							set: { newValue in
								viewModel.moistureThreshold.minMoisture = Double(newValue) ?? 0
							}
						)
					)
					
					thresholdField(
						title: "Maximum (%)",
						value: Binding(
							get: {
								viewModel.moistureThreshold.isEmpty ? "" : Int(viewModel.moistureThreshold.maxMoisture).description
							},
							set: { newValue in
								viewModel.moistureThreshold.maxMoisture = Double(newValue) ?? 0
							}
						)
					)
					
					if !viewModel.moistureThreshold.isValid {
						Text("Minimum must be lower than or equal to maximum. Values: 0–100%.")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
				
				Section {
					Button(role: .destructive) {
						viewModel.clear()
					} label: {
						Label("Clear range", systemImage: "trash").tint(.red)
					}
				}
			}
			.navigationTitle("Moisture thresholds")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Cancel") {
						dismiss()
					}
					.tint(.green)
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button("Save") {
						viewModel.save()
						dismiss()
					}
					.tint(.green)
					.disabled(!viewModel.moistureThreshold.isValid)
				}
			}
		}
	}
	
	private func thresholdField(
		title: String,
		value: Binding<String>
	) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.body)
			
			TextField("Enter value", text: value)
				.keyboardType(.numberPad)
				.multilineTextAlignment(.center)
				.font(.title3)
				.padding(.vertical, 12)
				.background(.background, in: RoundedRectangle(cornerRadius: 12))
				.overlay {
					RoundedRectangle(cornerRadius: 12)
						.stroke(.quaternary, lineWidth: 1)
				}
				.onChange(of: value.wrappedValue) { _, newValue in
					let trimmedValue = String(
						newValue.drop(while: { $0 == "0" })
					)
					
					if trimmedValue != newValue {
						value.wrappedValue = trimmedValue
					}
				}
		}
		.padding(.vertical, 6)
	}
}

//#Preview {
//	MoistureThresholdView(viewModel: <#T##MoistureThresholdViewModel#>)
//}
