// Copyright 2019-2022 Spotify AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// A connectable adapter which imposes asynchronous dispatch blocks around calls to `accept`.
///
/// Creates `Connection`s that forward invocations to `accept` to a connection returned by the underlying connectable,
/// first switching to the provided `acceptQueue`. In other words, the real `accept` method will always be executed
/// asynchronously on the provided queue.
final class AsyncDispatchQueueConnectable<Input, Output>: Connectable {
    private let underlyingConnectable: AnyConnectable<Input, Output>
    private let acceptQueue: DispatchQueue

    init(
        _ underlyingConnectable: AnyConnectable<Input, Output>,
        acceptQueue: DispatchQueue
    ) {
        self.underlyingConnectable = underlyingConnectable
        self.acceptQueue = acceptQueue
    }

    convenience init<C: Connectable>(
        _ underlyingConnectable: C,
        acceptQueue: DispatchQueue
    ) where C.Input == Input, C.Output == Output {
        self.init(AnyConnectable(underlyingConnectable), acceptQueue: acceptQueue)
    }

    func connect(_ consumer: @escaping Consumer<Output>) -> Connection<Input> {
        // Synchronized values protect against state changes within the critical regions that are accessed on both the
        // loop queue and the accept queue. An optional consumer allows for clearing the reference when it is no longer
        // valid.
        let disposalStatus = Synchronized(value: false)
        let protectedConsumer = Synchronized<Consumer<Output>?>(value: consumer)

        let connection = underlyingConnectable.connect { value in
            protectedConsumer.read { consumer in
                guard let consumer = consumer else {
                    MobiusHooks.errorHandler("cannot consume value after dispose", #file, #line)
                }
                consumer(value)
            }
        }

        return Connection(
            acceptClosure: { [acceptQueue] input in
                acceptQueue.async {
                    // Prevents forwarding if the connection has since been disposed.
                    disposalStatus.read { disposed in
                        guard !disposed else { return }
                        connection.accept(input)
                    }
                }
            },
            disposeClosure: {
                guard disposalStatus.compareAndSwap(expected: false, with: true) else {
                    MobiusHooks.errorHandler("cannot dispose more than once", #file, #line)
                }

                connection.dispose()
                protectedConsumer.value = nil
            }
        )
    }
}
