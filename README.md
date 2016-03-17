# Kaggle-Job-Salary-Prediction
Predict the salary of any UK job ad based on its contents.

# The Problem
I submitted this as part of my final project for my course at University of Washington.
In this project, I am going to recreate the [Kaggle competition](https://www.kaggle.com/c/job-salary-prediction) to predict salaries based on job descriptions. This problem came from a company called Adzuna. They wanted to be able to predict the salary of a job based on it’s description.
However in this attempt I have reduced scope of the solution, I will build complete solution in days to come.

# The Data
There were four files availbale initially, I have merged them to make the problem simpler. There are two files available now.
JobData.csv and 
location_tree.txt

location_tree.txt has a fairly simple but non-standard format for the a hierarchy of UK locations. 
JobData.csv contains data for many job posting across varios industries. 

I want to predict SalaryNormalized.

# What I did
I broke the data set into training and testing sets. I did some exploratory analysis on training set and removed few columns from analysis.

There were too many job types to handle initially, I trained my model for "IT Jobs" only.

I was unable to use Full Description for feature extraction as even after doing basic cleaning I was unable to get meaningful features (skill sets). However I will try to do that later.

I used liner model for prediction. RMSE is not too good but hope that after extracting features from Full Description it will be much better.

# Future
I would like to extract features from Full Description and do this prediction for all job types.
Also, I would like to test few hypothesis where I can apply Lasso regression and Logistic Regression.
