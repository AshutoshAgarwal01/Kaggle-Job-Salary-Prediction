setwd('/Users/AshutoshAgarwal/Desktop/Data Sci Classes/350/Project/Salary')

library(glmnet)
require(logging)
library(tm)
library(SnowballC)

basicConfig()
addHandler(writeToFile, file="FinalProject_Ashutosh.log", logger="logger_name", level='DEBUG')

############################ Function 1 ############################ 
loadAllLocations = function(x){
  loginfo(paste('Fun: loadAllLocations : Getting list of all locations.'),logger='logger_name')
  #Load location tree as csv
  cols = c(1:7)
  locationtreecsv = read.csv(x,sep = '~', header = FALSE,quote = "", col.names = cols)
  locationtreecsv$X1 = gsub('"','',locationtreecsv$X1)
  locationtreecsv$X2 = gsub('"','',locationtreecsv$X2)
  locationtreecsv$X3 = gsub('"','',locationtreecsv$X3)
  locationtreecsv$X4 = gsub('"','',locationtreecsv$X4)
  locationtreecsv$X5 = gsub('"','',locationtreecsv$X5)
  locationtreecsv$X6 = gsub('"','',locationtreecsv$X6)
  locationtreecsv$X7 = gsub('"','',locationtreecsv$X7)
  
  l = stack(locationtreecsv)
  l = unique(stack(locationtreecsv)[, "values"])
  return (l)
}

############################ Function 2 ############################ 

allStopWords = function(){
  loginfo(paste('Fun: allStopWords : Begin: Preparing list of all stopwords.'),logger='logger_name')
  
  my_stops = as.character(sapply(stopwords(), function(x) gsub("'","",x)))
  
  #Add locations to stop words
  locations = loadAllLocations('location_tree.txt')
  
  my_stops = c(my_stops, tolower(locations))
  
  my_stops = c(my_stops, "job", "jobs","title", "client", "result", "person", "opportunity", "due"
              ,"skill","skills","require", "required","requires", "summary"
              ,"benefits", "benefit", "hour", "hours", "time", "sunday", "monday"
              ,"tuesday", "wednesday","thursday","friday","saturday" ,"month", "months"
              ,"asap","include","including","ref","date","role","week", "****"
              ,"success", "successful", "salary", "current", "currently", "look", "looking"
              ,"leading", "company" ,"large", "largest", "seek", "seeker", "seeking", "worker"
              ,"exciting", "qualified", "workers", "career", "per", "annum", "k", "experience"
              ,"experienced", "apply", "applying")

  loginfo(paste('Fun: allStopWords : End: Preparing list of all stopwords.'),logger='logger_name')
  return (my_stops)
}

############################ Function 3 ############################ 

normaliza_text = function(x, s){
  loginfo(paste('Fun: normaliza_text : Begin: Normalizing unstructured text.'),logger='logger_name')
  
  # Remove non-ascii
  x = iconv(x, from="latin1", to="ASCII", sub="")
  
  # Change to lower case:
  x = tolower(x)
  
  # Remove punctuation
  x = sapply(x, function(x) gsub("'", "", x))
  
  # Now the rest of the punctuation
  x = sapply(x, function(x) gsub("[[:punct:]]", " ", x))
  
  # Remove numbers
  x = sapply(x, function(x) gsub("\\d","",x))
  
  # Remove extra white space, so we can split words by spaces
  x = sapply(x, function(x) gsub("[ ]+"," ",x))
  
  # remove stopwords:
  x = sapply(x, function(x){
    paste(setdiff(strsplit(x," ")[[1]],s),collapse=" ")
  })
  
  # Remove extra white space again:
  x = sapply(x, function(x) gsub("[ ]+"," ",x))
  
  loginfo(paste('Fun: normaliza_text : End: Normalizing unstructured text.'),logger='logger_name')
  return(x)
}

############################ Function 4 ############################ 

