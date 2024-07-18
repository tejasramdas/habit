using CSV, DataFrames

file_path = "/home/para/Downloads"
file_name = "cells.csv"

f = joinpath(file_path, file_name)
#file = "$file_path/$file_name"

csvfile = CSV.read(f, DataFrame)
println(csvfile.head())
