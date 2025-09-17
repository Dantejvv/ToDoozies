//
//  CategoryPickerView.swift
//  ToDoozies
//
//  Created by Claude Code on 9/17/25.
//

import SwiftUI

// MARK: - Category Picker View

struct CategoryPickerView: View {
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var diContainer

    @State private var categories: [Category] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading categories...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Categories",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else {
                    categoryList
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search categories...")
            .task {
                await loadCategories()
            }
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        List {
            // "No Category" option
            noCategorySection

            // Available categories
            if !filteredCategories.isEmpty {
                categoriesSection
            } else if !searchText.isEmpty {
                emptySearchSection
            }
        }
    }

    private var noCategorySection: some View {
        Section {
            Button(action: {
                selectedCategory = nil
                dismiss()
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Category")
                            .foregroundColor(.primary)
                            .font(.body)

                        Text("Task will not be categorized")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    if selectedCategory == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("No Category")
            .accessibilityHint("Task will not be categorized")
            .accessibilityAddTraits(selectedCategory == nil ? .isSelected : [])
        }
    }

    private var categoriesSection: some View {
        Section("Categories") {
            ForEach(filteredCategories, id: \.id) { category in
                CategoryRow(
                    category: category,
                    isSelected: selectedCategory?.id == category.id,
                    onSelection: {
                        selectedCategory = category
                        dismiss()
                    }
                )
            }
        }
    }

    private var emptySearchSection: some View {
        Section {
            ContentUnavailableView.search(text: searchText)
        }
    }

    // MARK: - Computed Properties

    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories.sorted { $0.order < $1.order }
        } else {
            return categories
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.order < $1.order }
        }
    }

    // MARK: - Data Loading

    private func loadCategories() async {
        guard let container = diContainer else {
            errorMessage = "Unable to access app services"
            isLoading = false
            return
        }

        do {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            try await container.categoryService.refreshCategories()

            await MainActor.run {
                categories = container.appState.categories
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load categories: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    let category: Category
    let isSelected: Bool
    let onSelection: () -> Void

    var body: some View {
        Button(action: onSelection) {
            HStack {
                CategoryBadge(category: category, showIcon: true, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .foregroundColor(.primary)
                        .font(.body)

                    if category.taskCount > 0 {
                        Text("\(category.taskCount) tasks")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category: \(category.name)")
        .accessibilityHint(category.taskCount > 0 ? "Contains \(category.taskCount) tasks" : "Empty category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategoryPickerView(selectedCategory: .constant(nil))
    }
    .inject(DIContainer(modelContext: .preview))
}

#Preview("With Selected Category") {
    let sampleCategory = Category(name: "Work", color: "#FF9500", icon: "briefcase.fill", order: 1)

    return NavigationStack {
        CategoryPickerView(selectedCategory: .constant(sampleCategory))
    }
    .inject(DIContainer(modelContext: .preview))
}