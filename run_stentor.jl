using ImageView, StackViews, VideoIO

include("proc.jl")

img_arr=zeros(UInt8,2048,2048,20)
diff_arr=diff(Float16.(img_arr)/Float16(255.0),dims=3);

#=frame_num=Observable(1)=#
#=to_img=1=#
#=threshold=Observable(0.03)=#
#=p_x=Observable(1)=#
#=p_y=Observable(1)=#


####IGNORE ABOVE

MASTER_FOLDER="/media/para/T7_Tejas"

MASTER_FOLDER="/home/para"

datasets=DataFrame(dataset=sort(readdir("$MASTER_FOLDER/data")))
println(datasets)

fold_name=datasets.dataset[11]

img_arr,img_info,notes=load_stack("$MASTER_FOLDER/data/",fold_name);

fr=sort(vcat(collect(10:600:size(img_arr)[3]),collect(30:600:size(img_arr)[3])))
imshow(img_arr[:,:,fr])

write2video(img_arr[1:4:end,1:4:end,1:10:end],"$MASTER_FOLDER/data/$fold_name/$fold_name";fps=10)
file=open("$MASTER_FOLDER/data/$fold_name/dat2.bin","w+")
wrt = write(file, img_arr[1:4:end,1:4:end,1:10:end])


##### IGNORE BELOW






#Inspect all datasets
for i in datasets.dataset
    println(i)
    try
        notes=read(open("$MASTER_FOLDER/data/$i/dat.txt","r"), String)
        siz=filesize("$MASTER_FOLDER/data/$i/dat.bin")/1e9
        println(notes)
        println(siz)
    catch e
        println("Does not exist")
    end
    println(i)
    readline()
end

start=2
# What is this chunk for? For reading all info about the dataset?
for i in (size(datasets.dataset)[1]-start+1):(size(datasets.dataset)[1])
    fold_name = datasets.dataset[i]
    try
        img_arr,img_info,notes=load_stack(MASTER_FOLDER*"/data/", fold_name);
        println(notes)
        println(fold_name)
        imshow(img_arr)
    catch e
        println(e)
        println("Problem with $i ($fold_name)")
    end
    x=readline()
    if x=="c"
        break
    end
    ImageView.closeall()
end

#=led_stat=map(x->["OFF","ON"][x],Int.(img_info.Stim).+1)=#
#=to_img=1=#
#=diff_arr=compute_diff(img_arr[:,:,1:2:end],fold_name;diff_step=1);=#



imshow(img_arr)

imshow(diff_arr)

win_width=2048
plt=make_plot(img_arr,diff_arr,img_info.Cam,led_stat,win_width=win_width)
listen=frameshift(plt[1],frame_num,size(img_arr)[end],p_x)
show_plot()

# print("Enter x: ")
# s_x=parse(Int,readline())

# print("Enter y: ")
# s_y=parse(Int,readline())

# empty!(plt[1])
# win_width=80
# plt=make_plot(img_arr,diff_arr,img_info.Cam, led_stat,win_width=win_width)
# listen=frameshift(plt[1],frame_num,size(diff_arr)[end],p_x)

scattermouse=[]
crop_size=160
mouse_pos=[]
empty!(events(plt[1]).mousebutton.listeners)
mouse_click = on(events(plt[1]).mousebutton, priority=0) do event
    if event.button == Mouse.left && event.action == Mouse.press
        x, y = mouseposition(plt[2].scene)
        push!(scattermouse, poly!(plt[2],Rect(x-crop_size/2, y-crop_size/2, crop_size, crop_size), color=:red, alpha=0.3))
        push!(mouse_pos,(x,y))
    end
end

for (i,j) in enumerate(scattermouse)
    delete!(plt[2],j)
end
scattermouse=[]
mouse_pos=[]
show_plot()


cell_crop=cat([img_arr[x-((crop_size÷2)-1):x+crop_size÷2,y-((crop_size÷2)-1):y+crop_size÷2,:] for (x,y) in map(x->floor.(Int,x),sort(mouse_pos,by=x->x[1]))]...,dims=1)

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



write2video(tiled[:,:,1:10:end],"/home/para/data/$fold_name/tiled";fps=1)

imshow(tiled)

imshow(img_arr)

GC.gc()

x,y,p,s=track(diff_arr[1:1000],s_x,s_y,win_width=80,plot_path=false,plt=Nothing,blob_s=[5,10,20],thresh=0.03);

record(plt[1], "/home/para/data/$fold_name/out_stim.mp4", 1:2:2000; framerate = 20) do i
    frame_num[]=i
    print(i)
    recto.color= led_stat[i]=="OFF" ? :black : :blue
    notify(p_x)
end

boxp = Point2f[[1800, 1800], [2000, 1800], [2000, 2000], [1800, 2000]]
recto=poly!(plt[2],boxp,color=:black)

