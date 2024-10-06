# Phonepad Client
## Overview
Phonepad Client is an iOS application designed to transform your iPhone into a versatile touchpad and control center for your Mac. This project aims to provide a seamless and intuitive interface for controlling various aspects of your Mac, including cursor movement, app switching, media controls, and more.

## Table of Contents

1. System Design
2. Key Features
3. Technology Stack
4. Getting Started
5. Architecture
6. UI Components
7. Bluetooth Communication

## System Design
The Phonepad Client is designed with a modular architecture, focusing on:

- Bluetooth Low Energy (BLE) Communication: Ensures efficient, low-latency data transfer between the iOS device and the Mac.
- Reactive UI: Utilizes SwiftUI for a responsive and adaptive user interface.
- State Management: Implements the Observable Object pattern for managing application state.

## Key Features

- App switching interface
- Media controls (play/pause, next/previous track)
- Volume and brightness adjustment
- Virtual keyboard for text input
- Spaces navigation
- Scrolling interface (vertical and horizontal)

## Technology Stack

- Language: Swift 5.5+
- UI Framework: SwiftUI
- Bluetooth: Core Bluetooth framework
- Haptics: Core Haptics framework
- Minimum iOS Version: iOS 15.0 (subject to change based on requirements)

## Getting Started

Clone the repository:
`git clone https://github.com/your-organization/phonepad-client.git`

Open the Xcode project file `Phonepad client.xcodeproj`.
Ensure you have the latest version of Xcode installed (Xcode 13+).
Build and run the project on your iOS device.

Note: To test the full functionality, you'll need to have the Phonepad Server application running on your Mac.

## Architecture
The application follows a modular architecture with the following key components:

- ContentView: The main view orchestrating all sub-components.
- BLEManager: Manages Bluetooth communication with the Mac.
- TrackpadView: Handles touch input for cursor control.
- ScrollBarView: Manages scrolling interactions.
- AppsView: Displays and manages app switching.
- KeyboardView: Handles text input.
- Various Control Views: (SpacesView, MediaView, BrightnessView, VolumeView) for specific control functions.

## UI Components
The user interface is built using SwiftUI and consists of several custom components:

- TrackpadView: A customizable touchpad area.
- ScrollBarView: Vertical and horizontal scroll bars.
- AppsView: A grid of running applications.
- ControlToggleButtons: For accessing different control overlays.
- Overlay Views: For spaces, media, brightness, and volume controls.

Each component is designed to be reusable and easily customizable.

## Bluetooth Communication
Bluetooth communication is handled by the BLEManager class, which implements the following key features:

- Device discovery and connection
- Service and characteristic management
- Data encoding and decoding
- Chunked data transfer for larger payloads (e.g., app icons)
- Reliable data transmission with acknowledgments

Developers should familiarize themselves with the Core Bluetooth framework and the specific service and characteristic UUIDs used in the project.
