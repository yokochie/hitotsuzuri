import SwiftUI
import AppKit

// 標準OutlineViewだけが行フォーカス/複数選択/左右キーを受け持つ。
// 保存や対象アルバムの判断は既存Workflowへ返す。
public struct NativeFolderBrowser:NSViewRepresentable {
    public let folders:[LibraryFolder]
    public let selection:Set<String>
    @Binding public var expanded:Set<String>
    public let frozen:Bool
    public let focusRequest:Int
    public let focusID:String?
    public let onSelection:(Set<String>)->Void
    public let onFocus:(String)->Void
    public func makeCoordinator()->Coordinator {Coordinator(self)}
    public func makeNSView(context:Context)->NSScrollView {
        let scroll=NSScrollView(),outline=FolderOutlineView()
        let column=NSTableColumn(identifier:.init("folder")); column.title="フォルダ"; column.width=220
        outline.addTableColumn(column); outline.outlineTableColumn=column; outline.headerView=nil
        outline.allowsMultipleSelection=true; outline.allowsEmptySelection=true; outline.rowHeight=25
        outline.autoresizingMask=[.width]; outline.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        outline.delegate=context.coordinator; outline.dataSource=context.coordinator
        outline.onWindow={ [weak coordinator=context.coordinator] in coordinator?.restoreRequestedFocus() }
        outline.onTabEntry={ [weak coordinator=context.coordinator] in coordinator?.selectFirstForTabEntry() ?? false }
        outline.setAccessibilityLabel("フォルダ"); outline.setAccessibilityIdentifier("folder-list")
        scroll.documentView=outline; scroll.hasVerticalScroller=true
        context.coordinator.outline=outline; context.coordinator.update(self)
        return scroll
    }
    public func updateNSView(_ view:NSScrollView,context:Context) {context.coordinator.update(self)}
    private final class FolderOutlineView:NSOutlineView {
        var onWindow:(()->Void)?
        var onTabEntry:(()->Bool)?
        override func viewDidMoveToWindow() {super.viewDidMoveToWindow(); if window != nil {onWindow?()}}
        override func becomeFirstResponder()->Bool {
            let accepted=super.becomeFirstResponder()
            if accepted,let event=NSApp.currentEvent,event.type == .keyDown,event.keyCode==48,
               event.modifierFlags.intersection([.command,.control,.option]).isEmpty { _=onTabEntry?() }
            return accepted
        }
        override func keyDown(with event:NSEvent) {
            // 起動時からこの一覧がfirstResponderでも、初回Tabまでは未選択を保つ。
            if event.keyCode==48,event.modifierFlags.intersection([.command,.control,.option]).isEmpty,onTabEntry?()==true {return}
            super.keyDown(with:event)
        }
    }
    @MainActor public final class Coordinator:NSObject,NSOutlineViewDataSource,NSOutlineViewDelegate {
        private final class Node:NSObject {
            let folder:LibraryFolder
            var children=[Node]()
            init(_ folder:LibraryFolder) {self.folder=folder}
        }
        private var parent:NativeFolderBrowser
        fileprivate weak var outline:NSOutlineView?
        private var folders=[LibraryFolder](),roots=[Node](),nodes=[String:Node]()
        private var isUpdating=false,isExpanding=false
        private var pending:Set<String>?
        private var lastFocusRequest=0
        init(_ parent:NativeFolderBrowser) {self.parent=parent}
        fileprivate func update(_ value:NativeFolderBrowser) {
            parent=value
            guard let outline else {return}
            isUpdating=true
            defer {isUpdating=false}
            if folders != value.folders {
                folders=value.folders; rebuild(); outline.reloadData()
            }
            for node in nodes.values {
                if value.expanded.contains(node.folder.id) {outline.expandItem(node)}
                else {outline.collapseItem(node)}
            }
            if pending==value.selection {pending=nil}
            // 古い非同期反映で、直後のCommand追加/解除を巻き戻さない。
            if pending==nil {
                let rows=IndexSet((0..<outline.numberOfRows).filter {row in
                    (outline.item(atRow:row) as? Node).map {value.selection.contains($0.folder.id)} ?? false
                })
                if outline.selectedRowIndexes != rows {outline.selectRowIndexes(rows,byExtendingSelection:false)}
            }
            restoreRequestedFocus()
        }
        fileprivate func restoreRequestedFocus() {
            guard parent.focusRequest != lastFocusRequest,let outline,let window=outline.window else {return}
            lastFocusRequest=parent.focusRequest
            if let id=parent.focusID,let node=nodes[id] {let row=outline.row(forItem:node); if row>=0 {outline.scrollRowToVisible(row)}}
            window.makeFirstResponder(outline)
        }
        fileprivate func selectFirstForTabEntry()->Bool {
            guard !parent.frozen,parent.selection.isEmpty,pending?.isEmpty != false,
                  let outline,outline.selectedRowIndexes.isEmpty,outline.numberOfRows>0,
                  let node=outline.item(atRow:0) as? Node else {return false}
            let updating=isUpdating; isUpdating=true
            outline.selectRowIndexes(IndexSet(integer:0),byExtendingSelection:false)
            isUpdating=updating
            pending=[node.folder.id]; parent.onSelection([node.folder.id]); parent.onFocus(node.folder.id)
            return true
        }
        private func rebuild() {
            nodes=Dictionary(folders.map {($0.id,Node($0))},uniquingKeysWith:{first,_ in first})
            let childIDs=Set(folders.flatMap(\.children)); var used=Set<String>()
            func build(_ node:Node) {
                guard used.insert(node.folder.id).inserted else {return}
                node.children=node.folder.children.compactMap {id in guard !used.contains(id),let child=nodes[id] else {return nil}; build(child); return child}
            }
            roots=folders.filter {!childIDs.contains($0.id)}.compactMap {nodes[$0.id]}
            for root in roots {build(root)}
            for folder in folders where !used.contains(folder.id) {if let node=nodes[folder.id] {roots.append(node); build(node)}}
        }
        public func outlineView(_ outlineView:NSOutlineView,numberOfChildrenOfItem item:Any?)->Int {(item as? Node)?.children.count ?? roots.count}
        public func outlineView(_ outlineView:NSOutlineView,child index:Int,ofItem item:Any?)->Any {(item as? Node)?.children[index] ?? roots[index]}
        public func outlineView(_ outlineView:NSOutlineView,isItemExpandable item:Any)->Bool {!((item as? Node)?.children.isEmpty ?? true)}
        public func outlineView(_ outlineView:NSOutlineView,viewFor tableColumn:NSTableColumn?,item:Any)->NSView? {
            guard let node=item as? Node else {return nil}
            let cell=NSTableCellView(frame:NSRect(x:0,y:0,width:tableColumn?.width ?? outlineView.bounds.width,height:25))
            let label=NSTextField(labelWithString:node.folder.title.isEmpty ? "名称なし" : node.folder.title)
            label.lineBreakMode = .byTruncatingTail; label.toolTip=label.stringValue
            label.frame=NSRect(x:0,y:2,width:max(1,cell.bounds.width-4),height:21); label.autoresizingMask=[.width]
            cell.textField=label; cell.addSubview(label); return cell
        }
        public func selectionShouldChange(in outlineView:NSOutlineView)->Bool {!parent.frozen}
        public func outlineView(_ outlineView:NSOutlineView,shouldExpandItem item:Any)->Bool {!parent.frozen}
        public func outlineView(_ outlineView:NSOutlineView,shouldCollapseItem item:Any)->Bool {!parent.frozen}
        public func outlineViewSelectionDidChange(_ notification:Notification) {
            guard !isUpdating,!isExpanding,!parent.frozen,let outline else {return}
            let ids=Set(outline.selectedRowIndexes.compactMap {(outline.item(atRow:$0) as? Node)?.folder.id})
            pending=ids; parent.onSelection(ids)
            if let node=outline.item(atRow:outline.selectedRow) as? Node {parent.onFocus(node.folder.id)}
        }
        public func outlineViewItemWillExpand(_ notification:Notification) {isExpanding=true}
        public func outlineViewItemWillCollapse(_ notification:Notification) {isExpanding=true}
        public func outlineViewItemDidExpand(_ notification:Notification) {expansion(notification,true)}
        public func outlineViewItemDidCollapse(_ notification:Notification) {expansion(notification,false)}
        private func expansion(_ notification:Notification,_ expanded:Bool) {
            isExpanding=false
            guard !isUpdating,let node=notification.userInfo?["NSObject"] as? Node else {return}
            if expanded {parent.expanded.insert(node.folder.id)} else {parent.expanded.remove(node.folder.id)}
        }
    }
}
