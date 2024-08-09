using ImageView, StackViews, VideoIO, HDF5

include("proc.jl")
diff_arr=nothing
frame_num=Observable(2)
to_img=1
threshold=Observable(0.03)
p_x=Observable(1)
p_y=Observable(1)

#BLOCK 1: Load video and save downsampled frames

#External SSD
MASTER_FOLDERS=["/home/para","/media/para/T7_Tejas"]

println("Pick folder ($(MASTER_FOLDERS[1]) = 1, $(MASTER_FOLDERS[2]) = 2)")
MASTER_FOLDER=MASTER_FOLDERS[parse(Int,readline())]

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
println(datasets)

println("Enter folder number")
fold_name=datasets.dataset[parse(Int, readline())]

img_arr_1,img_info_1,notes_1=load_stack("$MASTER_FOLDER/data/",fold_name*"/trial_1");
img_arr_2,img_info_2,notes_2=load_stack("$MASTER_FOLDER/data/",fold_name*"/trial_2");
println()


if isfile("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.h5")
    println("Tiled file already exists! Delete before running this script or it won't save.")
end
#= #If issue loading dataset ("increase file size...")=#
#=img_arr,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name; num_frames=35900);=#

#=imshow(img_arr[:,:,fr])=#

#=fr=sort(vcat(collect(10:600:Int(floor(size(img_arr)[3]/2))),collect(30:600:Int(floor(size(img_arr)[3]/2)))))=#
#=imshow(img_arr[:,:,fr])=#

#Only look at first frame and last frame to see how much stuff changed
#=imshow(img_arr[:,:,[1,end]])=#

function downsample(arr,trial_num)
    if !isfile("$MASTER_FOLDER/data/$(fold_name)/trial_$(trial_num)/dat2.bin")
        file=open("$MASTER_FOLDER/data/$(fold_name)/trial_$(trial_num)/dat2.bin","w+")
        wrt = write(file, arr[1:2:end,1:2:end,1:10:end])
        println("Saved downsampled frames")
    end
end

downsample(img_arr_1,1)

downsample(img_arr_2,2)
#= #Load downsampled (if original file has already been deleted)=#
#=img_arr_ds,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name; down=true, sz=1024, num_frames=3590);=#

function save_vid(arr,trial_num)
    if !isfile("$MASTER_FOLDER/data/$fold_name/trial_$(trial_num)/$(fold_name)_trial_$(trial_num).mp4")
        write2video(arr[1:4:end,1:4:end,1:10:end],"$MASTER_FOLDER/data/$fold_name/trial_$(trial_num)/$(fold_name)_trial_$(trial_num)";fps=10)
    println("Saved video")
    end
end

save_vid(img_arr_1,1)
save_vid(img_arr_2,2)


skip_size=4800
#BLOCK 2: For cell picking and saving
cell_pick_arr=cat(img_arr_1[:,:,600:skip_size:end],img_arr_2[:,:,600:skip_size:end], dims=3)

