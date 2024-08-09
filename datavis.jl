using CSV, DataFrames, HDF5, CairoMakie,StatsPlots, RollingFunctions, MultivariateStats, Statistics, AlgebraOfGraphics 

root = "/media/para/T7_Tejas/data"

#root = "/home/para/data"
savepath = "/home/para/habit"
datasets=DataFrame(dataset=sort(readdir("$root")))
println(datasets)
fold_name=datasets.dataset[142]

file = h5open(joinpath(root, fold_name, "$(fold_name)_contractions.h5"))
file_info = h5open(joinpath(root, fold_name, "$(fold_name)_tiled.h5"))
manual = read(file["manual"])
NUM_CELLS = read(file_info["num_cells"])
NUM_STIM = floor(Int64, size(manual)[1]/2)
NUM_TRIAL = [1,2]
SWIM = 3

#=function create_metadata(manual, fold_name, num_stim, num_trial, num_cells, swim)=#
#=    df1 = DataFrame(stim = num_stim, trial = "Trial $(num_trial[1])",               =#
#=               contract = vec(mean(manual[1:num_stim,:], dims=2)))=#
#=    df1.rolling = rolling(mean, df1.contract, 5, padding = df1.contract[1:4])=#
#=    df2 = DataFrame(stim = NUM_STIM, trial = "Trial $(num_trial[2])",=#
#=                contract = vec(mean(manual[num_stim:(num_stim*2),:], dims=2)))=#
#=    df2.rolling = rolling(mean, df2.contract, 5, padding = df2.contract[1:4])=#
#=    return df2 =#
#=end=#
#==#
#=create_metadata(manual = manual, fold_name = fold_name, num_stim = NUM_STIM, num_cells = NUM_CELLS,=#
#=                swim = SWIM, num_trial = NUM_TRIAL)=#

## Write into functions
df1 = DataFrame(date = fold_name[1:10],
                total = NUM_CELLS,
                swim = SWIM,
                stim = 1:NUM_STIM, trial = "Trial $(NUM_TRIAL[1])",               
               contract = vec(mean(manual[1:NUM_STIM,:], dims=2)))
df1.rolling = rolling(mean, df1.contract, 5, padding = df1.contract[1:4])
df2 = DataFrame(date = fold_name[1:10],
                total = NUM_CELLS,
                swim = SWIM,stim = 1:NUM_STIM, trial = "Trial $(NUM_TRIAL[2])",
            contract = vec(mean(manual[NUM_STIM:(NUM_STIM*2-1),:], dims=2)))
df2.rolling = rolling(mean, df2.contract, 5, padding = df2.contract[1:4])
df = vcat(df1, df2)
outputfile = "$(savepath)/Aug08datasheet.csv"
CSV.write(outputfile, df, append = isfile(outputfile), writeheader = !isfile(outputfile))

single = DataFrame()
for cell in 1:NUM_CELLS
    for i in NUM_TRIAL
        df = DataFrame(date = fold_name[1:10],
                   cellnum = "Cell $(cell)",
                   trial = "Trial $(i)",stim = 1:NUM_STIM,
                       contract = [manual[stim, cell] for stim in 1:NUM_STIM])
        df.rolling = rolling(mean, df.contract, 5, padding = df.contract[1:4])
        single = vcat(single, df)
    end
end 

singleanalysis = "$(savepath)/Aug09datasheet.csv"
CSV.write(singleanalysis, single, append = isfile(singleanalysis), writeheader = !isfile(singleanalysis))

single2 = filter(single -> single.cellnum == "Cell 15")

single2

s = data(single) * visual(Lines) * mapping(:stim, :rolling, color = :cellnum)

draw(s, scales(Color = (; palette = :lajollaS)))


###### visualization of manual annotation
alldata = CSV.read("$(savepath)/Aug08datasheet.csv", DataFrame)
alldata

