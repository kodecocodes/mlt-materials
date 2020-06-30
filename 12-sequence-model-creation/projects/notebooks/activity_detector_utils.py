'''
/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
'''

import pandas as pd
import turicreate as tc
from glob import glob
from pathlib import Path
        
'''
  sframe_from_folder: Given the path to a folder, this function reads all the
                      .csv files in that folder and creates a Turi Create SFrame
                      containing their data. The columns are renamed to match the
                      features they contain, and a new "userId" column is added.
                      The csv files in folder should be created with the
                      GestureDataRecorder app. If any changes are made to the 
                      features recorded by that app (different features or different order)
                      then this code needs to be changed to match.
'''
def sframe_from_folder(folder):
    train_files = glob(f"{folder}/*.csv")
    
    if len(train_files) == 0:
        return None
    
    sf = append_uid_column(tc.SFrame.read_csv(train_files[0], header=False), train_files[0])
    for f in train_files[1:]:
        sf = sf.append(append_uid_column(tc.SFrame.read_csv(f, header=False), f))
        
    sf.rename(({'X1':'sessionId', 'X2':'activity',
                'X3':'roll', 'X4':'pitch', 'X5':'yaw',
                'X6':'rotX', 'X7':'rotY', 'X8':'rotZ',
                'X9':'gravX', 'X10':'gravY', 'X11':'gravZ',
                'X12':'accelX', 'X13':'accelY', 'X14':'accelZ'}),inplace=True)
    return sf

'''
  plot_gesture_activity: Uses matplotlib to display a line graph of the data in
                         the given Turi Create SFrame. Can optionally specify a 
                         user ID, activity, and/or list of features to limit what
                         data gets included in the graph.
'''
def plot_gesture_activity(sframe, userId=None, activity=None, features=None):
    # Convert to a Pandas DataFrame because it's easy to work with
    df = sframe.to_dataframe()
    
    if activity != None:
        df = df.loc[df.activity == activity]
    else:
        activity = "all"
        
    if userId:
        df = df.loc[df.userId == userId]
        
    if features:
        for col in list(df):
            if col not in features:
                df = df.drop(columns=[col])
                
    if len(df) == 0:
        print("No data to plot.")
    else:
        df.plot(kind='line', figsize=(20,10), title='{} samples'.format(activity))

'''
  count_activities: Given a Turi Create SFrame, counts the number of unique sessions
                    for each activity/user combination. Prints the results.
'''
def count_activities(sframe):
    counts = sframe.groupby(
        ['sessionId', 'activity', 'userId'], [tc.aggregate.COUNT]).groupby(
        ["activity", "userId"], [tc.aggregate.COUNT])
    print(counts.sort(['activity', 'userId']))                
    
'''
  append_uid_column: Helper function that takes a Turi Create SFrame and a path
                     to the data file used to make the SFrame. Adds a new column
                     named "userId" to the SFrame and populates every row of it
                     with the same value – the prefix of the filename up to the 
                     first dash '-'. For example, if from_path is "/path/to/some-file.csv",
                     the userId column will be filled with the value "some".
                     Modifies the given SFrame in place, but also returns it
                     to allow for chaining function calls.
'''
def append_uid_column(sframe, from_path):
    filename = Path(from_path).name
    first_dash = filename.find('-')
    if first_dash > 0:
        uid = filename[:first_dash]
        sframe['userId'] = uid
    return sframe

