# RehabTrack Workflow – Gross Movement Detector

This is part of the [RehabTrack Workflow](https://github.com/lrlcardoso/RehabTrack_Workflow): a modular pipeline for **tracking and analysing physiotherapy movements**, using video and IMU data.  
This module detects **gross arm movements** from processed video pose data, generating binary “use” signals and summary statistics for each limb.

---

## 📌 Overview

This module performs:
- **Loading** processed video pose data (e.g., keypoints, coordinates)
- **Velocity-based movement detection** for each arm
- **Filtering** using optional movement masks
- **Combination** of multi‑camera signals into unified left/right “use” signals
- **Visualisation** of movement events and detection performance
- **Saving** movement detection outputs and summary tables

**Inputs:**
- Processed pose estimation data (from the Video DataSynchronizaion stage)
- Configuration parameters (paths, thresholds, etc.)

**Outputs:**
- Binary left/right “use” signals for each camera and combined view
- Figures showing detected movements
- Summary tables of movement counts and statistics

---

## 📂 Repository Structure

```
Gross_Mov_Detector/
├── main.m                  # Main script to run the detection pipeline
├── lib/                    # MATLAB helper functions
│   ├── combine_use_signal.m           # Combine movement signals across cameras
│   ├── detect_movement.m              # Velocity-based movement detection
│   ├── filter_with_mask.m             # Apply spatial mask to detections
│   ├── organize_files.m               # Arrange and prepare input data
│   ├── plot_and_report.m              # Generate plots and reports
│   ├── save_combined_use_signal.m     # Save combined movement signals
│   ├── save_viewer_asset_table.m      # Save summary tables for review
│   └── ternary.m                      # Utility ternary function
└── README.md
```

---

## 🛠 Requirements

- MATLAB R2020b or later  
- Signal Processing Toolbox 

---

## 🚀 Usage

1. Open MATLAB and set the repo folder as the current working directory.
2. Edit `main.m` to update:
   - Input/output paths
   - Movement detection parameters
   - Camera and segment settings
3. Run:
```matlab
main
```

**Inputs:**  
- Processed pose data files from the DataSynchronizaion stage  

**Outputs:**  
- Binary “use” signals for each limb and combined view  
- Plots of detected movements  
- Summary statistics tables  

---

## 📝 License

Code: [MIT License](LICENSE)  

---

## 🤝 Acknowledgments

- MATLAB Signal Processing Toolbox
