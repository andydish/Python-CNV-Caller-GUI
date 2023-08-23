# version 1.0.0
print("PG Exome Depth Tool Version 1.0.0")

import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox, PhotoImage, simpledialog
from PIL import ImageTk, Image
import logging
import getpass
import datetime
import sys

# logging console to file
# get username executing
username = getpass.getuser()
# get date time of execution
current_datetime = datetime.datetime.now()
datetime_string = current_datetime.strftime("DATE_%Y-%m-%d_TIME_%H-%M-%S")
# make log file of execution, etc
logging.basicConfig(filename=f'app_data/run_logs/PG_ExomeDepth_run_log_USER_{username}_{datetime_string}.log', level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')

# Redirect console output to the logger
class ConsoleLogger:
    def write(self, message):
        logging.info(message)

    def flush(self):
        pass

sys.stdout = ConsoleLogger()

# print user name and date time for compliance
print(username)
print(datetime_string)

# get the user to name the analysis
def name_analysis():
    root = tk.Tk()
    root.withdraw()

    # Prompt the user to enter a name using a dialog box
    while True:
        analysis_name = simpledialog.askstring("Name Your Analysis", "Enter Analysis Name:")
        if analysis_name:
            break
        else:
            messagebox.showwarning("Error", "Name cannot be empty. Please try again.")
    return analysis_name

#get ref folder
def get_ref_folder():
    path_to_ref_folder = filedialog.askdirectory(title="Select folder with reference BAM files")
    return path_to_ref_folder

# prompt user using system dialog for path to folder with test BAM files in it
def get_test_folder():
    path_to_test_folder = filedialog.askdirectory(title="Select folder with test BAM files")
    return path_to_test_folder

# save the variables to a txt file
def save_variables(analysis_name, path_to_ref_folder, path_to_test_folder): # add path_to_control if need specific control rather than aggregate
    # change the path slash direction for r
    r_path_to_ref_folder = path_to_ref_folder.replace("\\","/")
    r_path_to_test_folder = path_to_test_folder.replace("\\", "/")
    # save to a txt file
    # Open the file in write mode and add all lines
    with open("app_data/path_file.txt", "w") as file:
        file.write(analysis_name+ "\n")
        file.write(r_path_to_ref_folder+ "\n")
        file.write(r_path_to_test_folder+ "\n")

def main():
    # get analysis name
    analysis_name = name_analysis()
    # get ref folder
    path_to_ref_folder = get_ref_folder()
    # get test folder
    path_to_test_folder = get_test_folder()
    # save paths to file
    save_variables(analysis_name, path_to_ref_folder, path_to_test_folder) # path_to_control
    # warning about run time
    messagebox.showinfo("Precision Genetics Exome Depth", "This will take a while, grab a coffee!\nCheck the console for progress information.")
    # run the R code
    subprocess.call("RScript.exe app_data/PG_exomedepth.r", shell=True)


if __name__ == "__main__":
    # show instructions
    # Create the main window
    root = tk.Tk()
    root.title("Precision Genetics Exome Depth Tool")

    # Load the image
    logo = ImageTk.PhotoImage(Image.open("app_data/pg_logo.png"))

    # Display the image in a label
    logo_label = tk.Label(root, image=logo)
    logo_label.grid(row=0, column=0)

    # Text to display
    text_1 = """ 
    Click "Start Analysis" and follow these steps:
        
    1. Name your analysis
    2. Choose the folder with your reference BAM files.
    - Your panel of normal reference samples should have an average copy number of 2 @ any loci. 
    3. Choose the folder with your test BAM files to analyze.
    4. Find your results in the "app_data/cnv_results/" in your analysis name folder. 
    
    Notes:
    - YOU WILL NEED R INSTALLED ON YOUR COMPUTER FOR THIS TO WORK
    - YOU WILL NEED R ON ON YOUR COMPUTER'S "PATH" FOR THIS TO WORK
    - If you encounter an error view the "app_data/run_logs" folder for more information.
    
    Contact andrew.disharoon@precisiongenetics.com with questions or issues.
    """
    # Display the text in a label
    text_label_1 = tk.Label(root, text=text_1, justify='left',font=("Segoe UI",'12'))
    text_label_1.grid(row=0, column=1, columnspan=3)

    # Add a button to choose a folder
    folder_button = tk.Button(root, text="Start Analysis", command=main)
    folder_button.grid(row=1, column=1, columnspan=3)
    # Run the main event loop
    root.mainloop()
