# Axys

**Axys** is a **VisionOS** app designed to be used in combination with the [RhinoPlugin](https://github.com/Apollo-ARTE/RhinoPlugin).  
It allows users to view and interact with 3D models from Rhino in augmented reality, perform spatial calibration, and visualize the constraints of a robotic 3D printing environment.

---

## Purpose

Axys transforms your physical space into an interactive 3D environment synchronized with Rhino.  
You can see exported models, interact with them, and visualize the printing robot's workspace and the real-world lab environment.

---

## Installation

To install and run **Axys**:

1. Clone the repository:
   ```bash
   git clone https://github.com/Apollo-ARTE/Axys.git
   ```
2. Open the `.xcodeproj` or `.xcodeworkspace` file in **Xcode**.
3. Ensure you have a valid Apple Developer account and a device running **visionOS**.
4. Build and run the app on your **Apple Vision Pro** via Xcode.

---

## How It Works

1. Ensure both the Vision Pro and the computer with Rhino are connected to the **same Wi-Fi network**.
2. In Rhino, start the WebSocket server using the command `WebSocketStart`.
3. Launch the **Axys** app on the Vision Pro.
4. Enter the IP address displayed in Rhino console to connect.
5. Run the app’s guided **spatial calibration**.
5.1. Place the required calibration markers in the physical environment. These markers are used by the app to align the virtual and real spaces accurately. (See the included image for reference.)
6. Select an object in Rhino.
7. Press **Export** in Axys to view the model in AR.
7.1. After tapping **Export**, you can browse a dedicated section in the app to view the list of all exported models.
8. When moving an object from the headset, its position and rotation are updated in Rhino in real time. Other changes may not be synchronized instantly.

---

## Features

- View 3D models exported from Rhino
- Perform spatial calibration with the physical space
- Visualize the robotic printer's workspace
- See a full-scale virtual lab environment
- Interact with models and send updates back to Rhino

---

## Technologies Used

- **VisionOS**
- **SwiftUI**
- **RealityKit**
- **WebSocket**
- **USDZ / Model3D**

---

## Contributing

Contributions, bug reports, and feature suggestions are welcome!

1. Fork the repository
2. Create a branch:  
   ```bash
   git checkout -b feature-name
   ```
3. Make your changes and commit
4. Submit a Pull Request

---

## License

This project is licensed under the [GNU GPL v3.0](https://www.gnu.org/licenses/gpl-3.0.html).  
Derivative works must be released under the same license. See the `LICENSE` file for full details.

---

## Authors

Rhino Plugin by [Salvatore Flauto](https://github.com/XlSolver / https://www.linkedin.com/in/salvatore-flauto-71020b190/)
