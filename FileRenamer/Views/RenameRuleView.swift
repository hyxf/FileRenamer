//
//  RenameRuleView.swift
//  FileRenamer
//

import SwiftUI

struct RenameRuleView: View {
    @Binding var rule: RenameRule
    let onRuleChange: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 规则类型选择卡片
                VStack(alignment: .leading, spacing: 10) {
                    Label("选择操作", systemImage: "wand.and.stars")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    // 原生 Picker
                    Picker("", selection: $rule.type) {
                        ForEach(RenameRuleType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .onChange(of: rule.type) { _ in
                        onRuleChange()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                )
                
                // 参数设置卡片
                VStack(alignment: .leading, spacing: 12) {
                    Label("参数设置", systemImage: "slider.horizontal.3")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    ruleContent
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                )
                
                // 扩展名设置
                VStack(alignment: .leading) {
                    Toggle("应用于扩展名", isOn: $rule.applyToExtension)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .font(.system(.subheadline, design: .rounded))
                        .onChange(of: rule.applyToExtension) { _ in
                            onRuleChange()
                        }
                    
                    Text("开启后将同时修改文件后缀名")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
    
    @ViewBuilder
    private var ruleContent: some View {
        switch rule.type {
        case .replace:
            replaceView
        case .prefix:
            prefixView
        case .suffix:
            suffixView
        case .sequence:
            sequenceView
        case .caseChange:
            caseChangeView
        case .removeText:
            removeTextView
        case .insertText:
            insertTextView
        }
    }
    
    // MARK: - Rule Subviews
    
    private var replaceView: some View {
        Group {
            VStack(alignment: .leading, spacing: 6) {
                Text("查找内容").font(.caption).foregroundColor(.secondary)
                TextField("输入要查找的文本", text: $rule.findText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rule.findText) { _ in onRuleChange() }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("替换为").font(.caption).foregroundColor(.secondary)
                TextField("输入替换后的文本", text: $rule.replaceText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rule.replaceText) { _ in onRuleChange() }
            }
        }
    }
    
    private var prefixView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("前缀文本").font(.caption).foregroundColor(.secondary)
            TextField("输入要添加的前缀", text: $rule.prefixText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: rule.prefixText) { _ in onRuleChange() }
        }
    }
    
    private var suffixView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("后缀文本").font(.caption).foregroundColor(.secondary)
            TextField("输入要添加的后缀", text: $rule.suffixText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: rule.suffixText) { _ in onRuleChange() }
        }
    }
    
    private var sequenceView: some View {
        Group {
            VStack(alignment: .leading, spacing: 6) {
                Text("前缀 (可选)").font(.caption).foregroundColor(.secondary)
                TextField("输入前缀", text: $rule.prefixText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rule.prefixText) { _ in onRuleChange() }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("分隔符").font(.caption).foregroundColor(.secondary)
                TextField("_", text: $rule.separator)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rule.separator) { _ in onRuleChange() }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("起始: \(rule.startNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper("", value: $rule.startNumber, in: 0...9999)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("位数: \(rule.digits)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper("", value: $rule.digits, in: 1...6)
                        .labelsHidden()
                }
            }
            .onChange(of: rule.startNumber) { _ in onRuleChange() }
            .onChange(of: rule.digits) { _ in onRuleChange() }
        }
    }
    
    private var caseChangeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择转换模式")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $rule.caseType) {
                ForEach(CaseType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .onChange(of: rule.caseType) { _ in
                onRuleChange()
            }
        }
    }
    
    private var removeTextView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("删除内容").font(.caption).foregroundColor(.secondary)
            TextField("输入要删除的文本", text: $rule.removeText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: rule.removeText) { _ in onRuleChange() }
        }
    }
    
    private var insertTextView: some View {
        Group {
            VStack(alignment: .leading, spacing: 6) {
                Text("插入内容").font(.caption).foregroundColor(.secondary)
                TextField("输入要插入的文本", text: $rule.insertText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rule.insertText) { _ in onRuleChange() }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("插入位置 (索引): \(rule.insertPosition)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("", value: $rule.insertPosition, in: 0...100)
                    .labelsHidden()
                    .onChange(of: rule.insertPosition) { _ in
                        onRuleChange()
                    }
            }
        }
    }
}
