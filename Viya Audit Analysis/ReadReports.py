##############################################################################
# $Id:$
# Copyright(c) 2019 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
#
# Name: ReadReports.py
#
# Purpose: This script parses archived log files to identify the event of a
#          report being opened. These events are then written to a CSV file.
#
# Author: Tommy Armstrong
#
# Support: SAS(r) Global Hosting and US Professional Services
#
# Input: 1) archived SAS Viya Log files
#
# Output: 1) reportsopened.csv - a CSV file capturing the report open events
#         2) processed_logs.txt - a text file containing log filenames that
#            document which archived log files have already been processed.
#
# Parameters: 1) string - pathname to the directory containing the archived
#                log files and where the processed_log.txt file exists.
#             2) string - pathname to the directory that the CSV file will be
#                output to.
#
# Dependencies/Assumptions:
#
# Usage: Daily so that the new report openings are made available for further
#        data analysis in the CSV output file.
#
#History:
# yyyymmdd userid description
#############################################################################

import sys, getopt
import glob
import json
import re
from datetime import datetime, timedelta
import os

#***********************************************************************************************
# Method: parseLogs
# Input: logsDir : a string representing the pathname to the directory containing the archived
#                  log files to be read in and parsed as well as the file recording the filenames
#                  of the previously processed log files.
#        outDir : a string representing the pathname to the directory that the CSV file output
#                 will be written to.
# Output: 1) a CSV data file where each observation represents a report opening event. Each event
#            is comprises a date, time, user, and report URI.
#         2) a text file where each processed log file name is written to in order to record
#            which 
# Description: archived log files are read in and parsed for a string pattern that corresponds
#              to report opening events. The data from this line combined with the associated
#              report URI are then written as an observation to a CSV file.
#***********************************************************************************************
def parseLogs(logsDir, outDir):
    original_stdout = sys.stdout # save original stdout since output will be redirected to files
    # create a list containing the pathnames of all archived log files
    # archive_files = 'C:\\Users\\toarms\\Documents\\USPS\\LogParser\\VIYA_AUDIT\\*.arc'
    archive_files = os.path.join(logsDir, '*.arc')
    files = (glob.glob(archive_files))
    # open the file that contains the pathnames for logs that have been processed
    log_history = os.path.join(logsDir,'processed_logs.txt')
    log_file = open(log_history, 'a+')
    log_file.seek(0)
    old_logs = log_file.readlines()
    log_file.close()
    # determine the log files that haven't been processed.
    new_logs = list(set(os.path.basename(file) for file in files).difference(set(line.rstrip('\n') for line in old_logs)))
    new_logs.sort(key= lambda x : os.path.getmtime(os.path.join(logsDir,x)))
    # create CSV file to store data that captures report opening events
    csv_file = os.path.join(outDir,'reportsopened.csv')
    f_out = open(csv_file, 'w')
    f_out.write('date,time,user,report_uri\n')
    f_out.close()
    # if there are new logs to process, parse them to identify new report open events
    if new_logs:
        # iterate through each unprocessed log file to parse out each instance of a report opening and write it to the csv file
        for log in new_logs:
            logfilepath = os.path.join(logsDir,log)
            f = open(logfilepath,'r')
            lines = f.readlines()
            f.close()
            reportCt=0
            with open(csv_file, 'a') as r:
                for index, string in enumerate(lines):
                    # search each line for the regular expression that denotes the opening of a report
                    m = re.search(r'{"referringApplication":"SASVisualAnalytics"},"uri":"/folders/folders/[A-Za-z0-9\-]+/members/[A-Za-z0-9\-]+","httpContext":{"statusCode":20\d,"method":"POST"}}', string)
                    if m != None:
                        reportCt += 1
                        sys.stdout = r # Change the standard output to the file we created.
                        obj=json.loads(string) # render the json formatted log line into a dictionary object
                        # set up variables for the while loop to search for the report URI:
                        report_uri="REPORT_URI_NOT_FOUND"
                        b_index = index - 1 # create an index used to search backwards in the log for the report URI
                        open_time = datetime.strptime(obj['timeStamp'], '%Y-%m-%dT%H:%M:%S.%fZ') # determine the time the report was opened
                        time_limit = 1000
                        # loop to iterate backwards to find the report URI associated with the opened report
                        while b_index >= 0:
                            needle = lines[b_index] # preceding log line of current iteration
                            needle_obj = json.loads(needle) # convert the log line into a dictionary object
                            needle_time = datetime.strptime(needle_obj['timeStamp'], '%Y-%m-%dT%H:%M:%S.%fZ') # get the preceding line's log time
                            # if there is a processing delay captured in the log, increase the time limit to search for the report URI
                            if re.search('ATYPICAL_DURATION', needle):
                                time_limit += 1000
                            # end the search for report URI if time difference between report opening and line is > 500 ms
                            if open_time - needle_time > timedelta(milliseconds=time_limit):
                                break
                            # look for the report URI in the preceding log line
                            needle_m = re.search(r'/reports/reports/[A-Za-z0-9\-]+', needle)
                            # if a report URI is found and the user value of the preceding log line matches that of the report opening log line
                            # capture the report URI.
                            if needle_m != None and obj['user'] == needle_obj['user']:
                                report_uri = needle_m.group(0)
                                break
                            b_index -= 1 # iterate backwards to the next preceding line
                        # end of while loop
                        # adjust the time so that it correctly reflects when the report was opened (5 hour time diff)
                        adj_time = open_time - timedelta(hours=5)
                        outStr=f"{adj_time.date()},{datetime.strftime(adj_time,'%H:%M:%S.%f')[:-3]},{obj['user']},{report_uri}"
                        print(outStr)
                    # end of if statement    
            sys.stdout = original_stdout # Change the standard output back to orignal setting.
            print(f"File: {log}")
            print(f"Report count: {reportCt}")
        # end for loop
        # write the pathnames of the processed logs to an output file
        with open(log_history, 'a') as log_file:
            log_file.write(f"Timestamp: {datetime.today()} Logs Directory: {logsDir}\n")
            log_file.writelines(os.path.basename(line) + '\n' for line in new_logs)
    # end if new_logs
# end parseLogs function

# main function that analyzes the command line arguments and initializes the
# file path variables that are then passed to the parseLogs function.
def main(argv):
    # a usage string that is printed when the script is called with incorrect syntax
    usageStr = "usage: readreports.py -l <logs directory path> -o <output directory path>\n"
    usageStr += "usage: readreports.py --logsDir <logs directory path> --outDir <output directory path>"
    if(len(argv) < 1):
        print(usageStr)
        sys.exit(2)
    # set the default log and output directories to the same one as the script (used if called manually)
    logsDir = os.getcwd()
    outDir = os.getcwd()
    try:
        opts, args = getopt.getopt(argv,"hl:o:",["logsDir=","outDir="])
        if len(args) > 0:
            raise getopt.GetoptError('Error')
    except getopt.GetoptError:
        print(usageStr)
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print(usageStr)
            sys.exit()
        elif opt in ('-l','--logsDir'):
            logsDir = os.path.abspath(arg)
        elif opt in ('-o','--outDir'):
            outDir = os.path.abspath(arg)
    # call the parseLogs function to identify report open events
    parseLogs(logsDir, outDir)
# end main function

if __name__ == '__main__':
    main(sys.argv[1:])
