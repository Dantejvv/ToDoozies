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
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
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

// MARK: - CategoryPickerSheet Removed
// Now using unified CategoryPickerView component

// MARK: - Preview

#Preview {
    AddHabitView()
        .inject(DIContainer(modelContext: ModelContext.preview))
}