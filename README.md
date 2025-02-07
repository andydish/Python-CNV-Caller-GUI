# PG Exome Depth Tool

**Version:** 1.0.0

The PG Exome Depth Tool wraps a python graphical interface to call copy-number variations (CNV) from exome-based sequencing data using [Exome Depth](https://github.com/vplagnol/ExomeDepth). This tool guides you through naming your analysis, selecting the folders containing your reference and test BAM files, and then executes an R script to perform the analysis. 

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Logging](#logging)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Contact](#contact)

---

## Features

- **User-Friendly GUI:** Built with Tkinter, the GUI provides simple dialogs to collect user inputs.
- **Logging:** Execution details (including username and timestamp) are automatically logged for regulatory compliance.
- **R Integration:** Calls the Exome Depth R script to run the core analysis.
- **Interactive Workflow:** Guides the user through:
  - Naming the analysis.
  - Selecting the reference folder (with BAM files having an average copy number of 2).
  - Selecting the test folder containing BAM files.
- **Results Storage:** Analysis results are stored in a dedicated folder within the project.

---

## Requirements

- **Python 3.6+**
- **R:** Must be installed and available on your system’s PATH.
- **Non-standard Python Libraries:**
  - `tkinter` (usually included with Python)
  - [`Pillow`](https://python-pillow.org/) (for image handling)
- **Operating System:** Windows is recommended, given the use of `RScript.exe`.

---

## Installation

1. **Clone the Repository:**

    ```bash
    git clone [https://github.com/yourusername/pg-exomedepth-tool.git](https://github.com/vplagnol/ExomeDepth.git)
    cd pg-exomedepth-tool
    ```

2. **Set Up a Virtual Environment (Optional but Recommended):**

    ```bash
    python -m venv env
    # On Windows:
    env\Scripts\activate
    # On macOS/Linux:
    source env/bin/activate
    ```

3. **Install Required Python Packages:**

    ```bash
    pip install Pillow
    ```

4. **Ensure R is Installed:**

    - Download and install R from [CRAN](https://cran.r-project.org/).
    - Make sure `RScript.exe` is added to your system's PATH so that the Python script can invoke it.

---

## Usage

1. **Run the Application:**

    Execute the main Python script from your terminal or command prompt:

    ```bash
    python your_script_name.py
    ```

    Replace `your_script_name.py` with the actual name of your Python file.

2. **Follow the On-Screen Prompts:**

    - **Name Your Analysis:** Enter a descriptive name when prompted.
    - **Select Reference Folder:** Choose the folder that contains your reference BAM files.
    - **Select Test Folder:** Choose the folder containing the test BAM files for analysis.

3. **Analysis Execution:**

    - Results are stored in the `app_data/cnv_results/` folder within a subfolder named after your analysis.

---

## Project Structure

```plaintext
pg-exomedepth-tool/
├── app_data/
│   ├── run_logs/         # Contains log files for each execution
│   ├── cnv_results/      # Contains analysis results (CNV outputs)
│   ├── pg_logo.png       # Logo image displayed in the GUI
│   ├── PG_exomedepth.r   # R script for performing the analysis
│   └── path_file.txt     # Stores user inputs (analysis name, folder paths)
├── PG_ExomeDepth_application.py   # Main Python script for running the tool
