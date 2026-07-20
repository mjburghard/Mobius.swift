// Copyright Spotify AB.
// SPDX-License-Identifier: Apache-2.0

import MobiusCore
import Nimble
import Quick

#if compiler(>=5.10)
private enum MainActorEffect: Equatable {
    case effect
}

private enum MainActorEvent: Equatable {
    case event
}

class MainActorEffectRouterDSLTests: QuickSpec {
    // swiftlint:disable:next function_body_length
    override class func spec() {
        it("Supports routing to an onMainActor side-effecting function") {
            guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) else {
                return
            }

            let performedEffects = Recorder<MainActorEffect>()
            var didDispatchEvents = false
            let parameterExtractor: (MainActorEffect) -> MainActorEffect? = { $0 == .effect ? .effect : nil }
            let dslHandler = EffectRouter<MainActorEffect, MainActorEvent>()
                .routeEffects(withParameters: parameterExtractor).onMainActor.to { effect in
                    performedEffects.append(effect)
                }
                .asConnectable
                .connect { _ in
                    didDispatchEvents = true
                }

            dslHandler.accept(.effect)
            expect(performedEffects.items).toEventually(equal([.effect]))
            expect(didDispatchEvents).to(beFalse())
        }

        it("Supports routing to and receiving events from an onMainActor effect handler") {
            guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) else {
                return
            }

            let performedEffects = Recorder<MainActorEffect>()
            let receivedEvents = Recorder<MainActorEvent>()
            let wasDisposed = Recorder<Bool>()
            let parameterExtractor: (MainActorEffect) -> MainActorEffect? = { $0 == .effect ? .effect : nil }
            let dslHandler = EffectRouter<MainActorEffect, MainActorEvent>()
                .routeEffects(withParameters: parameterExtractor).onMainActor.to { effect, callback in
                    performedEffects.append(effect)
                    callback.send(.event)
                    return AnonymousDisposable {
                        wasDisposed.append(true)
                    }
                }
                .asConnectable
                .connect { receivedEvents.append($0) }

            dslHandler.accept(.effect)
            expect(performedEffects.items).toEventually(equal([.effect]))
            expect(receivedEvents.items).toEventually(equal([.event]))

            dslHandler.dispose()
            expect(wasDisposed.items).toEventually(equal([true]))
        }

        it("Supports routing to an onMainActor event-returning function") {
            guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) else {
                return
            }

            let performedEffects = Recorder<MainActorEffect>()
            let receivedEvents = Recorder<MainActorEvent>()
            let parameterExtractor: (MainActorEffect) -> MainActorEffect? = { $0 == .effect ? .effect : nil }
            let dslHandler = EffectRouter<MainActorEffect, MainActorEvent>()
                .routeEffects(withParameters: parameterExtractor).onMainActor.toEvent { effect in
                    performedEffects.append(effect)
                    return .event
                }
                .asConnectable
                .connect { receivedEvents.append($0) }

            dslHandler.accept(.effect)
            expect(performedEffects.items).toEventually(equal([.effect]))
            expect(receivedEvents.items).toEventually(equal([.event]))
        }

        it("Supports routing to an onMainActor side-effecting function with no input parameters") {
            guard #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) else {
                return
            }

            let effectPerformedCount = Recorder<Int>()
            var didDispatchEvents = false
            let parameterExtractor: (MainActorEffect) -> Void? = { $0 == .effect ? () : nil }
            let dslHandler = EffectRouter<MainActorEffect, MainActorEvent>()
                .routeEffects(withParameters: parameterExtractor).onMainActor.to {
                    effectPerformedCount.append(1)
                }
                .asConnectable
                .connect { _ in
                    didDispatchEvents = true
                }

            dslHandler.accept(.effect)
            expect(effectPerformedCount.items).toEventually(equal([1]))
            expect(didDispatchEvents).to(beFalse())
        }
    }
}
#endif