fig_label = DataFrame(x=[30,30], y=[0.8, 0.8],
                      date = ["2024_07_28", "2024_07_31"], 
                      label = ["N = 15\nS = 3\n(Old stimulus)", "N = 4\nS = 3\n(New stimulus)"])
set_aog_theme!()
#update_theme!(fontsize=10, markersize=10)
p = data(alldata) * (visual(Scatter) + smooth()) * mapping(:stim => "Stimulus", :rolling => "Contraction probability\n(Avg. 5 trials)", color=:trial => "", col =:date)
p += data(fig_label) *
    visual(Makie.Text) *
    mapping(:x => "Stimulus", :y => "Contraction probability\n(Avg. 5 trials)", col =:date, text = :label => verbatim)
fig = draw(p, axis=(; title=""), scales(Color = (; palette = ["gray1", "dimgray"])))

save("figure.png", fig, px_per_unit = 3)
close(file)
close(file_info)

#=data_layer = data(df)=#
#=mapping_layer = mapping(:stim => "Stimulus", :contract => "Probability of contract", color=:trial)=#
#=visual_layer = (visual(Scatter) + smooth()) =#
#=draw(data_layer * mapping_layer * visual_layer,=#
#=     axis = (;title = "07.28.24"))=#

c += data((x=[1/10, 1/2], y=[0, ϕ(1)], label=["μ", "σ"])) *
    visual(Makie.Text) *
    mapping(:x, :y, text = :label => verbatim)


ϕ(x; μ=0, σ=1) = 1/sqrt(2*pi*σ^2) * exp(-(1/(2σ)) * (x - μ)^2)
xs = range(-3, 3, length=251)
ys = ϕ.(xs)
c = data((x=xs, y=ys)) * visual(Lines) * mapping(:x, :y)

c += data(DataFrame(x=0, hi=ϕ(0), lo=0)) * visual(Rangebars) *
    mapping(:x, :hi, :lo)

c += data(DataFrame(xmin=0, xmax=1, y=ϕ(1))) * visual(Rangebars, direction=:x) *
    mapping(:y, :xmin, :xmax)

c += data((x=[1/10, 1/2], y=[0, ϕ(1)], label=["μ", "σ"])) *
    visual(Makie.Text) *
    mapping(:x, :y, text = :label => verbatim)

draw(c)

responses = contract/num

df = DataFrame(stim=1:size(manual)[1], 
               num = read(file_info["num_cells"]),
               contract = vec(sum(manual, dims=2)),
               )

df.responses = df.contract./df.num

df[59:70,:]

df(!, responses = num/contract

@pipe session_df |> combine(_, stim = 1:size(manual)[1])

df = DataFrame(stim=1:size(manual)[1],
               num = info,
               contract = vec(contract), 
               responses = responses)

Plots.plot(Manual[:,1:2])


contract = vec(sum(manual,dims=2))

num_trial = size(Manual)[1]


#size, summary
## 1st is the stimuli, 2nd axis is row, 3rd is column

println(Manual[:,1])

println(Manual[1,:,:])

#Exclude the one that wasn't contracted after the first stimulus?
sum(Manual[1,:])

contract = [sum(Manual[i,:,:]) for i in 1:num_trial]
num = 14
df = DataFrame(Stimulus=1:num_trial, num = num, Num_Contract=contract, per_responses = contract/num)

df.avg10 = rolling(sum, df.per_responses, 10)

function rolling_avg(vector, size)
    for i in 1:length(vector)
        if i < size:
            avg10 = 

df(!, avg10 = rolling(sum,df.per_responses,10))

avg10 =  rolling(sum, per_responses,10)
rolling(sum, df.per_responses,10)/10

typeof(df.per_responses)

a = [i for i in 1:20]
rolling(sum, a, 10)
length(rolling(sum, a, 10))

typeof(a)

rolling(sum,a,10)
#=read(fid["manual"])=#

close(file)
close(file_info)
