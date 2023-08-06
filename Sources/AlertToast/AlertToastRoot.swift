//
//  AlertToastRoot.swift
//  
//
//  Created by Jack Hogan on 8/6/23.
//

import SwiftUI

internal struct AlertToastInfo {
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
    @State private var toastInfo: AlertToastInfo?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            innerBody(content: content)
            .animation(.spring(), value: toastInfo?.stableId.hashValue)
        } else {
            innerBody(content: content)
            .animation(.spring())
        }
    }
    
    func innerBody(content: Content) -> some View {
        ZStack {
            content
                .environment(\.presentedAlertToastView, $toastInfo)
            
            if let toastInfo = toastInfo {
                formatAlert(AnyView(toastInfo.view.view), withMode: toastInfo.mode)
                    .offset(y: toastInfo.offsetY)
                    .onTapGesture(perform: {
                        handleTap(withInfo: toastInfo)
                    })
                    .onDisappear(perform: {
                        handleOnDisappear(withInfo: toastInfo)
                    })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .valueChanged(value: toastInfo?.stableId.hashValue) { _ in
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
        if let workItem = workItem {
            workItem.cancel()
        }
        
        guard info.duration > 0 else { return }
        
        let task = DispatchWorkItem {
            withAnimation(Animation.spring()){
                toastInfo = nil
                workItem = nil
            }
        }
        
        workItem = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + info.duration, execute: task)
    }
    
    private func handleTap(withInfo info: AlertToastInfo) {
        if let onTap = info.onTap {
            onTap()
        }
        
        if info.tapToDismiss {
            withAnimation(Animation.spring()){
                self.workItem?.cancel()
                toastInfo = nil
                self.workItem = nil
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
    public func alertToastRoot() -> some View {
        self.modifier(AlertToastRoot())
    }
}