#Show video frame to pick cells
win_width=1024
plt=make_plot(cell_pick_arr;win_width=win_width)
listen=frameshift(plt[1],frame_num,size(cell_pick_arr)[end],p_x)
show_plot()
scattermouse=[]
crop_size=200
mouse_pos=[]
empty!(events(plt[1]).mousebutton.listeners)
mouse_click = on(events(plt[1]).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(plt[2].scene)
        push!(scattermouse, poly!(plt[2],Rect(x-crop_size/2, y-crop_size/2, crop_size, crop_size), color=:red, alpha=0.3))
        if crop_size/2 < x < size(cell_pick_arr)[1]-crop_size/2 && crop_size/2 < y < size(cell_pick_arr)[2]-crop_size/2
            push!(mouse_pos,[x,y])
            println("($(round(x,digits=2)), $(round(y,digits=2)))")
        else
            println("($x, $y) is invalid")
        end
    end
    if event.button == Mouse.right && event.action == Mouse.press
        x, y = mouseposition(plt[2].scene)
        push!(scattermouse, poly!(plt[2],Rect(x-crop_size/2, y-crop_size/2, crop_size, crop_size), color=RGBA(0,0,0,0), strokewidth=2, strokecolor=:blue))
    end
end

function lim(n)
    return n>size(cell_pick_arr)[3] ? 2 : n
end



empty!(events(plt[1]).keyboardbutton.listeners)
on(events(plt[1]).keyboardbutton) do event
    if event.action == Keyboard.press
        if event.key == Keyboard.left 
            frame_num[]=lim(frame_num[]-1)
        end
        if event.key == Keyboard.right 
            frame_num[]=lim(frame_num[]+1)
        end
    end
end

t=Threads.@async begin
    while true
        frame_num[]=lim(frame_num[]+1)
        sleep(0.5)
    end
end


println("Hit enter when done")
readline()

#(Run after picking cells) Generate tiled video with just the chosen cells just before and after each stimulus

function get_grid(n)
    col_num=Int(round(sqrt(n)))
    row_num=Int(ceil(n/col_num))
    pad_num=col_num*row_num
    pad_num-=n
    return col_num, row_num, pad_num
end
function rot(img)
    return permutedims(img,(2,1,3))[end:-1:1,:,:]
end
function reverse_rot(img)
    return permutedims(img[end:-1:1,:,:],(2,1,3))
end
function tile_arr(img_arr,mouse_pos,crop_size,fr)
    cell_crop=cat([img_arr[x-((crop_size÷2)-1):x+crop_size÷2,y-((crop_size÷2)-1):y+crop_size÷2,fr] for (x,y) in map(x->floor.(Int,x),sort(mouse_pos,by=x->x[1]))]...,dims=1)
    col_num, row_num, pad_num = get_grid(size(mouse_pos)[1])
    cell_crop_pad=PaddedView(0, cell_crop, (crop_size*col_num*row_num, crop_size, size(cell_crop)[3]))
    #=cell_crop_pad=rot(cell_crop_pad)=#
    tiled = cat([cell_crop_pad[(row_num*(i-1)*crop_size)+1:row_num*i*crop_size,:,:] for i in 1:col_num]..., dims=2) 
    imshow(tiled)
    return cell_crop, tiled, col_num, row_num, pad_num
end

fr=sort(vcat(collect(10:600:Int(floor(size(img_arr_1)[3]/1))),collect(30:600:Int(floor(size(img_arr_1)[3]/1)))))

tiled_arrs=[]
push!(tiled_arrs,(tile_arr(img_arr_1,mouse_pos,crop_size,fr)))

push!(tiled_arrs,(tile_arr(img_arr_2,mouse_pos,crop_size,fr)))

if !isfile("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.h5")
    tiled_save=h5open("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.h5","w")
    tiled_save["cell_locs"] = [(floor(Int,x),floor(Int,y)) for (x,y) in mouse_pos]
    tiled_save["tiled_frames_trial_1"] = tiled_arrs[1][1]
    tiled_save["tiled_frames_trial_2"] = tiled_arrs[2][1]
    tiled_save["col_num"]=tiled_arrs[1][3]
    tiled_save["row_num"]=tiled_arrs[1][4]
    tiled_save["pad_num"]=tiled_arrs[1][5]
    tiled_save["num_cells"]=size(mouse_pos)[1]
    tiled_save["crop_size"]=crop_size
    write2video(tiled_arrs[1][2],"$MASTER_FOLDER/data/$fold_name/$(fold_name)_trial_1_tiled";fps=4)
    write2video(tiled_arrs[2][2],"$MASTER_FOLDER/data/$fold_name/$(fold_name)_trial_2_tiled";fps=4)
    close(tiled_save)
else
    println("Tiled file already exists! Delete before running this script.")
end

img_arr_1=nothing
img_arr_2=nothing
GC.gc()
println("Can delete dat.bin now!")

