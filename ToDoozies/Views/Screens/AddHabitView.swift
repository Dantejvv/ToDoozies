//
//  AddHabitView.swift
//  ToDoozies
//
//  Created by Dante Vercelli on 9/16/25.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: AddHabitViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                AddHabitFormView(viewModel: viewModel)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if viewModel == nil, let container = diContainer {
                viewModel = container.makeAddHabitViewModel()
            }
        }
    }
}

struct AddHabitFormView: View {
    @Bindable var viewModel: AddHabitViewModel

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                categorySection
                targetSection

                if !viewModel.validationErrors.isEmpty {
                    validationErrorsSection
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Save") {
                        _Concurrency.Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $viewModel.showingCategoryPicker) {
                CategoryPickerSheet(
                    selectedCategory: viewModel.selectedCategory,
                    categories: viewModel.availableCategories,
                    onSelection: { category in
                        viewModel.selectCategory(category)
                    }
                )
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section("Habit Details") {
            TextField("Habit name", text: $viewModel.title)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.title) { _, _ in
                    viewModel.validateTitle()
                }
                .accessibilityLabel("Habit name")

            TextField("Description (optional)", text: $viewModel.habitDescription, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .onChange(of: viewModel.habitDescription) { _, _ in
                    viewModel.validateDescription()
                }
                .accessibilityLabel("Habit description")
        }
    }

    private var categorySection: some View {
        Section("Organization") {
            Button(action: {
                viewModel.showCategoryPicker()
            }) {
                HStack {
                    Text("Category")
                        .foregroundColor(.primary)

                    Spacer()

                    if let category = viewModel.selectedCategory {
                        CategoryBadge(category: category, size: .small)
                    } else {
                        Text("None")
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Category")
            .accessibilityValue(viewModel.selectedCategory?.name ?? "None selected")
            .accessibilityHint("Double tap to select a category")
        }
    }

    private var targetSection: some View {
        Section("Goal") {
            HStack {
                Text("Target completions per period")
                    .foregroundColor(.primary)

                Spacer()

                Stepper(
                    value: $viewModel.targetCompletionsPerPeriod,
                    in: 1...7
                ) {
                    Text("\(viewModel.targetCompletionsPerPeriod)")
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                .onChange(of: viewModel.targetCompletionsPerPeriod) { _, _ in
                    viewModel.validateTargetCompletions()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Target completions per period")
            .accessibilityValue("\(viewModel.targetCompletionsPerPeriod)")

            Text("This helps track your habit completion goals. Most daily habits should be set to 1.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var validationErrorsSection: some View {
        Section {
            ForEach(viewModel.validationErrors, id: \.localizedDescription) { error in
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        } header: {
            Text("Please fix the following issues:")
                .foregroundColor(.red)
        }
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {
    let selectedCategory: Category?
    let categories: [Category]
    let onSelection: (Category?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        onSelection(nil)
                        dismiss()
                    }) {
                        HStack {
                            Text("No Category")
                                .foregroundColor(.primary)

                            Spacer()

                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }

                if !categories.isEmpty {
                    Section("Categories") {
                        ForEach(categories, id: \.id) { category in
                            Button(action: {
                                onSelection(category)
                                dismiss()
                            }) {
                                HStack {
                                    CategoryBadge(category: category)

                                    Spacer()

                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddHabitView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}