formDocumentTermMatrix = function(x, percentSparse){
  loginfo(paste('Fun: formDocumentTermMatrix : Begin: Create document term matrix.'),logger='logger_name')
  ##-----Text Corpus-----
  text_corpus = Corpus(VectorSource(x))
  
  ## Term document matrix and document term matrix
  document_term_matrix = DocumentTermMatrix(text_corpus)
  
  ## remove sparse terms
  document_term_matrix = removeSparseTerms(document_term_matrix, percentSparse) # Play with the % criteria, start low and work up
  
  # Save Matrix (This is mostly empty)
  document_term_matrix = as.matrix(document_term_matrix)
  
  loginfo(paste('Fun: formDocumentTermMatrix : End: Create document term matrix.'),logger='logger_name')
  #Return Data Frame
  return(as.data.frame(document_term_matrix))
}

############################ Function 5 ############################ 
normalizeLocationData = function(x, locationtree){
  loginfo(paste('Fun: normalizeLocationData : Begin: reducung location information to zones.'),logger='logger_name')
  
  for (i in 1:length(x)) {
    # get city name from training dataset
    locNorm = x[i]
    
    # Find line number in location tree where above city appears
    line.id = which(grepl(locNorm, locationtree))[1]
    
    # find broad location (e.g. "UK~South East England~Hampshire~Basingstoke" --> South East England)
    broadLocation = regexpr("~.+?~", locationtree[line.id])
    match = regmatches(locationtree[line.id], broadLocation)
    
    #For debuggig
    #print(paste(i, ' - ', line.id, ' - ', match))
    
    # store the broad location in training dataset
    x[i] = gsub("~", "", match)
  }
  loginfo(paste('Fun: normalizeLocationData : End: reducung location information to zones.'),logger='logger_name')
  
  return(x)
}


######################### Loading Data #########################

#Load given data set
jobData = read.csv('JobData.csv',stringsAsFactors = TRUE)
#head(jobData,1)

#There are too many job categories in this data set which will make keyword extraction really difficult 
#  from job description. Hence filtering this data only for IT Jobs
jobData = jobData[jobData$Category=='IT Jobs',]

#Load location tree that has tre elike structure for cities in UK. (e.g. "UK~South East England~Hampshire~Basingstoke")
locationtree = readLines('location_tree.txt')
#head(locationtree)

#Generate stop words.
stop_words = allStopWords()

######################### Split Data #########################
# Split into train/test set 75% train / 25% test'
train_ind = sample(1:nrow(jobData), round(0.75*nrow(jobData)))
train_set = jobData[train_ind,]
test_set = jobData[-train_ind,]

######################### Look at summary of various features #########################
#1. Title...
t = table(train_set$Title)
barplot(t)
#Too many titles. It can not be used as a feature directly. Since it contains key info, it can be sliced
#for further feture extraction.

#2. Location...
t = table(train_set$LocationNormalized)
barplot(t)
#Too many cities aprox 28% others. 
# We will try to reduce number of cities by normalizing them to zones.

#3. ContractType...
t = table(train_set$ContractType)
barplot(t)
#Lot of missing data. No good feature.

#4. ContractTime...For some; this data is not available.
t = table(train_set$ContractTime)
barplot(t)
#Contract and permanent only. Good candidate for prediction feature.

#We saw that there were too many cities; as we have location tree; we can normalize that data 
#by replacing cities with their broad locations.
## COMMENTING AS THIS METHOD HAS SOME ISSUES ##
#train_set$location = normalizeLocationData(train_set$LocationNormalized,locationtree)

#convert this new column to factor.
#train_set$Location <- as.factor(train_set$Location)

#Locations look much better now.
#summary(train_set$Location)

#Remove those columns that we are not going to use later
train_set <- train_set[-c(4,6,10,12)]

######################### Deal with unstructured columns - Training Set #########################
#1. normalizing and stemming "Full Description" column
train_set$FullDescriptionCleaned = normaliza_text(train_set$FullDescription, stop_words)

