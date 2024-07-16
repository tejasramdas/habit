using CSV, DataFrames

file_path = "/home/para/Downloads"
file_name = "cells.csv"
file = "$file_path/$file_name"

csvfile = CSV.read(file, DataFrame)
println(csvfile.head())
