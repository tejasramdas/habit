using PackageCompiler

PackageCompiler.create_sysimage(["GLMakie"]; sysimage_path="makie.so", precompile_execution_file="precompile_file.jl")