# Stem words: Full Description
train_set$FullDescriptionCleanedStem = sapply(train_set$FullDescriptionCleaned, function(x){
  paste(setdiff(wordStem(strsplit(x," ")[[1]]),""),collapse=" ")
})

#2. normalizing and stemming "title" column
train_set$TitleCleaned = normaliza_text(train_set$Title, stop_words)

# Stem words: title
train_set$TitleCleanedStem = sapply(train_set$TitleCleaned, function(x){
  paste(setdiff(wordStem(strsplit(x," ")[[1]]),""),collapse=" ")
})

######################### Feature Engineering #########################
#We have two columns that have unstructured data
#1 FullDescription - I have less hope with this column as I dont have full list of skill keywords.
#                      I tried using various APIs but no luck. However we will try this.
#1 Title - This looks promising as there is no detailed vebose. Keyword extraction should be effective here.

#  1 FullDescription'
Jobs_term_df = formDocumentTermMatrix(train_set$FullDescriptionCleanedStem, 0.9)

#  2 Title'
Jobs_term_title_df = formDocumentTermMatrix(train_set$TitleCleanedStem, 0.98)

# Fit all features in one box
#Jobs_term_title_df$LocationNormalized = train_set$LocationNormalized
#Jobs_term_title_df$Company = train_set$Company
Jobs_term_title_df$ContractTime = train_set$ContractTime
Jobs_term_title_df$SalaryNormalized = train_set$SalaryNormalized

######################### Modelling - Using Title Features only #########################
#There were too many irrelevant features for Full description but I could fetch good features from title.
#Hence modelling based on features extracted from title. Fitting linear model. 
#I tried with all variables first but due to mismatched features between training and test data sets, 
#I was unable to test the model. Hence I removed location and company.'

lm.fit1 <- lm(SalaryNormalized ~ ., data = Jobs_term_title_df)
summary(lm.fit1)

######################### Test the model #########################

### Prepare test data 
#Remove those columns that we are not going to use later
test_set <- test_set[-c(4,6,10,12)]
 
#1. normalizing and stemming "Full Description" column
test_set$FullDescriptionCleaned = normaliza_text(test_set$FullDescription, stop_words)

# Stem words: Full Description
test_set$FullDescriptionCleanedStem = sapply(test_set$FullDescriptionCleaned, function(x){
  paste(setdiff(wordStem(strsplit(x," ")[[1]]),""),collapse=" ")
})

#2. normalizing and stemming "title" column
test_set$TitleCleaned = normaliza_text(test_set$Title, stop_words)

# Stem words: title
test_set$TitleCleanedStem = sapply(test_set$TitleCleaned, function(x){
  paste(setdiff(wordStem(strsplit(x," ")[[1]]),""),collapse=" ")
})

#Standardizing test data as per model needs.
test_Jobs_term_title_df = formDocumentTermMatrix(test_set$TitleCleanedStem, 0.98)
# Fit all features in one box
#test_Jobs_term_title_df$LocationNormalized = test_set$LocationNormalized
#test_Jobs_term_title_df$Company = test_set$Company
test_Jobs_term_title_df$ContractTime = test_set$ContractTime
test_Jobs_term_title_df$SalaryNormalized = test_set$SalaryNormalized

#Some features that were in training set are not in test set. Inserting those without making any effect.
getModified <- function(dframe, destination_string, foo) {
  dframe[[destination_string]] <- foo
  dframe
}

c1 = colnames(Jobs_term_title_df)
c2 = colnames(test_Jobs_term_title_df)

l1 = which(is.na(match(c1, c2))==TRUE)

for(i in l1){
  cn = colnames(Jobs_term_title_df)
  test_Jobs_term_title_df = getModified(test_Jobs_term_title_df, cn[i], 0)
}


#prediction using lm.fit1
lm.pred1 = predict(lm.fit1, newdata = test_Jobs_term_title_df)

#calculate RMSE
RMSE = sqrt(mean((lm.pred1 - test_Jobs_term_title_df$SalaryNormalized)^2))
RMSE


