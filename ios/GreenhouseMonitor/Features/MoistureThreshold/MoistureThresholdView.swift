//
//  MoistureThresholdView.swift
//  GreenhouseMonitor
//
//  Created by He Jianghao on 2026/10/15.
//

import SwiftUI

struct MoistureThresholdView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var minimum = "10"
	@State private var maximum = "20"
	
	private var isValid: Bool {
		guard let min = Int(minimum),
			  let max = Int(maximum) else {
			return false
		}
		
		return min >= 0 && max <= 100 && min < max
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
						value: $minimum
					)
					
					thresholdField(
						title: "Maximum (%)",
						value: $maximum
					)
					
					if !minimum.isEmpty && !maximum.isEmpty && !isValid {
						Text("Minimum must be lower than maximum. Values: 0–100%.")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
				
				Section {
					Button(role: .destructive) {
						minimum = ""
						maximum = ""
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
						// Persist the thresholds here.
						dismiss()
					}
					.tint(.green)
					.disabled(!isValid)
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
		}
		.padding(.vertical, 6)
	}
}

#Preview {
	MoistureThresholdView()
}
