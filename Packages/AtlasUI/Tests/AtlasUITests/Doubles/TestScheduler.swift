import Combine
import Foundation

/// A Combine scheduler whose clock moves only when `advance(by:)` moves it. Actions run on the
/// caller's thread, in time order.
final class TestScheduler: Scheduler {
  typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
  typealias SchedulerOptions = DispatchQueue.SchedulerOptions

  private struct ScheduledAction {
    let id: Int
    var date: SchedulerTimeType
    /// `nil` for an action that runs once.
    let interval: SchedulerTimeType.Stride?
    let run: () -> Void
  }

  private(set) var now = SchedulerTimeType(DispatchTime(uptimeNanoseconds: 1))
  let minimumTolerance: SchedulerTimeType.Stride = .zero
  private var actions: [ScheduledAction] = []
  private var lastID = 0

  /// Moves the clock forward by `stride`, running each action that comes due on the way.
  func advance(by stride: SchedulerTimeType.Stride) {
    let end = now.advanced(by: stride)
    while let index = indexOfNextAction(dueBy: end) {
      let action = actions[index]
      now = action.date
      if let interval = action.interval {
        actions[index].date = action.date.advanced(by: interval)
      } else {
        actions.remove(at: index)
      }
      action.run()
    }
    now = end
  }

  func schedule(options _: SchedulerOptions?, _ action: @escaping () -> Void) {
    enqueue(at: now, interval: nil, action)
  }

  func schedule(
    after date: SchedulerTimeType,
    tolerance _: SchedulerTimeType.Stride,
    options _: SchedulerOptions?,
    _ action: @escaping () -> Void
  ) {
    enqueue(at: date, interval: nil, action)
  }

  func schedule(
    after date: SchedulerTimeType,
    interval: SchedulerTimeType.Stride,
    tolerance _: SchedulerTimeType.Stride,
    options _: SchedulerOptions?,
    _ action: @escaping () -> Void
  ) -> any Cancellable {
    let id = enqueue(at: date, interval: interval, action)
    return AnyCancellable { [weak self] in
      self?.actions.removeAll { $0.id == id }
    }
  }

  @discardableResult
  private func enqueue(
    at date: SchedulerTimeType,
    interval: SchedulerTimeType.Stride?,
    _ run: @escaping () -> Void
  ) -> Int {
    lastID += 1
    actions.append(ScheduledAction(id: lastID, date: date, interval: interval, run: run))
    return lastID
  }

  /// The earliest action due by `end`; of those due at the same time, the first scheduled.
  private func indexOfNextAction(dueBy end: SchedulerTimeType) -> Int? {
    actions.indices
      .filter { actions[$0].date <= end }
      .min { (actions[$0].date, actions[$0].id) < (actions[$1].date, actions[$1].id) }
  }
}
