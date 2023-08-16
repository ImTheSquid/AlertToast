//
//  AlertToastRoot.swift
//  
//
//  Created by Jack Hogan on 8/6/23.
//

import SwiftUI

internal struct AlertToastInfo: Equatable {
    static func == (lhs: AlertToastInfo, rhs: AlertToastInfo) -> Bool {
        lhs.stableId.hashValue == rhs.stableId.hashValue && lhs.view.id == rhs.view.id
    }
    
    let view: EquatableViewEraser
    let stableId: any Hashable
    let mode: AlertToast.DisplayMode
    let duration: Double
    let tapToDismiss: Bool
    let onTap: (() -> Void)?
    let completion: (() -> Void)?
    let offsetY: CGFloat
}

internal struct PresentedAlertToastView: EnvironmentKey {
    static var defaultValue: Binding<AlertToastInfo?> = .constant(nil)
}

extension EnvironmentValues {
    internal var presentedAlertToastView: Binding<AlertToastInfo?> {
        get { self[PresentedAlertToastView.self] }
        set { self[PresentedAlertToastView.self] = newValue }
    }
}

internal struct StableIdProvider<OtherContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let otherContent: () -> OtherContent
    let mode: AlertToast.DisplayMode
    let duration: Double
    let tapToDismiss: Bool
    let onTap: (() -> Void)?
    let completion: (() -> Void)?
    let offsetY: CGFloat
    @State private var stableId = UUID()
    @Environment(\.presentedAlertToastView) private var presented
    
    /// https://zachsim.one/blog/2022/6/16/multiple-preference-keys-on-the-same-view-in-swiftui
    func body(content: Content) -> some View {
        content/*.background(Rectangle().hidden().preference(key: AlertToastView.self, value: AlertToastInfo(view: EquatableViewEraser(view: otherContent()), stableId: stableId, mode: mode)))*/
            .valueChanged(value: isPresented) { isPresented in
                if isPresented {
                    presented.wrappedValue = AlertToastInfo(view: EquatableViewEraser(view: otherContent()), stableId: stableId, mode: mode, duration: duration, tapToDismiss: tapToDismiss, onTap: onTap, completion: completion, offsetY: offsetY)
                } else if presented.wrappedValue?.stableId.hashValue == stableId.hashValue {
                    presented.wrappedValue = nil
                }
            }
            .valueChanged(value: presented.wrappedValue == nil) { notPresented in
                if notPresented {
                    isPresented = false
                }
            }
            .valueChanged(value: presented.wrappedValue?.stableId.hashValue, onChange: { hv in
                if hv != stableId.hashValue {
                    isPresented = false
                }
            })
    }
}

internal struct EquatableViewEraser: Equatable {
    static func == (lhs: EquatableViewEraser, rhs: EquatableViewEraser) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID()
    let view: any View
}

internal struct AlertToastRoot: ViewModifier {
    let animation: Animation
    @State private var toastInfo: AlertToastInfo?
    @State private var dismissalTask: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            innerBody(content: content)
                .animation(animation, value: toastInfo)
        } else {
            innerBody(content: content)
                .animation(animation)
        }
    }
    
    func innerBody(content: Content) -> some View {
        ZStack {
            content
                .environment(\.presentedAlertToastView, $toastInfo)
                .zIndex(0)
            
            if let toastInfo = toastInfo {
                formatAlert(AnyView(toastInfo.view.view), withMode: toastInfo.mode)
                    .offset(y: toastInfo.offsetY)
                    .onTapGesture(perform: {
                        handleTap(withInfo: toastInfo)
                    })
                    .onDisappear(perform: {
                        handleOnDisappear(withInfo: toastInfo)
                    })
                    .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .valueChanged(value: toastInfo) { _ in
            if let toastInfo = toastInfo {
                handleOnAppear(withInfo: toastInfo)
            }
        }
    }
    
    @ViewBuilder private func formatAlert(_ alert: AnyView, withMode mode: AlertToast.DisplayMode) -> some View {
        switch mode {
        case .alert:
            alert
                .transition(AnyTransition.scale(scale: 0.8).combined(with: .opacity))
        case .hud:
            alert
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
        case .banner:
            alert
                .transition(mode == .banner(.slide) ? AnyTransition.slide.combined(with: .opacity) : AnyTransition.move(edge: .bottom))
        }
    }
    
    private func handleOnAppear(withInfo info: AlertToastInfo) {
        if let workItem = dismissalTask, !workItem.isCancelled {
            workItem.cancel()
        }
        
        guard info.duration > 0 else { return }
        
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000.0 * info.duration))
            if Task.isCancelled {
                return
            }
            
            toastInfo = nil
            dismissalTask = nil
        }
        
        dismissalTask = task    
    }
    
    private func handleTap(withInfo info: AlertToastInfo) {
        if let onTap = info.onTap {
            onTap()
        }
        
        if info.tapToDismiss {
            self.dismissalTask?.cancel()
            Task { @MainActor in
                toastInfo = nil
            }
        }
    }
    
    private func handleOnDisappear(withInfo info: AlertToastInfo) {
        if let completion = info.completion {
            completion()
        }
    }
}

extension View {
    public func alertToastRoot(usingAnimation animation: Animation = .spring()) -> some View {
        self.modifier(AlertToastRoot(animation: animation))
    }
}
