using GLMakie, VideoIO, Colors, ImageFiltering, Statistics, DataFrames, RollingFunctions, HDF5, ProgressBars, PaddedViews

#Change filename to path

#MASTER_FOLDER="/home/para"

MASTER_FOLDERS=["/home/para","/media/para/T7_Tejas"]

println("Pick folder ($(MASTER_FOLDERS[1]) = 1, $(MASTER_FOLDERS[2]) = 2)")

#=MASTER_FOLDER=MASTER_FOLDERS[1]=#

MASTER_FOLDER=MASTER_FOLDERS[parse(Int,readline())]

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
println(datasets)

#=fold_name=datasets.dataset[8]=#

println("Enter folder number")
fold_name=datasets.dataset[parse(Int, readline())]

#=vid=VideoIO.load("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.mp4",target_format=VideoIO.AV_PIX_FMT_GRAY8)=#

vid_file=h5open("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.h5")
arr_1=read(vid_file["tiled_frames_trial_1"])
arr_2=read(vid_file["tiled_frames_trial_2"])

row_num=read(vid_file["row_num"])
col_num=read(vid_file["col_num"])

crop_size=read(vid_file["crop_size"])
num_cells=read(vid_file["num_cells"])

num_stim=60

println("$num_cells cells in this run.")

arr=cat(arr_1,arr_2;dims=3)

frame_num=Observable(1)
threshold_high=Observable(0.17*256)
threshold_low=Observable(0.03*256)

f=Figure(size=(512,512))
ax=Axis(f[2:10,1:9])
lab=Label(f[1,:],@lift("Trial $(($frame_num-1)÷(num_stim*2)+1) | Stimulus $(Int(ceil((((($frame_num-1))%(num_stim*2) +1)/2))))"))

function tile_arr(img_arr,row_num,col_num)
    cell_crop_pad=PaddedView(0, img_arr, (crop_size*col_num*row_num, crop_size, size(img_arr)[3]))
    tiled = cat([permutedims(cell_crop_pad[(row_num*(i-1)*crop_size)+1:row_num*i*crop_size,:,:],(1,2,3)) for i in 1:col_num]..., dims=2) 
    return tiled
end

tiled_arr=cat(tile_arr(arr_1,row_num,col_num),tile_arr(arr_2,row_num,col_num);dims=3)

# i=image!(ax,@lift(max.($threshold_low,min.($threshold_high,vid_arr[$frame_num]))),colorrange=[0,1])


#=i=image!(ax,@lift($threshold_low.<vid_arr[$frame_num].<$threshold_high),colorrange=[0,1])=#

i=image!(ax,@lift(tiled_arr[:,:,$frame_num].*3),colorrange=[0,255])

auto_contract=zeros(num_stim*2,num_cells)
manual_contract=zeros(num_stim*2,num_cells)

function auto(vid_arr, num_cells, auto_contract)
    println("Autoprocessing contractions...")
    for i in tqdm(num_cells)
        prev=mean(threshold_low[].<vid_arr[(i-1)*crop_size+1:i*crop_size,:,:].<threshold_high[],dims=(1,2))
        #=println(size(prev))=#
        prev=reshape(prev,:)
        auto_contract[:,i]=(prev[2:2:end]./prev[1:2:end]).<0.8
    end
    return auto_contract
end

auto_contract=(auto(arr, num_cells, auto_contract))

#Manual annotation
empty!(events(ax).mousebutton.listeners)
mouse_click = on(events(ax).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(ax.scene)
        if 0<x<size(tiled_arr)[1] && 0<y<size(tiled_arr)[2]
            cell_num=Int(floor(y/crop_size))*row_num+Int(ceil(x/crop_size))
            if cell_num<=num_cells
                manual_contract[Int(ceil(frame_num[]/2)),cell_num]=1-manual_contract[Int(ceil(frame_num[]/2)),cell_num]
            else
                println("Empty tile")
            end
            notify(frame_num)
        end
    end
end

function lim(n)
    return min(num_stim*4,max(1,n))
end

empty!(events(ax).keyboardbutton.listeners)
on(events(f).keyboardbutton) do event
    if event.action == Keyboard.press
        if event.key == Keyboard.left 
            frame_num[]=lim(frame_num[]-2)
        end
        if event.key == Keyboard.right 
            frame_num[]=lim(frame_num[]+2)
        end
        if event.key == Keyboard.down 
            frame_num[]+=(2*(frame_num[]%2)-1)
        end
    end
end

t=Threads.@async begin
    while true
        frame_num[]+=(2*(frame_num[]%2)-1)
        sleep(0.5)
    end
end

function clear_plot(p)
    for i in p
        delete!(ax,i)
    end
    p=[]
    return p
end

function annot(annot_arr,p)
    for i in 1:col_num
        for j in 1:row_num
            if ((i-1)*row_num+j<=num_cells)
                push!(p,poly!(ax,Point2f[((j-1)*crop_size+1, (i-1)*crop_size+1), (j*crop_size, (i-1)*crop_size+1), (j*crop_size, i*crop_size), ((j-1)*crop_size+1, i*crop_size)], color = @lift(RGBAf(100,0,0,(annot_arr[Int(ceil($frame_num/2)),(i-1)*row_num+j])*0.2)), strokecolor = :black, strokewidth = 1, ))
            end
        end
    end
end

p=[]
annot(manual_contract,p)

display(f)

println("Hit enter when done")
readline()


function plot_fig(contract,lab,p)
    fps = 2
    annot(contract,p)
    record(f, "$MASTER_FOLDER/data/$fold_name/$(fold_name)_$(lab)_annotation.mp4"; framerate = fps) do io
        for i = 1:num_stim*4
            frame_num[]=i
            sleep(0.01)
            recordframe!(io)
        end
    end
    #Data visualization
    f_dat=Figure()
    ax=Axis(f_dat[1:3,1:3],xlabel="Stimulus number",ylabel="Contraction probability")
    xlims!(ax,0,num_stim)
    ylims!(ax,0,1)
    mean_cells=mean(contract,dims=2)
    sing1=mean_cells[1:num_stim] #rolling(mean,mean_cells[1:60],5)
    sing2=mean_cells[num_stim+1:end]#rolling(mean,mean_cells[61:end],5)
    lines!(ax,reshape(sing1,:),linewidth=3,color=:black,label="Mean trial 1 ($num_cells cells)")
    lines!(ax,reshape(sing2,:),linewidth=3,color=:gray,label="Mean trial 2 ($num_cells cells)")
    l=Legend(f_dat[2,4],ax)
    save("$MASTER_FOLDER/data/$fold_name/$(fold_name)_$(lab)_annotation_curve.png", f_dat)
end


if !isfile("$MASTER_FOLDER/data/$fold_name/$(fold_name)_contractions.h5")
    contract_save=h5open("$MASTER_FOLDER/data/$fold_name/$(fold_name)_contractions.h5","w")
    contract_save["auto"]=auto_contract
    contract_save["manual"]=manual_contract
    close(contract_save)
    p=clear_plot(p)
    plot_fig(auto_contract,"auto",p)
    p=clear_plot(p)
    plot_fig(manual_contract,"manual",p)
else
    println("Contraction data already exists so did not save this.")
end
