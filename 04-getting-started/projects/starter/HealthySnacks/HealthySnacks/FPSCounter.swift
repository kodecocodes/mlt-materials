import Foundation
import QuartzCore

public class FPSCounter {
  private(set) public var fps: Double = 0

  var frames = 0
  var startTime: CFTimeInterval = 0

  public func start() {
    frames = 0
    startTime = CACurrentMediaTime()
  }

  public func frameCompleted() {
    frames += 1
    let now = CACurrentMediaTime()
    let elapsed = now - startTime
    if elapsed >= 0.01 {
      fps = Double(frames) / elapsed
      if elapsed >= 1 {
        frames = 0
        startTime = now
      }
    }
  }
}
