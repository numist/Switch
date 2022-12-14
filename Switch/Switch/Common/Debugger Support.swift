import Darwin
import Foundation

func amIBeingDebugged() -> Bool {
  var info = kinfo_proc()
  var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
  var size = MemoryLayout<kinfo_proc>.stride
  let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
  assert(junk == 0, "sysctl failed")
  return (info.kp_proc.p_flag & P_TRACED) != 0
}

func stopwatch<T>(_ title: String, threshold: Double, _ closure: () -> T) -> T {
  let start = Date()
  let result = closure()
  let elapsed = -start.timeIntervalSinceNow
  if elapsed > threshold {
    print("⏱: \(title) took \(elapsed) seconds")
  }
  return result
}
