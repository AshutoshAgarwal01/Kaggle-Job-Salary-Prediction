# Kaggle-Job-Salary-Prediction
Predict the salary of any UK job ad based on its contents.

# The Problem
In this project, I am going to recreate the Kaggle competition to predict salaries based on job descriptions. This problem came from a company called Adzuna, “The UK’s Search Engine for Jobs, Property and Cars.” They wanted to be able to predict the salary of a job based on it’s description.

# The Data
There were four files availbale initially, I have merged them to make the problem simpler. There are two files available now.

JobData.csv and location_tree.txt

location_tree.txt has a fairly simple but non-standard format for the a hierarchy of UK locations. JobData.csv contains data for many job posting across varios industries. I want to predict SalaryNormalized.

# What I did
I broke the data set into training and testing sets. I did some exploratory analysis on training set and removed few columns from analysis.

I was unable to use FUll Description for feature extraction as even after doing basic cleaning I was unable to get meaningful features (skill sets). However I will try to do that later.

I used liner model for prediction. RMSE is not to good but hope that after extracting features from Full Description it will be much better.

P.S: I tried Laso regression for model but that did not work well hence I removed that from the code.
