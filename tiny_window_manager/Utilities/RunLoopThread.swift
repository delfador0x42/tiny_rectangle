//
//  RunLoopThread.swift
//  tiny_window_manager
//
//  A custom Thread subclass that creates and manages its own RunLoop.
//
//  WHAT IS A RUNLOOP?
//  A RunLoop is an event-processing loop that keeps a thread alive and responsive.
//  Without a RunLoop, a thread would execute its code once and then terminate.
//  With a RunLoop, a thread can:
//    - Wait for events (keyboard, mouse, timers, etc.)
//    - Process those events when they arrive
//    - Go back to waiting (efficiently, without burning CPU)
//
//  Think of it like a receptionist who waits for phone calls, handles them,
//  then goes back to waiting - rather than constantly checking the phone.
//
//  WHY CREATE A DEDICATED RUNLOOP THREAD?
//  The main thread has its own RunLoop for handling UI events. But sometimes
//  we need to process events (like CGEvent taps) on a separate thread to:
//    1. Avoid blocking the UI
//    2. Get higher priority for time-sensitive operations
//    3. Keep event processing isolated from UI work
//
//  THE SYNCHRONIZATION CHALLENGE:
//  When you start a new thread, there's a race condition:
//    - The parent thread continues immediately after calling start()
//    - The new thread takes time to initialize its RunLoop
//    - If the parent tries to use the RunLoop before it's ready = crash!
//
//  We solve this with a SEMAPHORE - a synchronization primitive that makes
//  the parent thread WAIT until the child thread signals "I'm ready!".
//
//  TIMELINE OF EVENTS:
//    1. Parent calls start()
//    2. Parent waits on semaphore (blocks here...)
//    3. Child thread begins, creates RunLoop
//    4. Child signals semaphore ("I'm ready!")
//    5. Parent unblocks, can now safely access the RunLoop
//    6. Child enters its event loop, processing events forever
//

import Foundation

// MARK: - RunLoopThread

/// A Thread subclass that creates and exposes its own RunLoop for event processing.
///
/// Use this when you need a dedicated thread with its own event loop, such as
/// for processing CGEvent taps or other asynchronous event sources.
///
/// Example usage:
/// ```
/// // Create a high-priority thread for event processing
/// let eventThread = RunLoopThread(
///     mode: .default,
///     qualityOfService: .userInteractive,
///     start: true
/// )
///
/// // Now you can add event sources to its RunLoop
/// eventThread.runLoop?.add(myEventTap, forMode: .default)
/// ```
///
class RunLoopThread: Thread {

    // MARK: - Properties

    /// A semaphore used to synchronize thread startup.
    ///
    /// Initial value of 0 means wait() will block until signal() is called.
    /// This ensures the parent thread waits for the RunLoop to be ready.
    ///
    private let startSemaphore = DispatchSemaphore(value: 0)

    /// The RunLoop mode this thread will run in.
    ///
    /// Common modes:
    ///   - .default: Normal event processing
    ///   - .common: A pseudo-mode that includes multiple real modes
    ///
    private let mode: RunLoop.Mode

    /// The RunLoop created by this thread.
    ///
    /// This is nil until the thread starts and creates its RunLoop.
    /// After start() returns, this is guaranteed to be non-nil.
    ///
    /// Note: `private(set)` means external code can read this but not set it.
    ///
    private(set) var runLoop: RunLoop?

    // MARK: - Initialization

    /// Creates a new RunLoop thread.
    ///
    /// - Parameters:
    ///   - mode: The RunLoop mode to run in (e.g., `.default`).
    ///   - qualityOfService: Optional priority level for the thread.
    ///     Use `.userInteractive` for time-sensitive event processing.
    ///   - start: If true, starts the thread immediately. If false, you must
    ///     call start() yourself later.
    ///
    init(mode: RunLoop.Mode, qualityOfService: QualityOfService? = nil, start shouldStart: Bool = false) {
        self.mode = mode
        super.init()

        // Set the thread's priority if specified
        if let qualityOfService = qualityOfService {
            self.qualityOfService = qualityOfService
        }

        // Optionally start the thread immediately
        if shouldStart {
            self.start()
        }
    }

    // MARK: - Thread Lifecycle

    /// Starts the thread and WAITS until its RunLoop is ready.
    ///
    /// Unlike a normal Thread's start(), this method blocks until the new
    /// thread has initialized its RunLoop. This ensures that when start()
    /// returns, you can safely access the `runLoop` property.
    ///
    override func start() {
        // Start the thread (this calls main() on the new thread)
        super.start()

        // Block here until the child thread signals it's ready
        // This is the key synchronization point!
        startSemaphore.wait()
    }

    /// The main entry point for the thread - runs the event loop.
    ///
    /// This method:
    ///   1. Creates the RunLoop for this thread
    ///   2. Signals the parent that we're ready
    ///   3. Runs the event loop forever (until cancelled)
    ///
    /// Note: This is called automatically by the system when the thread starts.
    /// You should never call this directly.
    ///
    override func main() {
        // STEP 1: Create/capture the RunLoop for this thread
        //
        // Each thread has exactly one RunLoop, created lazily.
        // RunLoop.current gives us this thread's RunLoop.
        runLoop = RunLoop.current

        // STEP 2: Signal the parent thread that we're ready
        //
        // The parent is blocked in start(), waiting for this signal.
        // After this, the parent knows runLoop is safe to access.
        startSemaphore.signal()

        // STEP 3: Run the event loop forever
        //
        // This loop processes events until the thread is cancelled.
        // isCancelled becomes true when someone calls cancel() on this thread.
        while !isCancelled {

            // Try to run the RunLoop for one iteration
            //
            // run(mode:before:) processes events until:
            //   - An event is processed (returns true)
            //   - The timeout is reached (returns false)
            //   - There are no input sources (returns false)
            //
            // We use .distantFuture as the timeout so it waits indefinitely.
            let didProcessEvent = runLoop!.run(mode: mode, before: .distantFuture)

            if !didProcessEvent {
                // No input sources are attached yet, so RunLoop returned immediately.
                // Sleep briefly to avoid spinning the CPU at 100%.
                // Once input sources are added, this branch won't be taken.
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
}
