using ImageView, StackViews, VideoIO, HDF5

include("proc.jl")
diff_arr=nothing
frame_num=Observable(1)
to_img=1
threshold=Observable(0.03)
p_x=Observable(1)
p_y=Observable(1)

#BLOCK 1: Load video and save downsampled frames

#External SSD
MASTER_FOLDER="/media/para/T7_Tejas"

#On computer
MASTER_FOLDER="/home/para"

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
println(datasets)

fold_name=datasets.dataset[3]

img_arr,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name);

#If issue loading dataset ("increase file size...")
img_arr,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name; num_frames=35900);

fr=sort(vcat(collect(10:600:Int(floor(size(img_arr)[3]/1))),collect(30:600:Int(floor(size(img_arr)[3]/1)))))
imshow(img_arr[:,:,fr])

#=fr=sort(vcat(collect(10:600:Int(floor(size(img_arr)[3]/2))),collect(30:600:Int(floor(size(img_arr)[3]/2)))))=#
#=imshow(img_arr[:,:,fr])=#

#Only look at first frame and last frame to see how much stuff changed
imshow(img_arr[:,:,[1,end]])

if isfile("$MASTER_FOLDER/data/$fold_name/dat.bin")
    file=open("$MASTER_FOLDER/data/$fold_name/dat2.bin","w+")
    wrt = write(file, img_arr[1:2:end,1:2:end,1:10:end])
end

#Load downsampled (if original file has already been deleted)
img_arr_ds,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name; down=true, sz=1024, num_frames=3590);

write2video(img_arr[1:4:end,1:4:end,1:10:end],"$MASTER_FOLDER/data/$fold_name/$fold_name";fps=10)


#BLOCK 2: For cell picking and saving


#Show video frame to pick cells
win_width=1024
plt=make_plot(img_arr,diff_arr,img_info.Cam,nothing,win_width=win_width)
listen=frameshift(plt[1],frame_num,size(img_arr)[end],p_x)
show_plot()
scattermouse=[]
crop_size=160
frame_num[]=35900
mouse_pos=[]
empty!(events(plt[1]).mousebutton.listeners)
mouse_click = on(events(plt[1]).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(plt[2].scene)
        push!(scattermouse, poly!(plt[2],Rect(x-crop_size/2, y-crop_size/2, crop_size, crop_size), color=:red, alpha=0.3))
        push!(mouse_pos,[x,y])
    end
end

#(Run after picking cells) Generate tiled video with just the chosen cells just before and after each stimulus
cell_crop=cat([img_arr[x-((crop_size÷2)-1):x+crop_size÷2,y-((crop_size÷2)-1):y+crop_size÷2,fr] for (x,y) in map(x->floor.(Int,x),sort(mouse_pos,by=x->x[1]))]...,dims=1)
function get_grid(n)
    col_num=Int(round(sqrt(n)))
    row_num=Int(ceil(n/col_num))
    pad_num=col_num*row_num
    pad_num-=n
    return col_num, row_num, pad_num
end
col_num, row_num, pad_num = get_grid(size(mouse_pos)[1])
cell_crop_pad=PaddedView(0, cell_crop, (crop_size*col_num*row_num, crop_size, size(cell_crop)[3]))
function rot(img)
    return permutedims(img,(2,1,3))[end:-1:1,:,:]
end
function reverse_rot(img)
    return permutedims(img[end:-1:1,:,:],(2,1,3))
end
cell_crop_pad=rot(cell_crop_pad)
tiled = cat([cell_crop_pad[:,(col_num*(i-1)*crop_size)+1:col_num*i*crop_size,:] for i in 1:row_num]..., dims=1) 
imshow(tiled)


tiled_save=h5open("$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled.h5","w")
tiled_save["cell_locs"] = [(floor(Int,x),floor(Int,y)) for (x,y) in mouse_pos]
tiled_save["tiled_frames"] = tiled
write2video(tiled[:,:,:],"$MASTER_FOLDER/data/$fold_name/$(fold_name)_tiled";fps=4)
close(tiled_save)

img_arr=nothing
GC.gc()
println("Can delete dat.bin now!")

##### IGNORE BELOW




#Inspect all datasets
#=for i in datasets.dataset=#
#=    println(i)=#
#=    try=#
#=        notes=read(open("$MASTER_FOLDER/data/$i/dat.txt","r"), String)=#
#=        siz=filesize("$MASTER_FOLDER/data/$i/dat.bin")/1e9=#
#=        println(notes)=#
#=        println(siz)=#
#=    catch e=#
#=        println("Does not exist")=#
#=    end=#
#=    println(i)=#
#=    readline()=#
#=end=#
#==#
#=start=2=#
#=# What is this chunk for? For reading all info about the dataset?=#
#=for i in (size(datasets.dataset)[1]-start+1):(size(datasets.dataset)[1])=#
#=    fold_name = datasets.dataset[i]=#
#=    try=#
#=        img_arr,img_info,notes=load_stack(MASTER_FOLDER*"/data/", fold_name);=#
#=        println(notes)=#
#=        println(fold_name)=#
#=        imshow(img_arr)=#
#=    catch e=#
#=        println(e)=#
#=        println("Problem with $i ($fold_name)")=#
#=    end=#
#=    x=readline()=#
#=    if x=="c"=#
#=        break=#
#=    end=#
#=    ImageView.closeall()=#
#=end=#

#=led_stat=map(x->["OFF","ON"][x],Int.(img_info.Stim).+1)=#
#=to_img=1=#
#=diff_arr=compute_diff(img_arr[:,:,1:2:end],fold_name;diff_step=1);=#

