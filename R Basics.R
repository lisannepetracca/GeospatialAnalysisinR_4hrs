##part 1
#Make an object called obj with 1 element 'x'
Obj<-"x"

#run obj it will return 'x'
Obj

#Make a vector (NOTE this is not the same as a spatial vector data type)
lis<-c(1,5,7)

#inspect 'lis'
lis

#select the second item in the vector lis
lis[2]

#select items 2 through 3 in lis
lis[c(2:3)]

#select items 1 and 3 in the list
lis[c(1,3)]

#remove item 2 from lis, store in new object called 'lis2'
lis2<-lis[-2]

lis2# look at lis2

#replace item 2 in lis with the number 25
lis[2]<-25
lis#look at lis

#make a data frame called df
df<-data.frame(letters=c("a","b","c"),numbers=lis)

#inspect df
df

#inspect data
head(df) #look at first few rows
tail(df)#look at last few rows
str(df)#look at data structure
summary(df)#look at data summaries

#look at numbers column
df$numbers

#look at numbers column using index
df[,2]

#look at row 3 in numbers column
df[3,2]

#Run calculations or operations on data
#Take the mean of the numbers column
mean(df$numbers)
