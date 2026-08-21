import SwiftUI
import UIKit

struct PortionSliderRepresentable: UIViewRepresentable {
  @Binding var grams: Double
  var range: ClosedRange<Double> = 10...500

  func makeCoordinator() -> Coordinator {
    Coordinator(grams: $grams)
  }

  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider()
    slider.minimumValue = Float(range.lowerBound)
    slider.maximumValue = Float(range.upperBound)
    slider.value = Float(grams)
    slider.minimumTrackTintColor = UIColor(red: 0.184, green: 0.435, blue: 0.929, alpha: 1)
    slider.maximumTrackTintColor = UIColor(red: 0.902, green: 0.922, blue: 0.949, alpha: 1)
    slider.thumbTintColor = UIColor(red: 0.106, green: 0.227, blue: 0.420, alpha: 1)
    slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
    return slider
  }

  func updateUIView(_ slider: UISlider, context: Context) {
    context.coordinator.grams = $grams
    if abs(Double(slider.value) - grams) > 0.5 {
      slider.value = Float(grams)
    }
  }

  final class Coordinator: NSObject {
    var grams: Binding<Double>
    init(grams: Binding<Double>) { self.grams = grams }

    @objc func changed(_ sender: UISlider) {
      grams.wrappedValue = Double(sender.value.rounded())
    }
  }
}
