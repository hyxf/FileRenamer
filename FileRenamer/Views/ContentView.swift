//
//  ContentView.swift
//  FileRenamer
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileRenamerViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 350)
        } detail: {
            detailView
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.showSuccess, let message = viewModel.successMessage {
                Text(message)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white) // Fix: foregroundStyle -> foregroundColor
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.green) // Fix: .green.gradient -> Color.green
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4))
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7),
                        value: viewModel.showSuccess)
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary) // Fix
                Text("配置规则")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary) // Fix
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            RenameRuleView(rule: $viewModel.rule, onRuleChange: {
                viewModel.applyRule()
            })

            Spacer()
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var detailView: some View {
        VStack(spacing: 0) {
            FileListView(viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if !viewModel.files.isEmpty {
                    Button {
                        viewModel.toggleSelectAll()
                    } label: {
                        Label(
                            viewModel.isAllSelected ? "取消全选" : "全选",
                            systemImage: viewModel
                                .isAllSelected ? "checkmark.circle.fill" : "circle")
                    }
                    .help(viewModel.isAllSelected ? "取消全选" : "选择全部文件")

                    Divider()

                    Button {
                        viewModel.removeSelectedFiles()
                    } label: {
                        Label("移除选中", systemImage: "trash")
                    }
                    .disabled(viewModel.selectedFiles.isEmpty)

                    Button {
                        viewModel.clearAll()
                    } label: {
                        Label("清空列表", systemImage: "xmark.circle")
                    }

                    Divider()
                }

                Button {
                    Task {
                        await viewModel.executeRename()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("执行重命名")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                }
                .disabled(!viewModel.hasChanges || viewModel.isProcessing || viewModel.files
                    .isEmpty)
                .help("应用重命名更改")
            }
        }
    }
}
