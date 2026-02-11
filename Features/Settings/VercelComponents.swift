import SwiftUI

// MARK: - VercelToggleStyle

struct VercelToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
      Spacer()
      toggleTrack(isOn: configuration.isOn)
        .onTapGesture { configuration.isOn.toggle() }
    }
  }

  private func toggleTrack(isOn: Bool) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 11)
        .fill(isOn ? Geist.Colors.gray1000 : Geist.Colors.gray200)
        .frame(width: 40, height: 22)
      Circle()
        .fill(Geist.Colors.backgroundPrimary)
        .frame(width: 18, height: 18)
        .offset(x: isOn ? 9 : -9)
    }
    .animation(.easeInOut(duration: 0.15), value: isOn)
  }
}

// MARK: - VercelSegmentedControl

struct VercelSegmentedControl<T: Hashable>: View {
  @Binding var selection: T
  let options: [(value: T, label: String)]

  var body: some View {
    HStack(spacing: 0) {
      ForEach(options, id: \.value) { option in
        Button {
          selection = option.value
        } label: {
          Text(option.label)
            .font(Geist.Typography.Settings.button)
            .foregroundColor(selection == option.value ? Geist.Colors.backgroundPrimary : Geist.Colors.gray700)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
              selection == option.value
                ? RoundedRectangle(cornerRadius: 4).fill(Geist.Colors.gray1000)
                : RoundedRectangle(cornerRadius: 4).fill(Color.clear)
            )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(2)
    .background(Geist.Colors.gray100)
    .clipShape(RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius))
    .overlay(
      RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
        .stroke(Geist.Colors.border, lineWidth: 1)
    )
  }
}

// MARK: - VercelSecondaryButtonStyle

struct VercelSecondaryButtonStyle: ButtonStyle {
  @State private var isHovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Geist.Typography.Settings.button)
      .foregroundColor(Geist.Colors.gray1000)
      .frame(height: 32)
      .padding(.horizontal, 16)
      .background(
        RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
          .fill(isHovered ? Geist.Colors.gray200 : Color.clear)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
          .stroke(Geist.Colors.border, lineWidth: 1)
      )
      .onHover { isHovered = $0 }
  }
}

// MARK: - VercelTextFieldModifier

struct VercelTextFieldModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(Geist.Typography.Settings.inputText)
      .foregroundColor(Geist.Colors.gray1000)
      .padding(.horizontal, 10)
      .frame(height: Geist.Layout.settingsInputHeight)
      .background(Geist.Colors.gray100)
      .clipShape(RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius))
      .overlay(
        RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
          .stroke(Geist.Colors.border, lineWidth: 1)
      )
  }
}

extension View {
  func vercelTextField() -> some View {
    modifier(VercelTextFieldModifier())
  }
}

// MARK: - VercelIconButton

struct VercelIconButton: View {
  let systemName: String
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Image(systemName: systemName)
        .foregroundColor(Geist.Colors.gray800)
        .frame(width: Geist.Layout.settingsIconButtonSize,
               height: Geist.Layout.settingsIconButtonSize)
        .background(
          RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
            .fill(isHovered ? Geist.Colors.gray100 : Color.clear)
        )
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}

// MARK: - VercelSectionHeader

struct VercelSectionHeader: View {
  let title: String

  var body: some View {
    Text(title)
      .font(Geist.Typography.Settings.sectionHeader)
      .foregroundColor(Geist.Colors.gray800)
      .textCase(.uppercase)
      .tracking(0.5)
  }
}

// MARK: - VercelDropdown

struct VercelDropdown<T: Hashable>: View {
  let label: String
  @Binding var selection: T
  let options: [(value: T, label: String)]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(Geist.Typography.Settings.fieldLabel)
        .foregroundColor(Geist.Colors.gray1000)

      Menu {
        ForEach(options, id: \.value) { option in
          Button(option.label) {
            selection = option.value
          }
        }
      } label: {
        HStack {
          Text(selectedLabel)
            .font(Geist.Typography.Settings.inputText)
            .foregroundColor(Geist.Colors.gray1000)
          Spacer()
          Image(systemName: "chevron.down")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Geist.Colors.gray800)
        }
        .padding(.horizontal, 12)
        .frame(height: Geist.Layout.settingsInputHeight)
        .background(Geist.Colors.gray100)
        .clipShape(RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius))
        .overlay(
          RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
            .stroke(Geist.Colors.border, lineWidth: 1)
        )
      }
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
    }
  }

  private var selectedLabel: String {
    options.first(where: { $0.value == selection })?.label ?? ""
  }
}

// MARK: - VercelCheckmarkRow

struct VercelCheckmarkRow: View {
  let name: String
  @Binding var isSelected: Bool

  var body: some View {
    Button {
      isSelected.toggle()
    } label: {
      HStack {
        Text(name)
          .font(Geist.Typography.Settings.fieldLabel)
          .foregroundColor(Geist.Colors.gray1000)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Geist.Colors.gray1000)
        }
      }
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
